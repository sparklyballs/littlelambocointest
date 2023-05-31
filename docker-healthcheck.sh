#!/bin/bash

# shellcheck disable=SC2154
if [[ ${healthcheck} != "true" ]]; then
    exit 0
fi

dt () {
    date +%FT%T.%3N
}

logger () {
    # shellcheck disable=SC2154
    if [[ ${log_to_file} != 'true' ]]; then
        echo "$1" >> /proc/1/fd/1
    else
        echo "$1" >> "${LITTLELAMBOCOIN_ROOT}/log/debug.log"
    fi
}

# Set default to false for all components
# Gets reset to true individually depending on ${service} variable
node_check=false
farmer_check=false
harvester_check=false
wallet_check=false

# Determine which services to healthcheck based on ${service}
# shellcheck disable=SC2154,SC2206
services_array=($service)
for option in "${services_array[@]}"
do
    case "${option}" in
        all)
            node_check=true
            farmer_check=true
            harvester_check=true
            wallet_check=true
        ;;
        node)
            node_check=true
        ;;
        harvester)
            harvester_check=true
        ;;
        farmer)
            node_check=true
            farmer_check=true
            harvester_check=true
            wallet_check=true
        ;;
        farmer-no-wallet)
            node_check=true
            farmer_check=true
            harvester_check=true
        ;;
        farmer-only)
            farmer_check=true
        ;;
        wallet)
            wallet_check=true
        ;;
    esac
done

# Always check the daemon
nc -z -v -w1 localhost 44453
# shellcheck disable=SC2181
if [[ "$?" -ne 0 ]]; then
    logger "$(dt) Daemon healthcheck failed"
    exit 1
fi

if [[ ${node_check} == "true" ]]; then
    curl -X POST --fail \
      --cert "${LITTLELAMBOCOIN_ROOT}/config/ssl/full_node/private_full_node.crt" \
      --key "${LITTLELAMBOCOIN_ROOT}/config/ssl/full_node/private_full_node.key" \
      -d '{}' -k -H "Content-Type: application/json" https://localhost:18714/healthz

    # shellcheck disable=SC2181
    if [[ "$?" -ne 0 ]]; then
        logger "$(dt) Node healthcheck failed"
        exit 1
    fi
fi

if [[ ${farmer_check} == "true" ]]; then
    curl -X POST --fail \
      --cert "${LITTLELAMBOCOIN_ROOT}/config/ssl/farmer/private_farmer.crt" \
      --key "${LITTLELAMBOCOIN_ROOT}/config/ssl/farmer/private_farmer.key" \
      -d '{}' -k -H "Content-Type: application/json" https://localhost:18543/healthz

    # shellcheck disable=SC2181
    if [[ "$?" -ne 0 ]]; then
        logger "$(dt) Farmer healthcheck failed"
        exit 1
    fi
fi

if [[ ${harvester_check} == "true" ]]; then
    curl -X POST --fail \
      --cert "${LITTLELAMBOCOIN_ROOT}/config/ssl/harvester/private_harvester.crt" \
      --key "${LITTLELAMBOCOIN_ROOT}/config/ssl/harvester/private_harvester.key" \
      -d '{}' -k -H "Content-Type: application/json" https://localhost:18779/healthz

    # shellcheck disable=SC2181
    if [[ "$?" -ne 0 ]]; then
        logger "$(dt) Harvester healthcheck failed"
        exit 1
    fi
fi

if [[ ${wallet_check} == "true" ]]; then
    curl -X POST --fail \
      --cert "${LITTLELAMBOCOIN_ROOT}/config/ssl/wallet/private_wallet.crt" \
      --key "${LITTLELAMBOCOIN_ROOT}/config/ssl/wallet/private_wallet.key" \
      -d '{}' -k -H "Content-Type: application/json" https://localhost:19678/healthz

    # shellcheck disable=SC2181
    if [[ "$?" -ne 0 ]]; then
        logger "$(dt) Wallet healthcheck failed"
        exit 1
    fi
fi

# shellcheck disable=SC2154
if [[ ${log_level} == 'INFO' ]]; then
    logger "$(dt) Healthcheck(s) completed successfully"
fi
