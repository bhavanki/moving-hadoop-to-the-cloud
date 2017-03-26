#!/usr/bin/env bash

dfs_used=$(/opt/hadoop/bin/hdfs dfsadmin -report | \
  grep -m 1 "DFS Used%" | cut -d ' ' -f 3 | sed 's/%//g')

/usr/local/bin/aws cloudwatch put-metric-data --metric-name DFSUsed \
  --namespace HadoopClusters --unit Percent --value "$dfs_used" \
  --dimensions Cluster=MyFirstCluster
