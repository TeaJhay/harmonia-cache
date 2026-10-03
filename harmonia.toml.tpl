bind = "[::]:5000"
workers = ${WORKERS}
max_connection_rate = ${MAX_CONNECTION_RATE}
priority = ${PRIORITY}
enable_compression = ${COMPRESSION}
virtual_nix_store = "${VIRTUAL_NIX_STORE}"
nix_db_path = "${DB_PATH}"
sign_key_paths = ["/keys/${CACHE_PRIV_KEY}"]
