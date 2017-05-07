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

# Configures Hadoop components on a manager instance and one or more worker
# instances.

usage() {
  cat << EOF
usage: $0 options manager-ip worker-ip ...

OPTIONS:
  -d <name>  Hostname of database server hosting Hive metastore
  -a <keys>  AWS access key and secret access key, separated by a colon
  -H         Initialize for second manager (for HA cluster)
  -m <ip>    IP address of second manager (for HA cluster)
  -h         Shows this help message

For an HA cluster, run this script on the first manager with -m, and then
on the second manager with -m and -H. Use the same manager IP addresses on
each manager; do not reverse them when running on the second manager.

The user account on each manager must have passwordless sudo access.
EOF
}

HIVE_DB_SERVER=
AWS_ACCESS_KEY=
AWS_SECRET_KEY=
ON_SECOND_MANAGER=
MANAGER2_IP=
while getopts "a:d:hHm:" opt
do
  case $opt in
    h)
      usage
      exit 0
      ;;
    a)
      AWS_ACCESS_KEY="${OPTARG%%:*}"
      AWS_SECRET_KEY="${OPTARG##*:}"
      ;;
    d)
      HIVE_DB_SERVER="$OPTARG"
      ;;
    H)
      ON_SECOND_MANAGER=1
      ;;
    m)
      MANAGER2_IP="$OPTARG"
      ;;
    ?)
      usage
      exit
      ;;
  esac
done
shift $((OPTIND - 1))

if (( $# < 2 )); then
  echo "Supply the manager private IP address and at least one worker IP address"
  usage
  exit 1
fi

if [[ -n $ON_SECOND_MANAGER && -z $MANAGER2_IP ]]; then
  echo "When running on second manager, -m is required"
  usage
  exit 1
fi

# Collect required IP addresses: manager and workers
MANAGER_IP="$1"
shift
WORKER_IPS=( "$@" )

NUM_WORKERS=${#WORKER_IPS[@]}

echo "Manager IP: $MANAGER_IP"
if [[ -n $MANAGER2_IP ]]; then
  echo "HA Manager IP: $MANAGER2_IP"
fi
echo "${NUM_WORKERS} worker IPs: ${WORKER_IPS[*]}"
echo

# Replaces a ${token_string} in a file with a value
swap_in() {
  local f="$1"
  local token_name="$2"
  local repl="$3"

  local token='\${'"${token_name}"'}'

  sudo sed -i "s/${token}/${repl}/g" "$f"
}

echo
echo "Substituting IP addresses and hostnames into Hadoop configurations"
echo

# Replace in core-site.xml files: manager.ip, worker<i>.ip
echo "- /etc/hadoop/core-site.xml"
swap_in /etc/hadoop/core-site.xml manager.ip "${MANAGER_IP}"
for i in $(seq 1 "$NUM_WORKERS"); do
  w="${WORKER_IPS[$(( i - 1 ))]}"
  swap_in /etc/hadoop/core-site.xml "worker${i}.ip" "$w"
done

# Replace in yarn-site.xml files: manager.ip, manager2.ip, worker<i>.ip
echo "- /etc/hadoop/yarn-site.xml"
swap_in /etc/hadoop/yarn-site.xml manager.ip "${MANAGER_IP}"
swap_in /etc/hadoop/yarn-site.xml manager2.ip "${MANAGER2_IP}"
for i in $(seq 1 "$NUM_WORKERS"); do
  w="${WORKER_IPS[$(( i - 1 ))]}"
  swap_in /etc/hadoop/yarn-site.xml "worker${i}.ip" "$w"
done
if [[ -n $ON_SECOND_MANAGER ]]; then
  # Change YARN RM HA ID to rm2 on the second manager
  sudo sed -i 's/<value>rm1</<value>rm2</' /etc/hadoop/yarn-site.xml
  echo
fi

# Write slaves file based on known worker IP addresses
echo "- /etc/hadoop/slaves"
printf '%s\n' "${WORKER_IPS[@]}" | sudo tee /etc/hadoop/slaves > /dev/null

# Replace in zoo.cfg files: worker<i>.ip
echo "- /opt/zookeeper/conf/zoo.cfg"
for i in $(seq 1 "$NUM_WORKERS"); do
  w="${WORKER_IPS[$(( i - 1 ))]}"
  swap_in /opt/zookeeper/conf/zoo.cfg "worker${i}.ip" "$w"
done

# Replace in hive-site.xml: manager.ip, dbserver.name
echo "- /opt/hive/conf/hive-site.xml"
if [[ -z $ON_SECOND_MANAGER ]]; then
  swap_in /opt/hive/conf/hive-site.xml manager.ip "${MANAGER_IP}"
else
  swap_in /opt/hive/conf/hive-site.xml manager.ip "${MANAGER2_IP}"
fi
if [[ -n $HIVE_DB_SERVER ]]; then
  swap_in /opt/hive/conf/hive-site.xml dbserver.name "${HIVE_DB_SERVER}"
fi

echo
echo "IP address and hostname substitutions complete"

if [[ -n $AWS_ACCESS_KEY ]]; then
  echo
  echo "Substituting AWS keys into Hadoop configurations"
  echo

  # Replace in core-site.xml: AWS keys
  echo "- /etc/hadoop/core-site.xml"
  swap_in /etc/hadoop/core-site.xml aws.access.key "${AWS_ACCESS_KEY}"
  swap_in /etc/hadoop/core-site.xml aws.secret.key "${AWS_SECRET_KEY}"

  echo
  echo "AWS key substitutions complete"
fi

if [[ -z $ON_SECOND_MANAGER ]]; then
  echo
  echo "Copying configurations out to workers"
  WORKER_FILES=(/etc/hadoop/core-site.xml
                /etc/hadoop/yarn-site.xml
                /opt/zookeeper/conf/zoo.cfg)

  # Copy out configuration files to each worker
  for w in "${WORKER_IPS[@]}"; do
    echo "- $w"
    scp "${WORKER_FILES[@]}" "$w":.
    for f in "${WORKER_FILES[@]}"; do
      ssh "$w" sudo cp "$(basename "$f")" "$f"
    done
  done

  # If configuring for HA (and running on first manager), remove
  # yarn.resourcemanager.ha.id from worker copies of yarn-site.xml
  if [[ -n $MANAGER2_IP ]]; then
    echo
    echo "Removing YARN RM HA ID from workers"
    for w in "${WORKER_IPS[@]}"; do
      echo "- $w"
      ssh "$w" sudo sed -i \
        '/\<name\>yarn.resourcemanager.ha.id\</,/\<property\>/d' \
        /etc/hadoop/yarn-site.xml
    done
  fi

  # Create ZooKeeper myid files, assigning a unique number per worker
  echo
  echo "Creating ZooKeeper myid files on workers"
  for i in $(seq 1 "$NUM_WORKERS"); do
    w="${WORKER_IPS[$(( i - 1 ))]}"
    echo "- $w"
    echo "$i" | ssh "$w" "sudo tee /var/lib/zookeeper/myid > /dev/null"
  done
fi
