This is pretty much completely slopped as I didn't want to use nix for one thing on my homelab. Hopefully I'll go through and make this cleaner and better and documented. I just substituted the default config for vars you can control. Aimed for portainer but adapt to choice.

just add the ip:port and pub key from Harmonia to your nix.settings to use it as cache.

You can get the pub key by printing the pem file inside the docker container
```
printf "%s\n" "$(docker exec <container> cat /keys/cache-pub-key.pem)"
```

```
nix.settings = {
            substituters = [
              "http://127.0.0.1:5000" # If using direct IP.
              #"https://cache.your.domain" # If setup with reverse proxy
            ];
            trusted-public-keys = [
             "cache.lan-1:AAAAAAAAAAAAAAAAAAA=" # Enter pub key here
            ];
```
