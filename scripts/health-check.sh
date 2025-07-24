#!/bin/bash

# Early version check before any retries
version_check() {
  local service_name=$1
  local port=$2

  node_info=$(curl -s http://localhost:$port/metagraph/info)
  response_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/metagraph/info)

  if [ "$response_code" != "200" ]; then
    echo "$service_name: Unable to perform version check (HTTP $response_code)"
    exit 1
  fi

  local_metagraph_version=$(echo "$node_info" | jq -r '.metagraphVersion' 2>/dev/null)
  source_metagraph_version=$(curl -s http://$SOURCE_NODE_1_IP:$SOURCE_NODE_1_ML0_PUBLIC_PORT/metagraph/info | jq -r '.metagraphVersion' 2>/dev/null)

  if [ -z "$local_metagraph_version" ] || [ "$local_metagraph_version" = "null" ] || \
     [ -z "$source_metagraph_version" ] || [ "$source_metagraph_version" = "null" ]; then
    echo "$service_name version check failed - unable to retrieve metagraph versions"
    echo "Container startup failed - exiting..."
    exit 1
  fi

  if [ "$local_metagraph_version" != "$source_metagraph_version" ]; then
    echo "$service_name version mismatch:"
    echo "  Local version : $local_metagraph_version"
    echo "  Source version: $source_metagraph_version"
    echo "Please update your node running: docker-compose down && docker-compose pull && docker-compose up -d"
    echo "Container startup failed - leaving cluster and exiting..."
    curl -s -X POST http://localhost:$cli_port/cluster/leave
    
    exit 1
  fi

  echo "$service_name version check passed. Version: $local_metagraph_version"
}


health_check() {
  local service_name=$1
  local port=$2
  local attempts=5
  local wait=2

  for i in $(seq 1 $attempts); do
    node_info=$(curl -s http://localhost:$port/metagraph/info)
    response_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/metagraph/info)

    if [ "$response_code" = "200" ]; then    
      state=$(echo "$node_info" | jq -r '.state' 2>/dev/null)
      
      # Check for immediately unhealthy states
      if [ "$state" = "SessionStarted" ] || [ "$state" = "ReadyToJoin" ] || [ "$state" = "WaitingForDownload" ]; then
        echo "$service_name is unhealthy. State: $state"
        echo "Container startup failed - exiting..."
        exit 1
      fi

      # Handle Observing state with 5-minute timeout
      if [ "$state" = "Observing" ]; then
        current_time=$(date +%s)

        # Check if we have a stored timestamp for this service (using environment variable)        
        sanitized_service_name=$(echo "$service_name" | tr '-' '_')
        timestamp_var="${sanitized_service_name}_observing_start"
                
        # Get timestamp from environment or set to current time
        if [ -n "${!timestamp_var}" ]; then
          # Use existing timestamp
          start_time=${!timestamp_var}
          time_diff=$((current_time - start_time))
          
          # Check if 5 minutes (300 seconds) have passed
          if [ $time_diff -ge 300 ]; then
            echo "$service_name has been in Observing state for more than 5 minutes. State: $state"
            echo "Container startup failed - exiting..."
            exit 1
          else
            remaining_time=$((300 - time_diff))
            echo "$service_name is in Observing state for ${time_diff}s (${remaining_time}s remaining before timeout). State: $state"
            # Return healthy - Observing state is valid within timeout
            return 0
          fi
        else
          # First time seeing Observing state, set timestamp in environment
          export ${timestamp_var}=$current_time
          echo "$service_name entered Observing state. Starting 5-minute timeout. State: $state"
          # Return healthy - just entered Observing state
          return 0
        fi
      else
        # Not in Observing state, clear any existing timestamp
        timestamp_var="${service_name}_observing_start"
        unset $timestamp_var
      fi

      echo "$service_name on port $port is healthy. State: $state"

      if [ "$service_name" = "metagraph-l0" ] && [ "$state" = "Ready" ]; then
        source_info=$(get_random_source_node "ML0")
        peer_id=$(echo "$source_info" | cut -d';' -f1)
        ip=$(echo "$source_info" | cut -d';' -f2)
        public_port=$(echo "$source_info" | cut -d';' -f4)

        current_ordinal=$(curl -s http://$ip:$public_port/snapshots/latest | jq -r '.value.ordinal')
        ordinal_to_check_hashes=$((current_ordinal - 1))

        if [ -z "$ordinal_to_check_hashes" ] || [ "$ordinal_to_check_hashes" = "null" ]; then
          echo "Failed to retrieve snapshot ordinal."
          echo "Container startup failed - exiting..."
          exit 1
        fi

        echo "Ordinal to check hashes: $ordinal_to_check_hashes"

        node_ordinal_hash=$(curl -s http://localhost:$port/snapshots/$ordinal_to_check_hashes/hash)
        source_node_ordinal_hash=$(curl -s http://$ip:$public_port/snapshots/$ordinal_to_check_hashes/hash)

        echo "Comparing snapshot hashes for ordinal $ordinal_to_check_hashes:"
        echo "  Local : $node_ordinal_hash"
        echo "  Source($ip): $source_node_ordinal_hash"

        if [ "$node_ordinal_hash" != "$source_node_ordinal_hash" ]; then
          echo "Hash mismatch detected. Container startup failed - exiting..."
          exit 1
        fi
      fi

      return 0  # all checks passed
    else
      echo "$service_name on port $port not healthy (HTTP $response_code), attempt $i/$attempts"
      sleep $wait
    fi
  done

  echo "Health check failed for $service_name after $attempts attempts. Container startup failed - exiting..."
  exit 1
}