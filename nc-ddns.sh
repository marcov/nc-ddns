#!/bin/bash
#
# (C) Marco Vedovati <mv@sba.lat> - 2020
# SPDX-License-Identifier: Apache-2.0
#
# Updates Namecheap DDNS updater
#
set -euo pipefail

declare -r ddnsInfoFile="$HOME/ddns-info.txt"
declare -r cachedIpFile="$XDG_RUNTIME_DIR/ddns-ip"
declare -r urlPrefix="https://dynamicdns.park-your-domain.com/update"
declare -r respSuccessPattern="<ErrCount>0</ErrCount>"
declare -A urlParams=( [host]="" [domain]="" [password]="" [ip]="" )

get_ip() {
	curl -fsSL "icanhazip.com"
}

update_ip() {
	local fullUrl="${urlPrefix}"

	local sep="?"

	for key in "${!urlParams[@]}"; do
		value="${urlParams[$key]}"
		[ -n "$key" ] && [ -n "$value" ] || { echo "ERR: empty key/value pair: \"$key\":\"$value"\"; exit -1; }

		fullUrl+="${sep}$key=$value"

		[ "$sep" = "&" ] || sep="&"
	done

	echo "INFO: cURL URL: $fullUrl"

	local response=
	read -r response <<< \
		"$(curl -fsSL "$fullUrl" || { echo "ERR: cURL for IP update failed"; exit -1; })"

	echo "INFO: got response: $response"

	[[ $response =~ $respSuccessPattern ]] ||
		{ echo "ERR: cURL response is not successful: \"$response\""; exit -1; }
}

setParams() {
	local newIp="$1"
	[ -n "$newIp" ] || { echo "ERR: need an IP"; exit -1; }

	[ -f "$ddnsInfoFile" ] || { echo "ERR: missing DDNS info file \"$ddnsInfoFile\""; exit -1; }
	. "$ddnsInfoFile"

	urlParams[host]="$ddnsHost"
	urlParams[domain]="$ddnsDomain"
	urlParams[password]="$ddnsPassword"

	urlParams[ip]="$1"
}

main() {
	local currIp=`get_ip`
	[ -n "$currIp" ] || { echo "ERR: failed to get IP"; exit -1; }
	echo "INFO: current IP: $currIp"

	local cachedIp=
	if [ -f "$cachedIpFile" ] && \
		read -r cachedIp < "$cachedIpFile"; then
		echo "INFO: cached IP: $cachedIp"
	else
		echo "WARN: missing DDNS cached IP file: \"$cachedIpFile\""
	fi

	[ "$cachedIp" = "$currIp" ] && { echo "INFO: IP hasn't changed, nothing to do"; return; }

	setParams "$currIp"
	update_ip
	echo -n "$currIp" > "$cachedIpFile"
	echo "DONE"
}

[ "${1:-}" = "-f" ] &&
	{ echo "INFO: forcing update by deleting cached IP file...";
		rm -f "$cachedIpFile"; } ||
	{ echo "INFO: normal update mode"; }

main
