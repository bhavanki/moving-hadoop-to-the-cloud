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

HADOOP_VERSION="${HADOOP_VERSION:-2.7.2}"

# Download and install Hadoop
echo "Downloading Hadoop $HADOOP_VERSION ..."
curl -O "https://archive.apache.org/dist/hadoop/common/hadoop-2.7.2/hadoop-2.7.2.tar.gz"
echo "Installing Hadoop ..."
sudo tar xzfC "hadoop-${HADOOP_VERSION}.tar.gz" /opt
sudo chown -R root:root /opt/hadoop-*
sudo ln -s "/opt/hadoop-${HADOOP_VERSION}" /opt/hadoop

# Add Hadoop to the PATH
for u in hdfs yarn; do
  echo "Adding Hadoop to PATH for $u ..."
  echo "export PATH=\"/opt/hadoop/bin:\$PATH\"" | sudo -u "${u}" tee -a "/home/${u}/.profile" > /dev/null
done

# Set up HADOOP_PREFIX
echo "Setting HADOOP_PREFIX systemwide ..."
echo "export HADOOP_PREFIX=/opt/hadoop" | sudo tee /etc/profile.d/hadoop.sh > /dev/null

# Set up /etc/hadoop link
echo "Linking /etc/hadoop ..."
sudo ln -s /opt/hadoop/etc/hadoop /etc/hadoop

# Create log and run directories
echo "Creating log and pid directories ..."
for d in /var/log/hadoop /var/run/hadoop; do
  sudo mkdir -p "$d"
  sudo chgrp hadoop "$d"
  sudo chmod g+w "$d"
done

# Create and install init.d script
echo "Writing init.d script for /var/run/hadoop ..."
# does this work?
sudo tee /etc/init.d/hadoop > /dev/null <<EOF
#!/bin/sh

### BEGIN INIT INFO
# Provides: hadoop_pid_dir
# Required-Start: \$remote_fs \$syslog
# Required-Stop: \$remote_fs \$syslog
# Default-Start:  2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Create Hadoop directories at boot
### END INIT INFO

case "\$1" in
  start)
    mkdir -p /var/run/hadoop
    chown root:hadoop /var/run/hadoop
    chmod 0775 /var/run/hadoop
    ;;
esac
EOF
sudo chmod +x /etc/init.d/hadoop
sudo update-rc.d hadoop defaults 98
