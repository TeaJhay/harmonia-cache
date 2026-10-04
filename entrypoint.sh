#!/bin/sh
set -e
export PATH=/root/.nix-profile/bin:$PATH

set -a
: "${WORKERS:=4}"
: "${PRIORITY:=30}"
: "${MAX_CONNECTION_RATE:=256}"
: "${COMPRESSION:=true}"
: "${VIRTUAL_NIX_STORE:=/nix/store}"
: "${DB_PATH:=/nix/var/nix/db/db.sqlite}"
: "${CACHE_PRIV_KEY:=cache-priv-key.pem}"
: "${CACHE_PUB_KEY:=cache-pub-key.pem}"

mkdir -p /etc/ssh /var/empty /run/sshd /root/.ssh /keys
chmod 700 /root/.ssh
grep -q '^sshd:' /etc/passwd || echo 'sshd:x:74:74:sshd:/var/empty:/bin/false' >> /etc/passwd

# Generate keys on first run; they persist in the /keys volume
[ -f /keys/ssh_host_ed25519_key ] || ssh-keygen -t ed25519 -N "" -f /keys/ssh_host_ed25519_key
[ -f "/keys/${CACHE_PRIV_KEY}" ] || nix-store --generate-binary-cache-key \
    cache.lan-1 "/keys/${CACHE_PRIV_KEY}" "/keys/${CACHE_PUB_KEY}"
echo "Cache public key: $(cat "/keys/${CACHE_PUB_KEY}")"

# Builders' public keys
if [ -f /keys/authorized_keys ]; then
  cp /keys/authorized_keys /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
fi
# ===================== sshd =====================
mkdir -p /var/empty /run/sshd /root/.ssh /keys
chmod 700 /root/.ssh
if [ -n "$SSH_AUTHORIZED_KEYS" ]; then
  printf '%s\n' "$SSH_AUTHORIZED_KEYS" > /root/.ssh/authorized_keys
elif [ -f /keys/authorized_keys ]; then
  cp /keys/authorized_keys /root/.ssh/authorized_keys
fi
[ -f /root/.ssh/authorized_keys ] && chmod 600 /root/.ssh/authorized_keys

# A locked root account is refused even with a valid key; '*' = no password, keys allowed
if [ -f /etc/shadow ]; then
  while IFS= read -r l; do
    case "$l" in root:*) l="root:*:${l#root:*:}";; esac
    printf '%s\n' "$l"
  done < /etc/shadow > /tmp/shadow.new
  cat /tmp/shadow.new > /etc/shadow
  rm -f /tmp/shadow.new
fi

grep -q '^sshd:' /etc/passwd || echo 'sshd:x:74:74:sshd:/var/empty:/bin/false' >> /etc/passwd
[ -f /keys/ssh_host_ed25519_key ] || ssh-keygen -t ed25519 -N '' -f /keys/ssh_host_ed25519_key
"$(command -v sshd)" -D -e -f /dev/null -h /keys/ssh_host_ed25519_key \
  -o PermitRootLogin=prohibit-password -o PasswordAuthentication=no &
  
TPL="${CIRCUS_TEMPLATE:=/etc/harmonia.toml.tpl}"
OUT="${CIRCUS_RENDERED:=/etc/harmonia.toml}"
VARS="$(grep -o '\${[A-Za-z_][A-Za-z0-9_]*}' "$TPL" | sort -u | tr '\n' ' ')"
envsubst "$VARS" < "$TPL" > "$OUT"

export CONFIG_FILE="${CONFIG_FILE:=$OUT}"
exec harmonia-cache
