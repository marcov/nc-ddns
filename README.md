# Namecheap Dynamic DNS Updater
Just a simple bash + cURL based updater for the Namecheap Dynamic DNS service.

## Usage
You need to create a `$HOME/ddns-info.txt` file with the Namecheap domain details.

E.g., if your DDNS host is `HOST.DOMAIN-NAME.COM`, the content of that file should
be:
```
declare -r ddnsHost="HOST"
declare -r ddnsDomain="DOMAIN-NAME.COM"
declare -r ddnsPassword="namecheap-ddns-password"
```
The `ddnsPassword` should be retrieved from the Namecheap web control panel.

## Examples
This is supposed to be used with something like cron with for periodically refreshing
the DNS domain name, e.g.:
```
# update DDNS
*/5 * * * *    cd ~nc-ddns && chronic ./nc-ddns.sh | logger -t nc-ddns
```
