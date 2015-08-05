#!/bin/bash

set -e

##
# Control groups
#
# Linux Containers rely on control groups which not only track groups 
# of processes, but also expose metrics about CPU, memory, and block I/O 
# usage. You can access those metrics and obtain network usage metrics as 
# well. This is relevant for “pure” LXC containers, as well as for Docker 
# containers.
# 
# Control groups are exposed through a pseudo-filesystem. In recent 
# distros, you should find this filesystem under /sys/fs/cgroup. Under
# that directory, you will see multiple sub-directories, called devices,
# freezer, blkio, etc.; each sub-directory actually corresponds to a
# different cgroup hierarchy.
# 
# On older systems, the control groups might be mounted on /cgroup,
# without distinct hierarchies. In that case, instead of seeing the
# sub-directories, you will see a bunch of files in that directory, and
# possibly some directories corresponding to existing containers.
# 
# To figure out where your control groups are mounted, you can run:
# 
# $ grep cgroup /proc/mounts
# 
##
if grep cgroup /proc/mounts | grep /sys/fs/cgroup >/dev/null; then
    cgroup=/sys/fs/cgroup
elif grep cgroup /proc/mounts | grep /cgroup >/dev/null; then
    cgroup=/cgroup
fi

now=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)
instance_id=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)
mechine_mem=$(cat /proc/meminfo | awk '$1=="MemTotal:" {print $2*1024}')
# echo mechine_mem=$mechine_mem
metric_data="["

count=0
for id in `docker ps --no-trunc -q`; do
    container_name=$(docker inspect -f '{{ .Name }}' $id)
    container_name=${container_name:1}
    image_name=$(docker inspect -f '{{ .Config.Image }}' $id)
    ecs_container_name=$(docker inspect -f '{{ index .Config.Labels "com.amazonaws.ecs.container-name" }}' $id)
    ecs_task_family=$(docker inspect -f '{{ index .Config.Labels "com.amazonaws.ecs.task-definition-family" }}' $id)

    if [[ "$ecs_container_name" = "" ]] || [[ "$ecs_container_name" = "<no value>" ]]; then continue; fi

    # memory
    mem_path="$cgroup/memory/docker/$id"
    mem_usage=$(cat $mem_path/memory.usage_in_bytes)
    mem_usage_MB=$(echo $mem_usage | awk '{printf "%.2f", $1/1024/1024}')
    # mem_max_usage=$(cat $mem_path/memory.max_usage_in_bytes)
    # mem_max_usage_MB=$(echo $mem_max_usage | awk '{printf "%.2f", $1/1024/1024}')
    mem_limit=$(cat $mem_path/memory.limit_in_bytes)
    if [[ $mem_limit -gt $mechine_mem ]]; then
        mem_limit=$mechine_mem
    fi
    # echo mem_limit=$mem_limit
    mem_usage_percent=$(echo "$mem_usage" "$mem_limit" | awk '{printf "%.2f", $1/$2*100}')

    # cpu
    # cpu_path="$cgroup/cpu/docker/$id"

    # counter
    if [[ $counter -gt 0 ]]; then
        metric_data="$metric_data,"
    fi
    counter=$((counter+1))

    ##
    # Unit
    #
    # The unit of the metric.
    #
    # Type: String
    # 
    # Valid Values: Seconds | Microseconds | Milliseconds | Bytes | 
    # Kilobytes | Megabytes | Gigabytes | Terabytes | Bits | Kilobits | 
    # Megabits | Gigabits | Terabits | Percent | Count | Bytes/Second | 
    # Kilobytes/Second | Megabytes/Second | Gigabytes/Second | 
    # Terabytes/Second | Bits/Second | Kilobits/Second | Megabits/Second | 
    # Gigabits/Second | Terabits/Second | Count/Second | None
    ##
    metric_data="$metric_data{
    \"MetricName\": \"MemoryUsage\",
    \"Dimensions\": [
      {\"Name\": \"InstanceId\",\"Value\": \"$instance_id\"},
      {\"Name\": \"ImageName\",\"Value\": \"$image_name\"},
      {\"Name\": \"ECSContainerName\",\"Value\": \"$ecs_container_name\"},
      {\"Name\": \"ECSTaskFamily\",\"Value\": \"$ecs_task_family\"}
    ],
    \"Value\": $mem_usage_MB,
    \"Unit\": \"Megabytes\"
  },{
    \"MetricName\": \"MemoryUsagePercent\",
    \"Dimensions\": [
      {\"Name\": \"InstanceId\",\"Value\": \"$instance_id\"},
      {\"Name\": \"ImageName\",\"Value\": \"$image_name\"},
      {\"Name\": \"ECSContainerName\",\"Value\": \"$ecs_container_name\"},
      {\"Name\": \"ECSTaskFamily\",\"Value\": \"$ecs_task_family\"}
    ],
    \"Value\": $mem_usage_percent,
    \"Unit\": \"Percent\"
  }"
done

metric_data="$metric_data]"
# echo $metric_data

if [[ $counter -gt 0 ]]; then
    aws cloudwatch put-metric-data --namespace "ECS Custom" --metric-data "$metric_data"
fi

echo "last updated: $now"
