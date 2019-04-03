#!/bin/bash
set -e

if [[ "$1" = "bitcoind" ]]; then
    exec gosu bitcoin "$@"
elif [[ "$1" == "bitcoin-cli" ]]; then
    exec gosu bitcoin "$@"
elif [[ "$1" == "bitcoin-tx" ]]; then
    exec gosu bitcoin "$@"
else
    exec "$@"
fi
