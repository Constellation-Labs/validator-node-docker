#!/bin/bash

source /app/scripts/health-check.sh
source /app/scripts/metagraph-l0.sh
source /app/scripts/currency-l1.sh
source /app/scripts/data-l1.sh

# Ensure shared data directory exists
mkdir -p "/app/shared-data"

# Normalize and prepare LAYERS_TO_RUN
LAYERS_TO_RUN_CSV=$(echo "$LAYERS_TO_RUN" | tr '[:upper:]' '[:lower:]')

# Conditionally start services
[[ "$LAYERS_TO_RUN_CSV" == *"ml0"* ]] && start_metagraph_l0_service
[[ "$LAYERS_TO_RUN_CSV" == *"cl1"* ]] && start_currency_l1_service
[[ "$LAYERS_TO_RUN_CSV" == *"dl1"* ]] && start_data_l1_service

echo "Waiting for services to start..."
sleep 10

while true; do
  for service in metagraph-l0 currency-l1 data-l1; do
    case $service in
      "metagraph-l0") [[ "$LAYERS_TO_RUN_CSV" != *"ml0"* ]] && continue ;;
      "currency-l1")  [[ "$LAYERS_TO_RUN_CSV" != *"cl1"* ]] && continue ;;
      "data-l1")      [[ "$LAYERS_TO_RUN_CSV" != *"dl1"* ]] && continue ;;
    esac

    pid_file="/app/$service/app.pid"

    if [ -f "$pid_file" ]; then
      pid=$(cat "$pid_file")

      if ! kill -0 "$pid" 2>/dev/null; then
        echo "Process for $service (PID $pid) died, restarting..."
        case $service in
          "metagraph-l0") start_metagraph_l0_service ;;
          "currency-l1")  start_currency_l1_service ;;
          "data-l1")      start_data_l1_service ;;
        esac
        continue
      fi

      case $service in
        "metagraph-l0") port=$METAGRAPH_L0_PUBLIC_PORT ;;
        "currency-l1")  port=$CURRENCY_L1_PUBLIC_PORT ;;
        "data-l1")      port=$DATA_L1_PUBLIC_PORT ;;
      esac

      if ! health_check "$service" "$port"; then
        echo "Health check failed for $service, restarting..."
        kill -9 "$pid" 2>/dev/null
        case $service in
          "metagraph-l0") start_metagraph_l0_service ;;
          "currency-l1")  start_currency_l1_service ;;
          "data-l1")      start_data_l1_service ;;
        esac
      fi
    else
      echo "PID file for $service not found"
    fi
  done
  sleep 30
done