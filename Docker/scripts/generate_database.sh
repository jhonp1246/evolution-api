#!/bin/bash

source ./Docker/scripts/env_functions.sh

if [ "$DOCKER_ENV" != "true" ]; then
    export_env_vars
fi

# Always run prisma generate so that TypeScript types are available at build
# time. prisma generate only reads the schema file — it does NOT require a
# live database connection. We default to the postgresql schema when
# DATABASE_PROVIDER is not set (e.g. during a Docker build on Railway where
# env vars are injected at runtime, not build time). deploy_database.sh will
# re-run db:generate at container start with the correct provider anyway.
SCHEMA_PROVIDER="${DATABASE_PROVIDER:-postgresql}"

# psql_bouncer shares the postgresql schema
if [ "$SCHEMA_PROVIDER" == "psql_bouncer" ]; then
    SCHEMA_PROVIDER="postgresql"
fi

if [[ "$SCHEMA_PROVIDER" == "postgresql" || "$SCHEMA_PROVIDER" == "mysql" ]]; then
    echo "Running prisma generate with schema: ./prisma/${SCHEMA_PROVIDER}-schema.prisma"
    npx prisma generate --schema "./prisma/${SCHEMA_PROVIDER}-schema.prisma"
    if [ $? -ne 0 ]; then
        echo "Prisma generate failed"
        exit 1
    else
        echo "Prisma generate succeeded"
    fi
else
    echo "Error: Cannot determine a valid schema for DATABASE_PROVIDER='${DATABASE_PROVIDER}'. Skipping prisma generate."
    exit 1
fi