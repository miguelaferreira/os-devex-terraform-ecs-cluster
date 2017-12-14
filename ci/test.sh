#!/usr/bin/env sh

set -e

if [ -f ".env" ]; then
  source .env
fi

set -v

echo "No infra is being built so no tests possible!"
