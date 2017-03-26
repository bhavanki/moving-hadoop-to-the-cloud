#!/usr/bin/env bash

yarn_mem_used=$(/path/to/yarnmem.sh)

/usr/local/bin/aws cloudwatch put-metric-data --metric-name YarnMemUsage \
  --namespace HadoopClusters --unit Percent --value "$yarn_mem_used" \
  --dimensions Cluster=MyFirstCluster