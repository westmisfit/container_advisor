#!/bin/bash

set -e

now=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)

for id in `docker ps --no-trunc -q`; do
    container_name=$(docker inspect -f '{{ .Name }}' $id)
    metric_name="$(hostname)_${container_name:1}_used_memory_MB"

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
    if [[ -f "/sys/fs/cgroup/memory/docker/$id/memory.stat" ]]; then
        memstat="/sys/fs/cgroup/memory/docker/$id/memory.stat"
    elif [[ -f "/cgroup/memory/docker/$id/memory.stat" ]]; then
        memstat="/cgroup/memory/docker/$id/memory.stat"
    else
        exit 1
    fi

    mem=$(cat $memstat | awk '$1=="active_anon" { printf "%.2f \n", $2/1024/1024 }')

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
    aws cloudwatch put-metric-data --metric-name "$metric_name" --namespace "Docker" --value "$mem" --timestamp "$now" --unit "Megabytes"
done

echo "last updated: $now"
