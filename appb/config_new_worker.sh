#!/usr/bin/env bash
# LICENSE BEGIN
#
# Copyright 2016 William A. Havanki, Jr.
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

# Configures Hadoop components on a new worker instance.

usage() {
  cat << EOF
usage: $0 new-worker-ip worker-ip ...

Run this script on a manager.
EOF
}

if (( $# < 2 )); then
  echo "Supply the new worker private IP address and at least one" \
    "(old) worker IP address"
  usage
  exit 1
fi

# Collect required IP addresses: this worker, and other workers
NEW_WORKER_IP="$1"
shift
WORKER_IPS=( "$@" )
WORKER_IPS+=( "$NEW_WORKER_IP" )

NUM_WORKERS=${#WORKER_IPS[@]}

echo "New worker IP: $NEW_WORKER_IP"
echo "${NUM_WORKERS} worker IPs: ${WORKER_IPS[*]}"
echo

echo
echo "Substituting IP addresses and hostnames into Hadoop configurations"
echo

# Rewrite slaves file based on known worker IP addresses
echo "- /etc/hadoop/slaves"
printf '%s\n' "${WORKER_IPS[@]}" | sudo tee /etc/hadoop/slaves > /dev/null

echo
echo "IP address and hostname substitutions complete"

# Copy out configuration files to the new worker
echo
echo "Copying configurations out to new worker"
WORKER_FILES=(/etc/hadoop/core-site.xml
              /etc/hadoop/yarn-site.xml
              /opt/zookeeper/conf/zoo.cfg)

echo "- copy to $NEW_WORKER_IP"
scp "${WORKER_FILES[@]}" "$NEW_WORKER_IP":.
for f in "${WORKER_FILES[@]}"; do
  echo "- put $f in place"
  ssh "$NEW_WORKER_IP" sudo cp "$(basename "$f")" "$f"
done
