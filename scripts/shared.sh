#!/bin/bash

get_random_source_node() {
  local layer=$1  # Expecting: ML0, CL1, DL1

  local index=$((RANDOM % 3))

  local peer_id_var="SOURCE_NODE_$((index + 1))_PEER_ID"
  local ip_var="SOURCE_NODE_$((index + 1))_IP"
  local p2p_port_var="SOURCE_NODE_$((index + 1))_${layer}_P2P_PORT"
  local public_port_var="SOURCE_NODE_$((index + 1))_${layer}_PUBLIC_PORT"

  local peer_id="${!peer_id_var}"
  local ip="${!ip_var}"
  local p2p_port="${!p2p_port_var}"
  local public_port_var="${!public_port_var}"

  echo "$peer_id;$ip;$p2p_port;$public_port_var"
}

check_if_node_is_ready_to_join() {
  local service_name=$1
  local port=$2

  echo "Waiting for $service_name to become ReadyToJoin..."

  for i in {1..60}; do
    response=$(curl -s -o /tmp/health.json -w "%{http_code}" "http://localhost:$port/node/info")

    if [ "$response" = "200" ]; then
      state=$(jq -r '.state' /tmp/health.json 2>/dev/null)
      if [ -n "$state" ]; then
        echo "[$service_name] Attempt $i: Current state is \"$state\""
        if [ "$state" = "ReadyToJoin" ]; then
          echo "$service_name is ReadyToJoin"
          return 0
        fi
      else
        echo "[$service_name] Attempt $i: State not found in response"
      fi
    else
      echo "[$service_name] Attempt $i: Health check returned HTTP $response"
    fi

    sleep 1
  done

  echo "$service_name is not ReadyToJoin after 60 seconds"
  return 1
}

join_node_to_cluster() {
  local service_name=$1
  local cli_port=$2
  local node_id=$3
  local node_ip=$4
  local node_p2p_port=$5

  echo "Joining $service_name to cluster on $node_ip:$node_p2p_port..."
  curl -s -X POST http://localhost:$cli_port/cluster/join \
    -H "Content-type: application/json" \
    -d "{\"id\":\"$node_id\", \"ip\": \"$node_ip\", \"p2pPort\": $node_p2p_port}"
}

check_and_download_seedlist() {
  local service_name=$1
  local seedlist_url=$2
  local seedlist_name=$3

  local seedlist_path="/app/$service_name/$seedlist_name"

  if [ -n "$seedlist_url" ] && [ -n "$seedlist_name" ]; then
    echo "Downloading seedlist from $seedlist_url to $seedlist_path"
    wget -q "$seedlist_url" -O "$seedlist_path"

    if [ $? -ne 0 ]; then
      echo "Failed to download seedlist from $seedlist_url"
      exit 1
    fi

    echo "Seedlist downloaded successfully."

    if [ -f "$seedlist_path" ]; then
      export SEEDLIST_ARG="--seedlist $seedlist_path"
    fi
  fi
}

check_and_download_allowance_list() {
  local service_name=$1
  local allowance_list_url=$2
  local allowance_list_name=$3

  local allowance_list_path="/app/$service_name/$allowance_list_name"

  if [ -n "$allowance_list_url" ] && [ -n "$allowance_list_name" ]; then
    echo "Downloading allowance list from $allowance_list_url to $allowance_list_path"
    wget -q "$allowance_list_url" -O "$allowance_list_path"

    if [ $? -ne 0 ]; then
      echo "Failed to download allowance list from $allowance_list_url"
      exit 1
    fi

    echo "Allowance list downloaded successfully."

    if [ -f "$allowance_list_path" ]; then
      export ALLOWANCE_LIST_ARG="--allowanceList $allowance_list_path"
    fi
  fi
}