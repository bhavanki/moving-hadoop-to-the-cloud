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

JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-1.8.0-openjdk-amd64}"

replace_line() {
  local f="$1"
  local m="$2"
  local r="$3"

  local subst="s:^.*${m}.*\$:${r}:"
  sudo sed -i "$subst" "$f"
}

add_hadoop_property() {
  local f="$1"
  local n="$2"
  local v="$3"

  local tf
  tf="$(mktemp)"
  xmlstarlet ed -P --subnode configuration -t elem -n property "$f" | \
    xmlstarlet ed -P --subnode "configuration/property[last()]" -t elem -n name -v "$n" | \
    xmlstarlet ed -P --subnode "configuration/property[last()]" -t elem -n value -v "$v" | \
    xmlstarlet fo > "$tf"
  sudo mv "$tf" "$f"
}

# Configure hadoop-env.sh
echo "Configuring hadoop-env.sh ... "
replace_line /etc/hadoop/hadoop-env.sh "JAVA_HOME=" "export JAVA_HOME=${JAVA_HOME}"
replace_line /etc/hadoop/hadoop-env.sh "HADOOP_LOG_DIR=" "export HADOOP_LOG_DIR=/var/log/hadoop"
replace_line /etc/hadoop/hadoop-env.sh "HADOOP_PID_DIR=" "export HADOOP_PID_DIR=/var/run/hadoop"

# Configure yarn-env.sh
echo "Configuring yarn-env.sh ..."
replace_line /etc/hadoop/yarn-env.sh "YARN_CONF_DIR=" "export YARN_CONF_DIR=/etc/hadoop"
replace_line /etc/hadoop/yarn-env.sh "YARN_LOG_DIR=" "export YARN_LOG_DIR=\"\$HADOOP_LOG_DIR\""
echo "YARN_OPTS=\"\$YARN_OPTS -Djava.net.preferIPv4Stack=true\"" | sudo tee -a /etc/hadoop/yarn-env.sh > /dev/null

# Configure core-site.xml
echo "Configuring core-site.xml ..."
add_hadoop_property /etc/hadoop/core-site.xml fs.defaultFS "hdfs://\${manager.ip}:8020"
add_hadoop_property /etc/hadoop/core-site.xml hadoop.tmp.dir "/home/\${user.name}/tmp"
# HA:
#add_hadoop_property /etc/hadoop/core-site.xml ha.zookeeper.quorum "\${worker1.ip}:2181,\${worker2.ip}:2181,\${worker3.ip}:2181"
# S3A:
#add_hadoop_property /etc/hadoop/core-site.xml fs.s3a.access.key "\${aws.access.key}"
#add_hadoop_property /etc/hadoop/core-site.xml fs.s3a.secret.key "\${aws.secret.key}"

# Configure yarn-site.xml
echo "Configuring yarn-site.xml ..."
add_hadoop_property /etc/hadoop/yarn-site.xml yarn.resourcemanager.hostname "\${manager.ip}"
add_hadoop_property /etc/hadoop/yarn-site.xml yarn.nodemanager.aux-services mapreduce_shuffle
# HA:
#add_hadoop_property /etc/hadoop/yarn-site.xml yarn.resourcemanager.ha.enabled true
#add_hadoop_property /etc/hadoop/yarn-site.xml yarn.resourcemanager.cluster-id myfirstcluster
#add_hadoop_property /etc/hadoop/yarn-site.xml yarn.resourcemanager.ha.rm-ids rm1,rm2
#add_hadoop_property /etc/hadoop/yarn-site.xml yarn.resourcemanager.ha.id rm1
#add_hadoop_property /etc/hadoop/yarn-site.xml yarn.resourcemanager.hostname.rm1 "\${manager.ip}"
#add_hadoop_property /etc/hadoop/yarn-site.xml yarn.resourcemanager.hostname.rm2 "\${manager2.ip}"
#add_hadoop_property /etc/hadoop/yarn-site.xml yarn.resourcemanager.zk-address "\${worker1.ip}:2181,\${worker2.ip}:2181,\${worker3.ip}:2181"
#add_hadoop_property /etc/hadoop/yarn-site.xml yarn.resourcemanager.ha.automatic-failover.enabled true
#add_hadoop_property /etc/hadoop/yarn-site.xml yarn.resourcemanager.ha.automatic-failover.embedded true
# Spark:
#add_hadoop_property /etc/hadoop/yarn-site.xml yarn.log-aggregation-enable true

# Configure hdfs-site.xml for HA
# echo "Configuring hdfs-site.xml ..."
#add_hadoop_property /etc/hadoop/hdfs-site.xml dfs.nameservices myfirstcluster
#add_hadoop_property /etc/hadoop/hdfs-site.xml dfs.ha.namenodes.myfirstcluster nn1,nn2
#add_hadoop_property /etc/hadoop/hdfs-site.xml dfs.namenode.rpc-address.myfirstcluster.nn1 "\${manager.ip}:8020"
#add_hadoop_property /etc/hadoop/hdfs-site.xml dfs.namenode.rpc-address.myfirstcluster.nn2 "\${manager2.ip}:8020"
#add_hadoop_property /etc/hadoop/hdfs-site.xml dfs.namenode.http-address.myfirstcluster.nn1 "\${manager.ip}:50070"
#add_hadoop_property /etc/hadoop/hdfs-site.xml dfs.namenode.http-address.myfirstcluster.nn2 "\${manager2.ip}:50070"
#add_hadoop_property /etc/hadoop/hdfs-site.xml dfs.namenode.shared.edits.dir "qjournal://\${worker1.ipz}:8485;\${worker2.ip}:8485;\${worker3.ip}:8485/myfirstcluster"
#add_hadoop_property /etc/hadoop/hdfs-site.xml dfs.client.failover.proxy.provider.myfirstcluster org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider
#add_hadoop_property /etc/hadoop/hdfs-site.xml dfs.journalnode.edits.dir /var/data/jn
#add_hadoop_property /etc/hadoop/hdfs-site.xml dfs.ha.fencing.methods "shell(/bin/true)"
#add_hadoop_property /etc/hadoop/hdfs-site.xml dfs.ha.automatic-failover.enabled true

# Configure mapred-site.xml
echo "Configuring mapred-site.xml ..."
sudo cp /etc/hadoop/mapred-site.xml.template /etc/hadoop/mapred-site.xml
add_hadoop_property /etc/hadoop/mapred-site.xml mapreduce.framework.name yarn
add_hadoop_property /etc/hadoop/mapred-site.xml yarn.app.mapreduce.am.staging-dir /user
# S3A:
# add_hadoop_property /etc/hadoop/mapred-site.xml mapreduce.application.classpath

# /etc/hadoop/slaves is not configured; write the whole thing later
