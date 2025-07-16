#!/bin/bash

source /app/scripts/shared.sh

start_data_l1_service() {
  export CL_KEYSTORE=$DATA_L1_CL_KEYSTORE
  export CL_KEYALIAS=$DATA_L1_CL_KEYALIAS
  export CL_PASSWORD=$DATA_L1_CL_PASSWORD

  export CL_PUBLIC_HTTP_PORT=$DATA_L1_PUBLIC_PORT
  export CL_P2P_HTTP_PORT=$DATA_L1_P2P_PORT
  export CL_CLI_HTTP_PORT=$DATA_L1_CLI_PORT

  export CL_GLOBAL_L0_PEER_HTTP_HOST=$GL0_NODE_IP
  export CL_GLOBAL_L0_PEER_HTTP_PORT=$GL0_NODE_PORT
  export CL_GLOBAL_L0_PEER_ID=$GL0_NODE_ID

  export CL_L0_PEER_HTTP_HOST=$SOURCE_NODE_1_IP
  export CL_L0_PEER_HTTP_PORT=$SOURCE_NODE_1_ML0_PUBLIC_PORT
  export CL_L0_PEER_ID=$SOURCE_NODE_1_PEER_ID

  export CL_L0_TOKEN_IDENTIFIER=$METAGRAPH_ID
  export CL_APP_ENV=$ENVIRONMENT

  check_and_download_seedlist "data-l1" "$DATA_L1_SEEDLIST_URL" "$DATA_L1_SEEDLIST_NAME"
  check_and_download_allowance_list "data-l1" "$DATA_L1_ALLOWANCE_LIST_URL" "$DATA_L1_ALLOWANCE_LIST_NAME"

  echo "Starting data-l1 on port $DATA_L1_PUBLIC_PORT..."
  cd /app/data-l1

  java -jar data-l1.jar run-validator --ip $NODE_IP $SEEDLIST_ARG $ALLOWANCE_LIST_ARG > /app/data-l1/app.log 2>&1 &
  echo $! > /app/data-l1/app.pid

  source_info=$(get_random_source_node "DL1")
  peer_id=$(echo "$source_info" | cut -d';' -f1)
  ip=$(echo "$source_info" | cut -d';' -f2)
  p2p_port=$(echo "$source_info" | cut -d';' -f3)

  check_if_node_is_ready_to_join "data-l1" $DATA_L1_PUBLIC_PORT

  echo "Joining using random DL1 source node: $ip:$p2p_port ($peer_id)"
  join_node_to_cluster "data-l1" "$DATA_L1_CLI_PORT" "$peer_id" "$ip" "$p2p_port"
}
