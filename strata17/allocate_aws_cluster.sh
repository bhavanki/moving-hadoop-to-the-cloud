#!/usr/bin/env bash
# LICENSE BEGIN
#
# Copyright 2017 William A. Havanki, Jr.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# LICENSE END

# Allocates Hadoop cluster instances for a simple cluster in AWS.

DEFAULT_INSTANCE_TYPE=m4.xlarge

usage() {
  cat << EOF
usage: $0 options ami-id keypair-name subnet-id num-workers

OPTIONS:
  -g <id>       security group ID (no default)
  -i <type>     instance type (default $DEFAULT_INSTANCE_TYPE)
  -n            perform dry run
  -p <profile>  AWS CLI profile (no default)
  -h    Shows this help message

The minimum number of workers permitted is three; the maximum is fifteen.
EOF
}

SECURITY_GROUP_ID=
INSTANCE_TYPE="${DEFAULT_INSTANCE_TYPE}"
DRY_RUN=
AWS_PROFILE=

while getopts "g:i:np:h" opt
do
  case $opt in
    h)
      usage
      exit 0
      ;;
    g)
      SECURITY_GROUP_ID="${OPTARG}"
      ;;
    i)
      INSTANCE_TYPE="${OPTARG}"
      ;;
    n)
      DRY_RUN=1
      ;;
    p)
      AWS_PROFILE="${OPTARG}"
      ;;
    ?)
      usage
      exit
      ;;
  esac
done
shift $((OPTIND - 1))

if (( $# < 4 )); then
  echo "Not enough arguments"
  usage
  exit 1
fi

AMI_ID="$1"
KEYPAIR_NAME="$2"
SUBNET_ID="$3"
NUM_WORKERS="$4"

if (( NUM_WORKERS < 3 || NUM_WORKERS > 15 )); then
  echo "The number of workers must be between 3 and 15"
  usage
  exit 1
fi

if ! hash aws > /dev/null; then
  echo "The AWS CLI must be on the path"
  exit 1
fi

AWS_OPTS=()
if [[ -n $AWS_PROFILE ]]; then
  AWS_OPTS+=(--profile "$AWS_PROFILE")
fi
AWS="$(which aws)"

if ! hash jq > /dev/null; then
  echo "jq must be on the path"
  exit 1
fi
JQ="$(which jq)"

RUN_INSTANCES_OPTS=(\
  --output json
  --image-id "$AMI_ID"\
  --key-name "$KEYPAIR_NAME"\
  --instance-type "$INSTANCE_TYPE"\
  --subnet-id "$SUBNET_ID"
  --associate-public-ip-address
)
if [[ -n $SECURITY_GROUP_ID ]]; then
  RUN_INSTANCES_OPTS+=(--security-group-ids "$SECURITY_GROUP_ID")
fi
if [[ -n $DRY_RUN ]]; then
  RUN_INSTANCES_OPTS+=(--dry-run)
fi

echo "Allocating manager instance"
MANAGER_JSON="$(mktemp -t manager.XXXXXX.json)"
"$AWS" "${AWS_OPTS[@]}" ec2 run-instances "${RUN_INSTANCES_OPTS[@]}" > "${MANAGER_JSON}"
manager_instance_id=$("$JQ" ".Instances[0].InstanceId" "${MANAGER_JSON}")
manager_private_ip_address=$("$JQ" ".Instances[0].PrivateIpAddress" "${MANAGER_JSON}")
manager_public_ip_address=$("$JQ" ".Instances[0].PublicIpAddress" "${MANAGER_JSON}")
echo "Allocated manager instance ${manager_instance_id}"

RUN_INSTANCES_OPTS+=(--count "$NUM_WORKERS")

echo "Allocating $NUM_WORKERS worker instances"
WORKERS_JSON="$(mktemp -t workers.XXXXXX.json)"
"$AWS" "${AWS_OPTS[@]}" ec2 run-instances "${RUN_INSTANCES_OPTS[@]}" > "${WORKERS_JSON}"
worker_instance_ids=()
worker_private_ip_addresses=()
worker_public_ip_addresses=()
for i in seq 1 $NUM_WORKERS; do
  worker_instance_ids[$i]=$("$JQ" ".Instances[$i].InstanceId" "${WORKERS_JSON}")
  worker_private_ip_addresses[$i]=$("$JQ" ".Instances[$i].PrivateIpAddress" "${WORKERS_JSON}")
  worker_public_ip_addresses[$i]=$("$JQ" ".Instances[$i].PublicIpAddress" "${WORKERS_JSON}")
  echo "Allocated worker instance ${worker_instance_ids[$i]}"
done

echo "${manager_instance_id} ${manager_private_ip_address}:${manager_public_ip_address}"
for i in seq 1 $NUM_WORKERS; do
  echo "${worker_instance_ids[$i]} ${worker_private_ip_addresses[$i]}:${worker_public_ip_addresses[$i]}"
done
