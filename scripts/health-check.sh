#!/bin/bash

# Health check function with retries
health_check() {
  local service_name=$1
  local port=$2
  local attempts=5
  local wait=2

for i in $(seq 1 $attempts); do
  response=$(curl -s -o /tmp/health.json -w "%{http_code}" http://localhost:$port/node/info)
  if [ "$response" = "200" ]; then
    state=$(jq -r '.state' /tmp/health.json 2>/dev/null)
    
    # Check for immediately unhealthy states
    if [ "$state" = "SessionStarted" ] || [ "$state" = "ReadyToJoin" ] || [ "$state" = "WaitingForDownload" ]; then
      echo "$service_name is unhealthy. State: $state"
      return 1
    fi

    # Handle Observing state with 5-minute timeout
    if [ "$state" = "Observing" ]; then
      current_time=$(date +%s)
      
      # Check if we have a stored timestamp for this service
      timestamp_file="/tmp/${service_name}_observing_start"
      
      if [ -f "$timestamp_file" ]; then
        # Read existing timestamp
        start_time=$(cat "$timestamp_file")
        time_diff=$((current_time - start_time))
        
        # Check if 5 minutes (300 seconds) have passed
        if [ $time_diff -ge 300 ]; then
          echo "$service_name has been in Observing state for more than 5 minutes. State: $state"
          rm -f "$timestamp_file"  # Clean up timestamp file
          return 1
        else
          remaining_time=$((300 - time_diff))
          echo "$service_name is in Observing state for ${time_diff}s (${remaining_time}s remaining before timeout). State: $state"
          sleep $wait
          continue
        fi
      else
        # First time seeing Observing state, record timestamp
        echo "$current_time" > "$timestamp_file"
        echo "$service_name entered Observing state. Starting 5-minute timeout. State: $state"
        sleep $wait
        continue
      fi
    else
      # Not in Observing state, clean up any existing timestamp file
      timestamp_file="/tmp/${service_name}_observing_start"
      [ -f "$timestamp_file" ] && rm -f "$timestamp_file"
    fi

    echo "$service_name on port $port is healthy. State: $state"

    if [ "$service_name" = "metagraph-l0" ] && [ "$state" = "Ready" ]; then
      current_ordinal=$(curl -s http://localhost:$port/snapshots/latest | jq -r '.value.ordinal')
      ordinal_to_check_hashes=$((current_ordinal - 1))

      if [ -z "$ordinal_to_check_hashes" ] || [ "$ordinal_to_check_hashes" = "null" ]; then
        echo "Failed to retrieve snapshot ordinal."
        return 1
      fi

      echo "Ordinal to check hashes: $ordinal_to_check_hashes"

      node_ordinal_hash=$(curl -s http://localhost:$port/snapshots/$ordinal_to_check_hashes/hash)
      source_node_ordinal_hash=$(curl -s http://$SOURCE_NODE_1_IP:$SOURCE_NODE_1_ML0_PUBLIC_PORT/snapshots/$ordinal_to_check_hashes/hash)

      echo "Comparing snapshot hashes for ordinal $ordinal_to_check_hashes:"
      echo "  Local : $node_ordinal_hash"
      echo "  Source: $source_node_ordinal_hash"

      if [ "$node_ordinal_hash" != "$source_node_ordinal_hash" ]; then
        echo "Hash mismatch detected. Restarting $service_name..."
        return 1
      fi
    fi

    return 0  # all checks passed
  else
    echo "$service_name on port $port not healthy (HTTP $response), attempt $i/$attempts"
    sleep $wait
  fi
done

  return 1  # never succeeded
}
