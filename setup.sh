#!/bin/bash

#################################### CONFIG SECTION ############################
# DIRECTORY CONFIG
BASE_DIR=/home/ec2-user/elastic
SETUP_DIR=$BASE_DIR/setup
SOFTWARE_DIR=$BASE_DIR/software
SCRIPT_DIR=$BASE_DIR/scripts
ELASTIC_CONFIG_DIR=$BASE_DIR/scripts/elastic/config
ELASTIC_LOGS_DIR=$BASE_DIR/scripts/elastic/logs
ELASTIC_DATA_DIR=$BASE_DIR/scripts/elastic/data

# ELASTIC CONFIG
ELASTIC_PORT=9200
ELASTIC_CLUSTER_NAME=elastic-cluster-test
# name of this node, defaults to hostname, but you can change. THIS IS DIFFERENT FOR EVERY NODE
ELASTIC_NODE_NAME=node-1
# ip address of this node, it will bind to the address. THIS IS DIFFERENT FOR EVERY NODE
ELASTIC_NETWORK_HOST=0.0.0.0
# ip address of all initial nodes to discover and create cluster
ELASTIC_SEED_NODES='["18.224.171.155:9300","18.216.204.35:9300","18.222.131.254:9300"]'
ELASTIC_MASTER_NODES='node-1,node-2,node-3'
# used for password generation of default users
ELASTIC_ADDRESS_ANY_NODE=18.224.171.155:9200

# SSL CONFIG
ELASTIC_NODE_CA_CERT=/home/ec2-user/elastic/certs/ca/ca.crt
ELASTIC_NODE_CERT=/home/ec2-user/elastic/certs/node-1/node-1.crt
ELASTIC_NODE_PK=/home/ec2-user/elastic/certs/node-1/node-1.key

#################################### CONFIG SECTION ENDS ############################

# DO NOT TOUCH
dqt='"'
mkdir -p $SETUP_DIR
mkdir -p $SOFTWARE_DIR
mkdir -p $SCRIPT_DIR
mkdir -p $ELASTIC_CONFIG_DIR
mkdir -p $ELASTIC_LOGS_DIR
mkdir -p $ELASTIC_DATA_DIR
mkdir -p $ELASTIC_CONFIG_DIR/certs


echo "downloading elasticsearch"
wget --directory-prefix=$SETUP_DIR https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.12.0-linux-x86_64.tar.gz
echo "Extracting elasticsearch"
tar xzf $SETUP_DIR/elasticsearch-7.12.0-linux-x86_64.tar.gz -C $SOFTWARE_DIR

echo "copying config directory"
cp -R $SOFTWARE_DIR/elasticsearch-7.12.0/config/* $ELASTIC_CONFIG_DIR/

echo "copying certs"
cp $ELASTIC_NODE_CA_CERT $ELASTIC_CONFIG_DIR/certs/ca.crt
cp $ELASTIC_NODE_CERT $ELASTIC_CONFIG_DIR/certs/node.crt
cp $ELASTIC_NODE_PK $ELASTIC_CONFIG_DIR/certs/node.key

echo "modifying elastic config"
echo "http.port: ${ELASTIC_PORT}" >> $ELASTIC_CONFIG_DIR/elasticsearch.yml
echo "path.data: ${ELASTIC_DATA_DIR}" >> $ELASTIC_CONFIG_DIR/elasticsearch.yml
echo "path.logs: ${ELASTIC_LOGS_DIR}" >> $ELASTIC_CONFIG_DIR/elasticsearch.yml
echo "cluster.name: ${ELASTIC_CLUSTER_NAME}" >> $ELASTIC_CONFIG_DIR/elasticsearch.yml
echo "node.name: ${ELASTIC_NODE_NAME}" >> $ELASTIC_CONFIG_DIR/elasticsearch.yml
echo "network.host: ${ELASTIC_NETWORK_HOST}" >> $ELASTIC_CONFIG_DIR/elasticsearch.yml
echo "discovery.seed_hosts: ${ELASTIC_SEED_NODES}" >> $ELASTIC_CONFIG_DIR/elasticsearch.yml

# SSL CONFIG
echo "xpack.security.enabled: true" >> $ELASTIC_CONFIG_DIR/elasticsearch.yml
echo "xpack.security.http.ssl.enabled: true" >> $ELASTIC_CONFIG_DIR/elasticsearch.yml
echo "xpack.security.transport.ssl.verification_mode: certificate" >> $ELASTIC_CONFIG_DIR/elasticsearch.yml
echo "xpack.security.transport.ssl.enabled: true" >> $ELASTIC_CONFIG_DIR/elasticsearch.yml
echo "xpack.security.http.ssl.key: certs/node.key" >> $ELASTIC_CONFIG_DIR/elasticsearch.yml
echo "xpack.security.http.ssl.certificate: certs/node.crt" >> $ELASTIC_CONFIG_DIR/elasticsearch.yml
echo "xpack.security.http.ssl.certificate_authorities: certs/ca.crt" >> $ELASTIC_CONFIG_DIR/elasticsearch.yml
echo "xpack.security.transport.ssl.key: certs/node.key" >> $ELASTIC_CONFIG_DIR/elasticsearch.yml
echo "xpack.security.transport.ssl.certificate: certs/node.crt" >> $ELASTIC_CONFIG_DIR/elasticsearch.yml
echo "xpack.security.transport.ssl.certificate_authorities: certs/ca.crt" >> $ELASTIC_CONFIG_DIR/elasticsearch.yml

echo "creating start-elastic.sh"
echo -n -e "#!/bin/bash
export ES_PATH_CONF=$ELASTIC_CONFIG_DIR
export JAVA_HOME=""
$SOFTWARE_DIR/elasticsearch-7.12.0/bin/elasticsearch -d -p $SCRIPT_DIR/elasticsearchpid" >> $SCRIPT_DIR/start-elastic.sh
chmod +x $SCRIPT_DIR/start-elastic.sh

echo "creating start-elastic-first-time-createcluster.sh"
echo -n -e "#!/bin/bash
export ES_PATH_CONF=$ELASTIC_CONFIG_DIR
export JAVA_HOME=""
$SOFTWARE_DIR/elasticsearch-7.12.0/bin/elasticsearch -d -p $SCRIPT_DIR/elasticsearchpid -Ecluster.initial_master_nodes=${ELASTIC_MASTER_NODES}" >> $SCRIPT_DIR/start-elastic-first-time-createcluster.sh
chmod +x $SCRIPT_DIR/start-elastic-first-time-createcluster.sh

echo "creating stop-elastic.sh"
echo -n -e "#!/bin/bash
pkill -F $SCRIPT_DIR/elasticsearchpid" >> $SCRIPT_DIR/stop-elastic.sh
chmod +x $SCRIPT_DIR/stop-elastic.sh

echo "creating password-generator.sh"
echo -n -e "#!/bin/bash
export ES_PATH_CONF=$ELASTIC_CONFIG_DIR
export JAVA_HOME=""
$SOFTWARE_DIR/elasticsearch-7.12.0/bin/elasticsearch-setup-passwords auto -u https://${ELASTIC_ADDRESS_ANY_NODE}" >> $SCRIPT_DIR/password-generator-first-time.sh
chmod +x $SCRIPT_DIR/password-generator-first-time.sh

echo "***************************************"
echo "STEP 1, execute this script very first time on all nodes at time of cluster bootstrap: $SCRIPT_DIR/start-elastic-first-time-createcluster.sh"
echo "STEP 2, wait for some time to bootstrap cluster and execute this to generate passwords: $SCRIPT_DIR/password-generator-first-time.sh"
echo "NOTE: DO NOT USE THIS SCRIPT AGAIN AFTER BOOTSTRAPPING THE CLUSTER. NOT EVEN WHEN WE NEED TO ADD MORE NODES. $SCRIPT_DIR/start-elastic.sh is the script to be used for subsequent starts"
echo "***************************************"
