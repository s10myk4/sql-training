SHELL:=/bin/bash
DC_CMD := docker-compose exec
ZOOKEEPER_PORT := 2181
KAFKA_CONTAINER_NAME := kafka
KAFKA_PORT := 9092
KAFKA_BIN_DIR := /opt/kafka/bin
MYSQL_CMD := /usr/bin/mysql -usql-demo -pdemo-sql -Dsql-demo

args = `arg="$(filter-out $@,$(MAKECMDGOALS))" && echo $${arg:-${1}}`

.DEFAULT_GOAL := help
.PHONY: help up ps build exec down-all

help:
	@grep -E '^[a-zA-Z/_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##"}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

up: ## docker-compose up [TARGET_NAME]
	@docker-compose up -d $(call args, )

ps: ## docker-compose ps
	@docker-compose ps

build: ## docker-compose build
	docker-compose build

exec: ## exec [HOSTNAME] //docker-compose exec [HOSTNAME] /bin/bash
	@docker-compose exec $(call args, ) /bin/bash

down-all: ## docker-compose down -v
	@docker-compose down -v

.PHONY: kafka/topic-list kafka/topic-describe kafka/topic-create kafka/topic-delete kafka/read kafka/write

#refs: https://kafka.apache.org/quickstart
kafka/topic-list: ## list kafka topics
	@$(DC_CMD) $(KAFKA_CONTAINER_NAME) $(KAFKA_BIN_DIR)/kafka-topics.sh --list --zookeeper zookeeper:$(ZOOKEEPER_PORT)

kafka/topic-describe: ## kafka/topic-describe TOPIC=[TOPIC_NAME]
	@$(DC_CMD) $(KAFKA_CONTAINER_NAME) $(KAFKA_BIN_DIR)/kafka-topics.sh --describe --zookeeper zookeeper:$(ZOOKEEPER_PORT) --topic $(call args, )

kafka/topic-create: ## kafka/topic-create [TOPIC_NAME]
	$(DC_CMD) $(KAFKA_CONTAINER_NAME) $(KAFKA_BIN_DIR)/kafka-topics.sh --create --zookeeper zookeeper:$(ZOOKEEPER_PORT) --topic $(call args, ) --partitions 1 --replication-factor 1

kafka/topic-delete: ## kafka/topic-delete [TOPIC_NAME]
	$(DC_CMD) $(KAFKA_CONTAINER_NAME) $(KAFKA_BIN_DIR)/kafka-topics.sh --delete --zookeeper zookeeper:$(ZOOKEEPER_PORT) --topic $(call args, )

kafka/read: ## kafka/read [TOPIC_NAME] //read events from specified topic
	@$(DC_CMD) $(KAFKA_CONTAINER_NAME) $(KAFKA_BIN_DIR)/kafka-console-consumer.sh --topic $(call args, ) --from-beginning --bootstrap-server $(KAFKA_CONTAINER_NAME):$(KAFKA_PORT)

kafka/write: ## kafka/write [TOPIC_NAME]
	$(DC_CMD) $(KAFKA_CONTAINER_NAME) $(KAFKA_BIN_DIR)/kafka-console-producer.sh --topic $(call args, ) --broker-list $(KAFKA_CONTAINER_NAME):$(KAFKA_PORT)

.PHONY: mysql/prompt mysql/show-tables

mysql/show-tables: ## show db tables
	@$(DC_CMD) mysql $(MYSQL_CMD) -e 'show tables'

mysql/prompt: ## start mysql prompt
	@$(DC_CMD) mysql $(MYSQL_CMD)


.PHONY: flink/job-list flink/sql-cli

flink/job-list: ## job list
	@$(DC_CMD) jobmanager flink list

flink/sql-cli: ## sql-cli
	@$(DC_CMD) sql-client ./sql-client.sh

.PHONY: zookeeper/broker-list

zookeeper/broker-list: ## broker list
	$(DC_CMD) zookeeper ./bin/zkCli.sh localhost:$(ZOOKEEPER_PORT) ls /brokers/ids
