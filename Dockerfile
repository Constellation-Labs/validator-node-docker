FROM eclipse-temurin:11-jre-jammy

RUN apt-get update && apt-get install -y \
    curl \
    jq \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app/metagraph-l0 \
             /app/currency-l1 \
             /app/data-l1 \
             /app/shared-data

COPY jars/metagraph-l0.jar /app/metagraph-l0/metagraph-l0.jar
COPY jars/currency-l1.jar /app/currency-l1/currency-l1.jar
COPY jars/data-l1.jar /app/data-l1/data-l1.jar

COPY scripts/ /app/scripts/
COPY scripts/start.sh /app/start.sh

RUN chmod +x /app/*/*.jar

VOLUME ["/app/shared-data"]

EXPOSE ${METAGRAPH_L0_PUBLIC_PORT} ${METAGRAPH_L0_P2P_PORT} ${METAGRAPH_L0_CLI_PORT} ${CURRENCY_L1_PUBLIC_PORT} ${CURRENCY_L1_P2P_PORT} ${CURRENCY_L1_CLI_PORT} ${DATA_L1_PUBLIC_PORT} ${DATA_L1_P2P_PORT} ${DATA_L1_CLI_PORT}

RUN chmod +x /app/start.sh

WORKDIR /app

CMD ["/app/start.sh"]
