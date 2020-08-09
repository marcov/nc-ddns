# Namecheap Dynamic DNS Updater
Just a simple bash + cURL based updater for the Namecheap Dynamic DNS service.

This updater does not use _nslookup_ to check for the configured host IP. That's
because the DNS resolver may respond with the most up to date IP value when queried,
because of cache TTL, etc...

So, it uses a local file cache storing the last successful IP address sent to Namecheap
for the host.

## Condfiguration
You need to create a `$HOME/ddns-info.txt` file with the Namecheap domain details.

E.g., if your DDNS host is `HOST.DOMAIN-NAME.COM`, the content of that file should
be:
```
declare -r ddnsHost="HOST"
declare -r ddnsDomain="DOMAIN-NAME.COM"
declare -r ddnsPassword="namecheap-ddns-password"
```
The `ddnsPassword` should be retrieved from the Namecheap web control panel.

## Usage Examples
### Force
Pass the `-f` flag to force IP to Host update, no matter the cache content.

### cron
This is supposed to be used with something like cron with for periodically refreshing
the DNS domain name, e.g. add to `crontab -e`:
```
# update DDNS
*/5 * * * *    cd ~/nc-ddns && chronic ./nc-ddns.sh | logger -t nc-ddns
```

## Limitations
- Right now only a single host per machine is supported.
- Config & cache file paths are hard-coded.

