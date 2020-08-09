# Namecheap Dynamic DNS Updater
Just a simple _bash_ + _cURL_ based updater for the [Namecheap](https://www.namecheap.com/) Dynamic DNS service.

This updater does not use _nslookup_ to check for the configured host IP. That's
because the DNS resolver may respond an outdated IP address value when queried,
because of cache TTL, etc ...

So, it uses a local file cache storing the last successful IP address sent to Namecheap
for the host.

## Configuration
You need to create a `$HOME/ddns-info.txt` file with the Namecheap domain details.

E.g., if your DDNS domain name is `ddns.example.com`, the content of that file
should be:
```
declare -r ddnsHost="ddns"
declare -r ddnsDomain="example.com"
declare -r ddnsPassword="namecheap-ddns-password"
```
The `ddnsPassword` shall be retrieved from the Namecheap web control panel.

## Usage Examples
### Forcing Updates
Pass the `-f` flag to force IP to Host update, no matter the cache content.

### With cron
This is supposed to be used with something like cron with for periodically refreshing
the DNS domain name, e.g. add to `crontab -e`:
```
# update DDNS
*/5 * * * *    cd ~/nc-ddns && chronic ./nc-ddns.sh | logger -t nc-ddns
```

## Limitations
- Right now only a single host per machine is supported.
- Configuration & cache files paths are hard-coded.

## Notes
