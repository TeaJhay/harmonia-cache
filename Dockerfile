FROM nixos/nix:latest

ENV NIX_CONFIG="experimental-features = nix-command flakes"

RUN nix profile add github:nix-community/harmonia nixpkgs#gettext

COPY harmonia.toml.tpl /etc/harmonia.toml.tpl
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/nix", "/keys"]
EXPOSE 5000 22
ENTRYPOINT ["/entrypoint.sh"]
