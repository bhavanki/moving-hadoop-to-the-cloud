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

# Generates SSH key pairs for accounts on one instance (manager), and distributes
# public keys to that instance and other instances (workers).

DEFAULT_ACCOUNTS=( ubuntu hdfs yarn zk )

usage() {
  cat << EOF
usage: $0 options manager-ips worker1-ips ...

OPTIONS:
  -a accts   Accounts to configure (default ${DEFAULT_ACCOUNTS[*]})
             Specify as space-separated list, e.g., "acct1 acct2 acct3"
  -G         Do not generate new SSH key pairs; use what is already available
  -i file    Identity file for SSH connections to manager
  -u user    User for SSH connections to manager
  -h         Shows this help message

Run this script on a machine that can connect to the manager instance via SSH.
The user account on the manager instance must have passwordless sudo access.

Pass the public and private IP addresses for each instance in the cluster as
a colon-separated pair, e.g., 203.0.113.101:192.168.1.101.

EXAMPLE:
  $0 -a "hdfs yarn" -i /path/to/key.pem -u ubuntu \\
    203.0.113.101:192.168.1.101 \\
    203.0.113.102:192.168.1.102 \\
    203.0.113.103:192.168.1.103 \\
    203.0.113.104:192.168.1.104
EOF
}

ACCOUNTS=( "${DEFAULT_ACCOUNTS[@]}" )
DO_NOT_GENERATE=
SSH_IDENTITY=
SSH_USER=
while getopts "a:Gi:u:h" opt
do
  case $opt in
    h)
      usage
      exit 0
      ;;
    a)
      ACCOUNTS=( $OPTARG )
      ;;
    G)
      DO_NOT_GENERATE=1
      ;;
    i)
      SSH_IDENTITY="$OPTARG"
      ;;
    u)
      SSH_USER="$OPTARG"
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

if [[ ${#ACCOUNTS[@]} == 0 ]]; then
  echo "No accounts specified"
  usage
  exit 1
fi

# Find manager IP addresses: "public IP:private IP"
MANAGER_PUBLIC_IP="${1%%:*}"
MANAGER_PRIVATE_IP="${1##*:}"
shift
# Collect remaining IP address pairs for workers
WORKER_IPS=( "$@" )

NUM_WORKERS=${#WORKER_IPS[@]}
MANAGER_HOSTNAME="$(hostname --fqdn)"

echo "Manager public IP: $MANAGER_PUBLIC_IP"
echo "Manager private IP: $MANAGER_PRIVATE_IP"
echo "Manager hostname: $MANAGER_HOSTNAME"
echo "${NUM_WORKERS} worker IPs: ${WORKER_IPS[*]}"
echo "Accounts: ${ACCOUNTS[*]}"

# Construct the SSH command with the provided identity file and username
SSH_CMD=( ssh )
if [[ -n $SSH_IDENTITY ]]; then
  SSH_CMD+=( -i "$SSH_IDENTITY" )
fi
if [[ -n $SSH_USER ]]; then
  SSH_CMD+=( -o "User=$SSH_USER" )
fi

# For each account ...
for acct in "${ACCOUNTS[@]}"; do

  # Note whether this account is the one used for SSH connections by this script
  if [[ -n $SSH_USER && "$acct" == "$SSH_USER" ]]; then
    issshuser=1
  else
    issshuser=
  fi

  echo
  if [[ -z $DO_NOT_GENERATE ]]; then
    # Generate a key pair on the manager instance using ssh-keygen
    echo "[$acct] Generating manager SSH key pair"
    "${SSH_CMD[@]}" -t "${MANAGER_PUBLIC_IP}" "sudo -u \"$acct\" ssh-keygen" \
      "-t rsa -b 2048 -f /home/$acct/.ssh/id_rsa -N ''"

    # Copy the new public key to the authorized_keys file on the manager
    # - If this account is the one being used by this script, then just
    #   append it to authorized_keys, don't outright replace the file
    echo "[$acct] Copying public SSH key to authorized_keys on manager"
    if [[ -n $issshuser ]]; then
      "${SSH_CMD[@]}" -t "${MANAGER_PUBLIC_IP}" \
        "sudo cat /home/$acct/.ssh/id_rsa.pub | sudo -u \"$acct\"" \
        "tee -a /home/$acct/.ssh/authorized_keys > /dev/null"
    else
      "${SSH_CMD[@]}" -t "${MANAGER_PUBLIC_IP}" \
        "sudo cat /home/$acct/.ssh/id_rsa.pub | sudo -u \"$acct\"" \
        "tee /home/$acct/.ssh/authorized_keys > /dev/null"
    fi
    # Set the permissions for authorized_keys appropriately
    "${SSH_CMD[@]}" -t "${MANAGER_PUBLIC_IP}" \
      "sudo chmod 600 /home/$acct/.ssh/authorized_keys"
  else
    echo "[$acct] Skipping manager SSH key pair generation"
  fi

  # Get the new public key
  echo "[$acct] Retrieving public SSH key"
  pubkey="$( "${SSH_CMD[@]}" -t "${MANAGER_PUBLIC_IP}" \
    "sudo cat /home/$acct/.ssh/id_rsa.pub" )"
  echo "[$acct] Public key contents:"
  echo "----"
  echo "$pubkey"
  echo "----"

  # For each worker ...
  for worker_ips in "${WORKER_IPS[@]}"; do

    # Write the public key to the authorized_keys file on the worker, creating
    # it and its directory if necessary
    # - Again, just append to the file if the account is being used here
    worker=${worker_ips%%:*}
    echo
    echo "[$acct] Installing public SSH key on $worker"
    "${SSH_CMD[@]}" -t "${worker}" \
      "sudo -u \"$acct\" mkdir -p -m 0700 /home/$acct/.ssh"
    "${SSH_CMD[@]}" "${worker}" "cat >> /tmp/pubkey" <<< "$pubkey"
    if [[ -n $issshuser ]]; then
      "${SSH_CMD[@]}" -t "${worker}" "sudo cat /tmp/pubkey | sudo -u \"$acct\"" \
        "tee -a /home/$acct/.ssh/authorized_keys > /dev/null"
    else
      "${SSH_CMD[@]}" -t "${worker}" "sudo cat /tmp/pubkey | sudo -u \"$acct\"" \
        "tee /home/$acct/.ssh/authorized_keys > /dev/null"
    fi
    "${SSH_CMD[@]}" -t "${worker}" "sudo chmod 600 /home/$acct/.ssh/authorized_keys"
    "${SSH_CMD[@]}" "${worker}" "rm /tmp/pubkey"

  done

  # Connect from the manager instance to itself and each worker so that the
  # new host keys are accepted now; this avoids being asked interactively later
  echo
  echo "[$acct] Connecting to each cluster instance from manager to" \
    "accept host keys"
  if [[ -n $MANAGER_HOSTNAME ]]; then
    "${SSH_CMD[@]}" -t "${MANAGER_PUBLIC_IP}" "sudo -u \"$acct\"" \
      "ssh -o StrictHostKeyChecking=no \"$MANAGER_HOSTNAME\" date > /dev/null"
  fi
  "${SSH_CMD[@]}" -t "${MANAGER_PUBLIC_IP}" "sudo -u \"$acct\"" \
    "ssh -o StrictHostKeyChecking=no \"$MANAGER_PRIVATE_IP\" date > /dev/null"
  "${SSH_CMD[@]}" -t "${MANAGER_PUBLIC_IP}" "sudo -u \"$acct\"" \
    "ssh -o StrictHostKeyChecking=no 0.0.0.0 date > /dev/null"
  for worker_ips in "${WORKER_IPS[@]}"; do
    worker=${worker_ips##*:} # connect from manager to private IP of worker
    "${SSH_CMD[@]}" -t "${MANAGER_PUBLIC_IP}" "sudo -u \"$acct\"" \
      "ssh -o StrictHostKeyChecking=no \"$worker\" date > /dev/null"
  done

done
