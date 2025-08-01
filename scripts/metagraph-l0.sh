#!/bin/bash

source /app/scripts/shared.sh

start_metagraph_l0_service() {
  export CL_KEYSTORE=$METAGRAPH_L0_CL_KEYSTORE
  export CL_KEYALIAS=$METAGRAPH_L0_CL_KEYALIAS
  export CL_PASSWORD=$METAGRAPH_L0_CL_PASSWORD

  export CL_PUBLIC_HTTP_PORT=$METAGRAPH_L0_PUBLIC_PORT
  export CL_P2P_HTTP_PORT=$METAGRAPH_L0_P2P_PORT
  export CL_CLI_HTTP_PORT=$METAGRAPH_L0_CLI_PORT

  export CL_GLOBAL_L0_PEER_HTTP_HOST=$GL0_NODE_IP
  export CL_GLOBAL_L0_PEER_HTTP_PORT=$GL0_NODE_PORT
  export CL_GLOBAL_L0_PEER_ID=$GL0_NODE_ID

  export CL_L0_TOKEN_IDENTIFIER=$METAGRAPH_ID
  export CL_APP_ENV=$ENVIRONMENT

  export CL_SNAPSHOT_STORED_PATH=/app/shared-data/metagraph-l0/data/snapshot
  export CL_INCREMENTAL_SNAPSHOT_TMP_STORED_PATH=/app/shared-data/metagraph-l0/data/incremental_snapshot_tmp
  export CL_INCREMENTAL_SNAPSHOT_STORED_PATH=/app/shared-data/metagraph-l0/data/incremental_snapshot
  export CL_SNAPSHOT_INFO_PATH=/app/shared-data/metagraph-l0/data/snapshot_info
  export CL_CALCULATED_STATE_PATH=/app/shared-data/metagraph-l0/data/calculated_state

  check_and_download_seedlist "metagraph-l0" "$METAGRAPH_L0_SEEDLIST_URL" "$METAGRAPH_L0_SEEDLIST_NAME"
  check_and_download_allowance_list "metagraph-l0" "$METAGRAPH_L0_ALLOWANCE_LIST_URL" "$METAGRAPH_L0_ALLOWANCE_LIST_NAME"

  echo "Starting metagraph-l0 on port $METAGRAPH_L0_PUBLIC_PORT..."
  cd /app/metagraph-l0

  java -jar metagraph-l0.jar run-validator --ip $NODE_IP $SEEDLIST_ARG $ALLOWANCE_LIST_ARG > /app/metagraph-l0/app.log 2>&1 &
  echo $! > /app/metagraph-l0/app.pid

  source_info=$(get_random_source_node "ML0")
  peer_id=$(echo "$source_info" | cut -d';' -f1)
  ip=$(echo "$source_info" | cut -d';' -f2)
  p2p_port=$(echo "$source_info" | cut -d';' -f3)

  check_if_node_is_ready_to_join "metagraph-l0" $METAGRAPH_L0_PUBLIC_PORT
  
  echo "Joining using random ML0 source node: $ip:$p2p_port ($peer_id)"
  join_node_to_cluster "metagraph-l0" "$METAGRAPH_L0_CLI_PORT" "$peer_id" "$ip" "$p2p_port"
}
