#!/bin/bash

source ./Docker/scripts/env_functions.sh

if [ "$DOCKER_ENV" != "true" ]; then
    export_env_vars
fi

# Always run `prisma generate` — it only reads the Prisma schema file and
# does not require a live database connection. This ensures the generated
# TypeScript client types are available for `npm run build` at Docker build
# time, even when DATABASE_PROVIDER is not yet set (Railway injects env vars
# at runtime, not build time).
# Note: runWithProvider.js defaults to 'postgresql' when DATABASE_PROVIDER is
# unset, so db:generate is safe to call unconditionally.
echo "Running Prisma client generation (schema-only, no DB connection required)..."
npm run db:generate
if [ $? -ne 0 ]; then
    echo "Prisma generate failed"
    exit 1
else
    echo "Prisma generate succeeded"
fi

# Database migrations DO require a live connection. Skip them when
# DATABASE_PROVIDER is not set (build time) — deploy_database.sh will
# run migrations at container start when all env vars are present.
if [ -z "$DATABASE_PROVIDER" ]; then
    echo "DATABASE_PROVIDER is not set (likely a build-time environment). Skipping database migrations — will run at container start."
    exit 0
fi

if [[ "$DATABASE_PROVIDER" == "postgresql" || "$DATABASE_PROVIDER" == "mysql" || "$DATABASE_PROVIDER" == "psql_bouncer" ]]; then
    export DATABASE_URL
    echo "Running database migrations for $DATABASE_PROVIDER"
    echo "Database URL: $DATABASE_URL"
    npm run db:deploy
    if [ $? -ne 0 ]; then
        echo "Database migration failed"
        exit 1
    else
        echo "Database migration succeeded"
    fi
else
    echo "Error: Database provider $DATABASE_PROVIDER invalid."
    exit 1
fi