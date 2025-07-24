#!/bin/bash

source /app/scripts/health-check.sh
source /app/scripts/metagraph-l0.sh
source /app/scripts/currency-l1.sh
source /app/scripts/data-l1.sh

# Ensure shared data directory exists
mkdir -p "/app/shared-data"

# Normalize and prepare LAYERS_TO_RUN
LAYERS_TO_RUN_CSV=$(echo "$LAYERS_TO_RUN" | tr '[:upper:]' '[:lower:]')

# Function to restart a service
restart_service() {
  local service=$1
  local pid_file="/app/$service/app.pid"
  
  # Kill existing process if it exists
  if [ -f "$pid_file" ]; then
    pid=$(cat "$pid_file")
    kill -9 "$pid" 2>/dev/null
  fi
  
  # Start the service
  case $service in
    "metagraph-l0") start_metagraph_l0_service ;;
    "currency-l1")  start_currency_l1_service ;;
    "data-l1")      start_data_l1_service ;;
  esac
  
  echo "Service $service restarted"
}

# Conditionally start services
[[ "$LAYERS_TO_RUN_CSV" == *"ml0"* ]] && start_metagraph_l0_service
[[ "$LAYERS_TO_RUN_CSV" == *"cl1"* ]] && start_currency_l1_service
[[ "$LAYERS_TO_RUN_CSV" == *"dl1"* ]] && start_data_l1_service

echo "Waiting for services to start..."
sleep 30

# Conditionally check versions
[[ "$LAYERS_TO_RUN_CSV" == *"ml0"* ]] && version_check "metagraph-l0" "$METAGRAPH_L0_PUBLIC_PORT"
[[ "$LAYERS_TO_RUN_CSV" == *"cl1"* ]] && version_check "currency-l1" "$CURRENCY_L1_PUBLIC_PORT"
[[ "$LAYERS_TO_RUN_CSV" == *"dl1"* ]] && version_check "data-l1" "$DATA_L1_PUBLIC_PORT"

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

      # Check if process is running and healthy
      restart_needed=false
      restart_reason=""
      
      if ! kill -0 "$pid" 2>/dev/null; then
        restart_needed=true
        restart_reason="Process for $service (PID $pid) died"
      else
        # Determine port and perform health check
        case $service in
          "metagraph-l0") port=$METAGRAPH_L0_PUBLIC_PORT ;;
          "currency-l1")  port=$CURRENCY_L1_PUBLIC_PORT ;;
          "data-l1")      port=$DATA_L1_PUBLIC_PORT ;;
        esac

        if ! health_check "$service" "$port"; then
          restart_needed=true
          restart_reason="Health check failed for $service"
        fi
      fi
      
      # Restart if needed
      if [ "$restart_needed" = true ]; then
        echo "$restart_reason, restarting..."
        restart_service "$service"
      fi
    else
      echo "PID file for $service not found, starting service..."
      restart_service "$service"
    fi
  done
  
  # Wait 5 minutes before next check
  sleep 300
done