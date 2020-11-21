#!/bin/bash

set -euo pipefail
set -x

declare -r scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

docker run \
    --rm \
    \
    -v ${scriptDir}:/nc-ddns \
    -v /tmp/:/tmp/ \
    \
    -v /dev/log:/dev/log \
    -v /etc/timezone:/etc/timezone:ro \
    -v /etc/localtime:/etc/localtime:ro \
    \
    --name=nc-ddns \
    \
    pullme/nc-ddns:latest \
    \
    /nc-ddns/nc-ddns.sh -c /nc-ddns/ddns-info.txt
