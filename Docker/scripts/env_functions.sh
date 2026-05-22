export_env_vars() {
    if [ -f .env ]; then
        while IFS='=' read -r key value; do
            if [[ -z "$key" || "$key" =~ ^\s*# || -z "$value" ]]; then
                continue
            fi

            key=$(echo "$key" | tr -d '[:space:]')
            value=$(echo "$value" | tr -d '[:space:]')
            value=$(echo "$value" | tr -d "'" | tr -d "\"")

            export "$key=$value"
        done < .env
    else
        # At Docker build time there is no .env file — env vars come from the
        # runtime environment (e.g. Railway). Warn but do not exit so that
        # callers can decide whether to proceed or skip gracefully.
        echo ".env file not found — skipping env export"
    fi
}
