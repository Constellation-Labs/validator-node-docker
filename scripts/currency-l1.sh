#!/bin/bash

source /app/scripts/shared.sh

start_currency_l1_service() {
  export CL_KEYSTORE=$CURRENCY_L1_CL_KEYSTORE
  export CL_KEYALIAS=$CURRENCY_L1_CL_KEYALIAS
  export CL_PASSWORD=$CURRENCY_L1_CL_PASSWORD

  export CL_PUBLIC_HTTP_PORT=$CURRENCY_L1_PUBLIC_PORT
  export CL_P2P_HTTP_PORT=$CURRENCY_L1_P2P_PORT
  export CL_CLI_HTTP_PORT=$CURRENCY_L1_CLI_PORT

  export CL_GLOBAL_L0_PEER_HTTP_HOST=$GL0_NODE_IP
  export CL_GLOBAL_L0_PEER_HTTP_PORT=$GL0_NODE_PORT
  export CL_GLOBAL_L0_PEER_ID=$GL0_NODE_ID

  export CL_L0_PEER_HTTP_HOST=$SOURCE_NODE_1_IP
  export CL_L0_PEER_HTTP_PORT=$SOURCE_NODE_1_ML0_PUBLIC_PORT
  export CL_L0_PEER_ID=$SOURCE_NODE_1_PEER_ID

  export CL_L0_TOKEN_IDENTIFIER=$METAGRAPH_ID
  export CL_APP_ENV=$ENVIRONMENT

  check_and_download_seedlist "currency-l1" "$CURRENCY_L1_SEEDLIST_URL" "$CURRENCY_L1_SEEDLIST_NAME"
  check_and_download_allowance_list "currency-l1" "$CURRENCY_L1_ALLOWANCE_LIST_URL" "$CURRENCY_L1_ALLOWANCE_LIST_NAME"

  echo "Starting currency-l1 on port $CURRENCY_L1_PUBLIC_PORT..."
  cd /app/currency-l1

  java -jar currency-l1.jar run-validator --ip $NODE_IP $SEEDLIST_ARG $ALLOWANCE_LIST_ARG > /app/currency-l1/app.log 2>&1 &
  echo $! > /app/currency-l1/app.pid

  check_if_node_is_ready_to_join "currency-l1" $CURRENCY_L1_PUBLIC_PORT
  join_node_to_cluster "currency-l1" $CURRENCY_L1_CLI_PORT $SOURCE_NODE_1_PEER_ID $SOURCE_NODE_1_IP $SOURCE_NODE_1_CL1_P2P_PORT
}