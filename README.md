# Elastic search install script

 - open `setup.sh` and configure the details in CONFIG section.
 - take special care of `ELASTIC_SEED_NODES` config.
 - value of `ELASTIC_NODE_NAME` will be different for each node in the cluster.
 - it assumes that you have already generated SSL certs. If not look into ssl directory of repo on how to generate self signed certs.

## Extra instructions
 - `start-elastic-first-time-createcluster.sh` is used only for very first time.
 - `password-generator-first-time.sh` use on any node to generate default user and passwords for first time.
