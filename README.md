# Validator Node Docker Environment

This repository provides a modular and extensible Docker-based environment for running validator nodes in a metagraph-based network. It supports multiple services, including:

- `metagraph-l0`
- `currency-l1`
- `data-l1`

Each component is packaged as a JAR, configured via environment variables, and managed with modular scripts for startup, health checking, and auto-recovery.

---

## 🧪 Features

- Service modularity: scripts per layer
- Snapshot hash consistency verification (for `metagraph-l0`)
- Integrated health checks with retries
- Automatic restart on process failure or unhealthy state
- Optional dynamic seedlist download support
- Environment-configured for testnet/mainnet flexibility

---

## 🚀 Getting Started

### 1. Configure Environment Variables

Create a `.env` file in the root directory with necessary ports, credentials, node info, and optional seedlist settings:

```env
NODE_IP=0.0.0.0
ENVIRONMENT=testnet

# Example port config
METAGRAPH_L0_PUBLIC_PORT=9100
CURRENCY_L1_PUBLIC_PORT=9200
DATA_L1_PUBLIC_PORT=9300

# Optional seedlist
METAGRAPH_L0_SEEDLIST_URL=https://example.com/seedlist.txt
METAGRAPH_L0_SEEDLIST_NAME=seedlist.txt

# Optional allowance list
METAGRAPH_L0_ALLOWANCE_LIST_URL=https://example.com/allowance_list.txt
METAGRAPH_L0_ALLOWANCE_LIST_NAME=allowance_list.txt

# Peer IDs, keystore config, etc.
```
## ⚙️ Getting Started

### Option 1: Quick Setup (Recommended)
Run the interactive setup wizard to configure your environment:

```bash
chmod +x setup.sh
./setup.sh
```
The setup wizard will guide you through:

* Environment selection (testnet/integrationnet/mainnet)
* Network configuration (IP addresses, ports)
* Credential setup (peer IDs, keystore configuration)
* Optional features (seedlist, allowance list)
* Automatic `.env` file generation

### Option 2: Manual Configuration
If you prefer manual setup, create a `.env` file in the root directory with necessary ports, credentials, node info, and optional seedlist settings:
```bash
NODE_IP=0.0.0.0
ENVIRONMENT=testnet

# Example port config
METAGRAPH_L0_PUBLIC_PORT=9100
CURRENCY_L1_PUBLIC_PORT=9200
DATA_L1_PUBLIC_PORT=9300

# Optional seedlist
METAGRAPH_L0_SEEDLIST_URL=https://example.com/seedlist.txt
METAGRAPH_L0_SEEDLIST_NAME=seedlist.txt

# Optional allowance list
METAGRAPH_L0_ALLOWANCE_LIST_URL=https://example.com/allowance_list.txt
METAGRAPH_L0_ALLOWANCE_LIST_NAME=allowance_list.txt

# Peer IDs, keystore config, etc.
...
```

## 🚀 Build and Start
Use Docker Compose to build and run the services:

```bash
docker-compose down && docker-compose pull && docker-compose up -d && docker-compose logs -f
```

## 📋 Monitoring

To manually check logs for a specific service:
```bash
docker exec -it pacaswap-node tail -f /app/metagraph-l0/logs/app.log
```
Replace metagraph-l0 with the service you want to monitor.

## 🔁 Health & Recovery

Each service is:
* Periodically health-checked via HTTP
* Restarted automatically if the process dies
* Restarted if the node is stuck in an unhealthy state (WaitingForDownload, SessionStarted, etc.)
* For metagraph-l0, the snapshot hash is validated against a known source

## 🛠️ Setup Wizard
The `setup.sh` script provides an interactive configuration experience that:

* Prompts for environment-specific settings
* Uses pre-configured templates for some metagraphs
* Generates optimized `.env` configuration
* Provides helpful tips
* Validates configuration before deployment

Available Templates
The setup wizard includes pre-configured templates for various metagraph networks:
```
shared-data/
├── pacaswap_testnet.env
├── [metagraph]_testnet.env
└── [metagraph]_mainnet.env
```

These templates contain:
* Port configurations
* Network-specific endpoints
* Recommended settings for each environment

## 🔧 Configuration Management
After running the setup wizard, you can:

* View current configuration: `cat .env`
* Edit configuration manually: `nano .env`