#!/bin/bash
#
# (C) Marco Vedovati <mv@sba.lat> - 2020
# SPDX-License-Identifier: Apache-2.0
#
# Namecheap Dynamic DNS updater
#
set -euo pipefail

declare -r myName="nc-ddns"
declare configFile="$HOME/ddns-info.txt"
declare -r cachedIpFile="${XDG_RUNTIME_DIR:-/run/user/`id -u`}/ddns-ip"
declare -r urlPrefix="https://dynamicdns.park-your-domain.com/update"
declare -r respSuccessPattern="<ErrCount>0</ErrCount>"
declare -A urlParams=( [host]="" [domain]="" [password]="" [ip]="" )
declare dryRun=

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

	curlCmd=( \
		curl \
		-fsSL \
		"$fullUrl" \
	)

	if [ -n "$dryRun" ]; then
		echo "DRY-RUN: ${curlCmd[@]}"
		return
	fi

	local response=
	read -r response <<< \
		"$(${curlCmd[@]} || { echo "ERR: cURL for IP update failed"; exit -1; })"

	echo "INFO: got response: $response"
	[[ $response =~ $respSuccessPattern ]] ||
		{ echo "ERR: cURL response is not successful: \"$response\""; exit -1; }
}

setParams() {
	local newIp="$1"
	[ -n "$newIp" ] || { echo "ERR: need an IP"; exit -1; }

	[ -f "$configFile" ] || { echo "ERR: missing DDNS info file \"$configFile\""; exit -1; }
	. "$configFile"

	urlParams[host]="$ddnsHost"
	urlParams[domain]="$ddnsDomain"
	urlParams[password]="$ddnsPassword"

	urlParams[ip]="$1"
}

main() {
	parse_args "$@"
	local currIp=`get_ip`
	[ -n "$currIp" ] || { echo "ERR: failed to get IP"; exit -1; }
	echo "INFO: current IP: $currIp"

	local cachedIp=
	if [ -f "$cachedIpFile" ]; then

		# read return > 0 when EOF is met...
		read -r cachedIp < "$cachedIpFile" || true

		[ -z "$cachedIp" ] && { echo "ERR: cached IP file content is invalid"; exit -1; }
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

parse_args() {
	OPTIND=1
	while getopts hfnc: name
	do
		#echo "ARG: $name"
		case $name in
			f)
				echo "INFO: forcing update by deleting cached IP file";
				rm -f "$cachedIpFile"
				;;

			n)
				dryRun=1
				echo "INFO: Dry run"
				;;

			c)
				configFile="$OPTARG"
				echo "INFO: overriding config file path: ${configFile}"
				;;

			h | ?)
				printf "\nUsage: %s [-h] [−f] [-n] [−c value]\n" "$myName"
				printf "
Options:
 -h :  help
 -f :  Force update
 -n :  Dry-run
 -c :  Configuration file path\n\n"
				exit 2
				;;
		esac
	done

	shift "$(( $OPTIND - 1 ))"
	[ -z "$*" ] || { echo "ERR: non-option arguments found: \"$*\""; exit 2; }
}

main "$@"
