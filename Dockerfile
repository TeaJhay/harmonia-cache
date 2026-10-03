FROM nixos/nix:latest

RUN nix --extra-experimental-features 'nix-command flakes' \
      profile install nixpkgs#harmonia nixpkgs#gettext nixpkgs#openssh

ENV WORKERS=4 \
    MAX_CONNECTION_RATE=256 \
    PRIORITY=30 \
    COMPRESSION=true \
    VIRTUAL_NIX_STORE=/nix/store \
    DB_PATH=/nix/var/nix/db/db.sqlite \
    CACHE_PRIV_KEY=cache-priv-key.pem \
    CACHE_PUB_KEY=cache-pub-key.pem

COPY harmonia.toml.tpl /etc/harmonia.toml.tpl
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/nix", "/keys"]
EXPOSE 5000 22
ENTRYPOINT ["/entrypoint.sh"]
