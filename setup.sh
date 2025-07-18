#!/bin/bash

echo "✨ Welcome to the Validator Node Setup Wizard ✨"
echo "🚀 This will generate your .env configuration file"
echo "-----------------------------------------------"
echo ""

ENV_FILE=".env"
> "$ENV_FILE"

prompt_default() {
  local var_name=$1
  local prompt=$2
  local default=$3
  read -p "$prompt [$default]: " value
  export $var_name="${value:-$default}"
  echo "$var_name=${!var_name}" >> "$ENV_FILE"
}

read -p "🌐 Enter your NODE_IP: " NODE_IP
echo "NODE_IP=$NODE_IP" >> "$ENV_FILE"

# Network selection with defaults
echo ""
echo "🌍 Available networks:"
echo "  1) testnet"
echo "  2) integrationnet"
echo "  3) mainnet"
echo ""
read -p "Select network (1-3) [1]: " network_choice
network_choice=${network_choice:-1}

case $network_choice in
  1)
    ENVIRONMENT="testnet"
    GL0_NODE_IP_DEFAULT="52.8.132.193"
    GL0_NODE_PORT_DEFAULT="9000"
    GL0_NODE_ID_DEFAULT="e2f4496e5872682d7a55aa06e507a58e96b5d48a5286bfdff7ed780fa464d9e789b2760ecd840f4cb3ee6e1c1d81b2ee844c88dbebf149b1084b7313eb680714"
    ;;
  2)
    ENVIRONMENT="integrationnet"
    GL0_NODE_IP_DEFAULT="13.52.205.240"
    GL0_NODE_PORT_DEFAULT="9000"
    GL0_NODE_ID_DEFAULT="e2f4496e5872682d7a55aa06e507a58e96b5d48a5286bfdff7ed780fa464d9e789b2760ecd840f4cb3ee6e1c1d81b2ee844c88dbebf149b1084b7313eb680714"
    ;;
  3)
    ENVIRONMENT="mainnet"
    GL0_NODE_IP_DEFAULT="52.53.46.33"
    GL0_NODE_PORT_DEFAULT="9000"
    GL0_NODE_ID_DEFAULT="e0c1ee6ec43510f0e16d2969a7a7c074a5c8cdb477c074fe9c32a9aad8cbc8ff1dff60bb81923e0db437d2686a9b65b86c403e6a21fa32b6acc4e61be4d70925"
    ;;
  *)
    echo "Invalid selection, defaulting to testnet"
    ENVIRONMENT="testnet"
    GL0_NODE_IP_DEFAULT="52.8.132.193"
    GL0_NODE_PORT_DEFAULT="9000"
    GL0_NODE_ID_DEFAULT="e2f4496e5872682d7a55aa06e507a58e96b5d48a5286bfdff7ed780fa464d9e789b2760ecd840f4cb3ee6e1c1d81b2ee844c88dbebf149b1084b7313eb680714"
    ;;
esac

echo "ENVIRONMENT=$ENVIRONMENT" >> "$ENV_FILE"

prompt_default GL0_NODE_IP "🛰️  GL0 Node IP" "$GL0_NODE_IP_DEFAULT"
prompt_default GL0_NODE_PORT "📡 GL0 Node Port" "$GL0_NODE_PORT_DEFAULT"
prompt_default GL0_NODE_ID "🆔 GL0 Node ID" "$GL0_NODE_ID_DEFAULT"

# Confirm network selection
echo ""
echo "🌍 Selected network: $ENVIRONMENT"
read -p "❓ Is this correct? (y/n) [y]: " confirm_network
confirm_network=${confirm_network:-y}

if [[ $confirm_network != "y" && $confirm_network != "Y" ]]; then
  echo "Please restart the script to select a different network."
  exit 1
fi

read -p "💠 Enter METAGRAPH_ID: " METAGRAPH_ID
echo "METAGRAPH_ID=$METAGRAPH_ID" >> "$ENV_FILE"

read -p "🏷️  Enter METAGRAPH_NAME (e.g., pacaswap): " METAGRAPH_NAME
echo "METAGRAPH_NAME=$METAGRAPH_NAME" >> "$ENV_FILE"

read -p "🧱 Layers to run (comma separated: ML0,CL1,DL1): " LAYERS_TO_RUN
echo "LAYERS_TO_RUN=$LAYERS_TO_RUN" >> "$ENV_FILE"

echo ""
echo "🌐 Source Node Configuration"
echo "Do you want to:"
echo "  1) Use default source nodes for $METAGRAPH_NAME on $ENVIRONMENT"
echo "  2) Configure custom source nodes"
echo ""
read -p "Select option (1-2) [1]: " source_choice
source_choice=${source_choice:-1}

if [[ $source_choice == "1" ]]; then
  # Try to load from metagraph-specific file first, then fallback to network defaults
  SOURCE_FILE="metagraph_source_nodes/${METAGRAPH_NAME}_${ENVIRONMENT}.env"
  
  if [[ -f "$SOURCE_FILE" ]]; then
    echo "🌐 Loading source node information from $SOURCE_FILE..."
    echo "" >> "$ENV_FILE"
    cat "$SOURCE_FILE" >> "$ENV_FILE"
  else
    echo "❌ Error: Source file $SOURCE_FILE not found!"
    echo "Please create the source node configuration file for $METAGRAPH_NAME on $ENVIRONMENT"
    echo "Expected file: $SOURCE_FILE"
    echo ""
    echo "The file should contain source node configuration in the format:"
    echo "SOURCE_NODE_1_IP=..."
    echo "SOURCE_NODE_1_ML0_PUBLIC_PORT=..."
    echo "SOURCE_NODE_1_PEER_ID=..."
    echo "etc."
    rm -f "$ENV_FILE"
    exit 1
  fi
else
  echo "🌐 Custom source node configuration..."
  echo ""
  
  read -p "📊 How many source nodes do you want to configure? [3]: " num_nodes
  num_nodes=${num_nodes:-3}
  
  for ((i=1; i<=num_nodes; i++)); do
    echo ""
    echo "🔧 Configuring source node $i..."
    
    read -p "🌐 Source Node $i IP: " node_ip
    echo "SOURCE_NODE_${i}_IP=$node_ip" >> "$ENV_FILE"
    
    prompt_default "SOURCE_NODE_${i}_ML0_PUBLIC_PORT" "📡 ML0 Public Port" "9100"
    prompt_default "SOURCE_NODE_${i}_ML0_P2P_PORT" "📡 ML0 P2P Port" "9101"
    prompt_default "SOURCE_NODE_${i}_CL1_PUBLIC_PORT" "📡 CL1 Public Port" "9200"
    prompt_default "SOURCE_NODE_${i}_CL1_P2P_PORT" "📡 CL1 P2P Port" "9201"
    prompt_default "SOURCE_NODE_${i}_DL1_PUBLIC_PORT" "📡 DL1 Public Port" "9300"
    prompt_default "SOURCE_NODE_${i}_DL1_P2P_PORT" "📡 DL1 P2P Port" "9301"
    
    read -p "🆔 Source Node $i Peer ID: " peer_id
    echo "SOURCE_NODE_${i}_PEER_ID=$peer_id" >> "$ENV_FILE"
    
    if [[ $i -lt $num_nodes ]]; then
      echo "" >> "$ENV_FILE"
    fi
  done
fi

echo "" >> "$ENV_FILE"

IFS=',' read -ra LAYERS <<< "$LAYERS_TO_RUN"

for LAYER in "${LAYERS[@]}"; do
  echo ""
  echo "🔧 Configuring layer: $LAYER"
  UPPER=$(echo "$LAYER" | tr '[:lower:]' '[:upper:]')

  case $UPPER in
    ML0)  PORT_PREFIX="METAGRAPH_L0"; SHARED_DIRECTORY=metagraph-l0 ;;
    CL1)  PORT_PREFIX="CURRENCY_L1"; SHARED_DIRECTORY=currency-l1 ;;
    DL1)  PORT_PREFIX="DATA_L1"; SHARED_DIRECTORY=data-l1 ;;
    *)    echo "⚠️  Unknown layer: $UPPER"; continue ;;
  esac

  read -p "🔐 Keystore name (e.g. node.p12): " KEYSTORE
  
  # Check if keystore file exists
  KEYSTORE_PATH="shared-data/$SHARED_DIRECTORY/$KEYSTORE"
  if [[ ! -f "$KEYSTORE_PATH" ]]; then
    echo "❌ Error: Keystore file not found!"
    echo "Expected file: $KEYSTORE_PATH"
    echo "Please ensure the keystore file exists in the correct directory."
    rm -f "$ENV_FILE"
    exit 1
  fi
  
  read -p "🔑 Key alias: " KEYALIAS
  read -p "🔑 Keystore password: " PASSWORD

  echo "${PORT_PREFIX}_CL_KEYSTORE=/app/shared-data/$SHARED_DIRECTORY/$KEYSTORE" >> "$ENV_FILE"
  echo "${PORT_PREFIX}_CL_KEYALIAS=$KEYALIAS" >> "$ENV_FILE"
  echo "${PORT_PREFIX}_CL_PASSWORD=$PASSWORD" >> "$ENV_FILE"

  echo "🌱 Seedlist config (optional):"
  read -p "🌍 Seedlist URL: " SEEDLIST_URL
  read -p "📄 Seedlist filename: " SEEDLIST_NAME

  if [[ -n "$SEEDLIST_URL" && -n "$SEEDLIST_NAME" ]]; then
    echo "${PORT_PREFIX}_SEEDLIST_URL=$SEEDLIST_URL" >> "$ENV_FILE"
    echo "${PORT_PREFIX}_SEEDLIST_NAME=$SEEDLIST_NAME" >> "$ENV_FILE"
  fi

  echo "📜 Allowance list config (optional):"
  read -p "🌍 Allowance list URL: " ALLOWANCE_LIST_URL
  read -p "📄 Allowance list filename: " ALLOWANCE_LIST_NAME

  if [[ -n "$ALLOWANCE_LIST_URL" && -n "$ALLOWANCE_LIST_NAME" ]]; then
    echo "${PORT_PREFIX}_ALLOWANCE_LIST_URL=$ALLOWANCE_LIST_URL" >> "$ENV_FILE"
    echo "${PORT_PREFIX}_ALLOWANCE_LIST_NAME=$ALLOWANCE_LIST_NAME" >> "$ENV_FILE"
  fi

  # Add default ports
  case $UPPER in
    ML0)
      echo "${PORT_PREFIX}_PUBLIC_PORT=9100" >> "$ENV_FILE"
      echo "${PORT_PREFIX}_P2P_PORT=9101" >> "$ENV_FILE"
      echo "${PORT_PREFIX}_CLI_PORT=9102" >> "$ENV_FILE"
      ;;
    CL1)
      echo "${PORT_PREFIX}_PUBLIC_PORT=9200" >> "$ENV_FILE"
      echo "${PORT_PREFIX}_P2P_PORT=9201" >> "$ENV_FILE"
      echo "${PORT_PREFIX}_CLI_PORT=9202" >> "$ENV_FILE"
      ;;
    DL1)
      echo "${PORT_PREFIX}_PUBLIC_PORT=9300" >> "$ENV_FILE"
      echo "${PORT_PREFIX}_P2P_PORT=9301" >> "$ENV_FILE"
      echo "${PORT_PREFIX}_CLI_PORT=9302" >> "$ENV_FILE"
      ;;
  esac

done

echo ""
echo "✅ All done! Your .env file has been saved."
echo "👉 You can now run your validator using Docker Compose!"
echo ""
echo "📋 Configuration summary:"
echo "  🌍 Environment: $ENVIRONMENT"
echo "  🏷️  Metagraph: $METAGRAPH_NAME"
echo "  🧱 Layers: $LAYERS_TO_RUN"
echo "  🌐 Source nodes: $(if [[ $source_choice == "1" ]]; then echo "Default"; else echo "Custom ($num_nodes nodes)"; fi)"