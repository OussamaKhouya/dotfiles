#!/usr/bin/env bash

seconds=$(cut -d. -f1 /proc/uptime)
hours=$((seconds / 3600))
tooltip=$(uptime -p)

printf '{"text":"%s","tooltip":"%s"}\n' "$hours" "$tooltip"
