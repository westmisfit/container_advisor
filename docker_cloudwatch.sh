#!/bin/bash

now=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)

for id in `docker ps --no-trunc -q`; do
	name=$(docker inspect -f '{{ .Name }}' $id)
	name="$(hostname)_${name:1}_used_memory"
	mem=$(cat /sys/fs/cgroup/memory/docker/$id/memory.stat | awk '$1=="active_anon" { print $2 }')
	aws cloudwatch put-metric-data --metric-name "$name" --namespace "Docker" --value "$mem" --timestamp "$now" --unit "Bytes"
done

echo "last updated: $now"
