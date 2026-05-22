#!/bin/bash

source ./Docker/scripts/env_functions.sh

if [ "$DOCKER_ENV" != "true" ]; then
    export_env_vars
fi

# DATABASE_PROVIDER may not be set at Docker build time because Railway
# environment variables are only injected at runtime. If the provider is
# unset we skip Prisma client generation here — deploy_database.sh will
# run db:generate again at container start when all env vars are present.
if [ -z "$DATABASE_PROVIDER" ]; then
    echo "DATABASE_PROVIDER is not set (likely a build-time environment). Skipping Prisma generate — will run at container start."
    exit 0
fi

if [[ "$DATABASE_PROVIDER" == "postgresql" || "$DATABASE_PROVIDER" == "mysql" || "$DATABASE_PROVIDER" == "psql_bouncer" ]]; then
    export DATABASE_URL
    echo "Generating database for $DATABASE_PROVIDER"
    echo "Database URL: $DATABASE_URL"
    npm run db:generate
    if [ $? -ne 0 ]; then
        echo "Prisma generate failed"
        exit 1
    else
        echo "Prisma generate succeeded"
    fi
else
    echo "Error: Database provider $DATABASE_PROVIDER invalid."
    exit 1
fi