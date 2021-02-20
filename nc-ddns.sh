#!/bin/bash
#
# (C) Marco Vedovati <mv@sba.lat> - 2020
# SPDX-License-Identifier: Apache-2.0
#
# Namecheap Dynamic DNS updater
#
set -euo pipefail

declare -r myName="nc-ddns"
declare configFile=
declare -r cachedIpFile="${XDG_RUNTIME_DIR:-/tmp}/ddns-ip"
declare -r urlPrefix="https://dynamicdns.park-your-domain.com/update"
declare -r respSuccessPattern="<ErrCount>0</ErrCount>"
declare -A urlParams=( [host]="" [domain]="" [password]="" [ip]="" )
declare dryRun=
declare debug=


info() {
	[ -z "$debug" ] ||  echo "INFO: $@"
}

get_ip() {
	curl -fsSL "icanhazip.com"
}

update_ip() {
	local fullUrl="${urlPrefix}"

	local sep=
	for key in "${!urlParams[@]}"; do
		value="${urlParams[$key]}"
		[ -n "$key" ] && [ -n "$value" ] || { echo "ERR: empty key/value pair: \"$key\":\"$value"\"; exit -1; }

		fullUrl+="${sep:-?}$key=$value"
		sep="&"
	done

	info "cURL URL: $fullUrl"

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

	info "got response: $response"
	[[ $response =~ $respSuccessPattern ]] ||
		{ echo "ERR: cURL response is not successful: \"$response\""; exit -1; }
}

read_config() {
	local ip="$1"
	[ -n "$ip" ] || { echo "ERR: need an IP"; exit -1; }

	if [ -f "$configFile" ]; then
    	. "$configFile"
    else
        echo "WARN: missing DDNS info file. Using config from env variables"

        if [ -z ${NC_DDNS_HOST:-} ] ||
           [ -z ${NC_DDNS_DOMAIN:-} ] ||
           [ -z ${NC_DDNS_PASSWORD:-} ]; then
            echo "ERR: could not get DDNS confg from env variables"
            exit -1
        fi

    fi

	urlParams[host]="$NC_DDNS_HOST"
	urlParams[domain]="$NC_DDNS_DOMAIN"
	urlParams[password]="$NC_DDNS_PASSWORD"

	urlParams[ip]="$1"
}

ip_is_cached() {
	local ip="$1"
	[ -n "$ip" ] || { echo "ERR: need an IP"; exit -1; }

	local cachedIp=
	if [ -f "$cachedIpFile" ]; then

		# read return > 0 when EOF is met...
		read -r cachedIp < "$cachedIpFile" || true

		if [ -z "$cachedIp" ]; then
            echo "WARN: cached IP file content is invalid"
        else
		    info "cached IP: $cachedIp"
        fi
	else
		echo "WARN: missing DDNS cached IP file: \"$cachedIpFile\""
	fi

	[ "$cachedIp" = "$ip" ]
}

resolve_ddns_ip() {
	local fullDomain="${urlParams[host]}.${urlParams[domain]}"
	#info "full domain: ${fullDomain}"

	dig +short "${fullDomain}" || { echo "ERR: dig lookup for domain name failed"; exit -1; }
}

main() {
	parse_args "$@"
	local currIp=`get_ip`
	[ -n "$currIp" ] || { echo "ERR: failed to get IP"; exit -1; }
	info "current IP: $currIp"

	read_config "$currIp"

	if ip_is_cached "$currIp"; then
		info "IP hasn't changed, nothing to do"

		local resolvedIp="$(resolve_ddns_ip)"

		[ -n "$resolvedIp" ] || { echo "ERR: unable to resolve IP"; exit -1; }

		if [ "$resolvedIp" != "$currIp" ]; then
			echo "WARN: current IP \"$currIp\" does not match resolved IP \"$resolvedIp\", invalidating cache"
			rm -f "$cachedIpFile"
		fi

		exit 0
	fi

	update_ip

	echo -n "$currIp" > "$cachedIpFile"
	echo "DONE"
}

parse_args() {
	OPTIND=1
	while getopts c:dfhn name
	do
		#echo "ARG: $name"
		case $name in

			c)
				configFile="$OPTARG"
				info "overriding config file path: ${configFile}"
				;;

			d)
				debug=1
				info "Debug info ON"
				;;

			f)
				info "forcing update by deleting cached IP file";
				rm -f "$cachedIpFile"
				;;

			n)
				dryRun=1
				info "Dry run"
				;;

			h | ?)
				printf "\nUsage: %s [-c config-file] [-d] [−n] [-h] [−f]\n" "$myName"
				printf "
Options:
 -c :  Configuration file path (default: get config via env variables)
 -d :  print debug info (default: false)
 -f :  Force update (invalidate the cached IP)
 -h :  help
 -n :  Dry-run
\n"
				exit 2
				;;

		esac
	done

	shift "$(( $OPTIND - 1 ))"
	[ -z "$*" ] || { echo "ERR: non-option arguments found: \"$*\""; exit 2; }
}

main "$@"
