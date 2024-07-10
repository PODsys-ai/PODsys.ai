#!/bin/bash
cd "$(dirname "$0")"

if dpkg -l | grep -q "stress"; then
  echo "stress installed"
else
  dpkg -i  stress/*.deb > /dev/null 2>&1
fi
stress --cpu $(( $(nproc) - 1 ))