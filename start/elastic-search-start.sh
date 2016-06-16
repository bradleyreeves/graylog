#!/bin/bash
# start/restart elasticsearch

APP=elastic-search

# echo all commands
set -x

# allowed to lock memory
ulimit -u unlimited
ulimit -l unlimited

sysctl -w net.core.rmem_max=8388608

sed -i -e 's/cluster.name:.*/cluster.name: pegselasticsearch'$ENV'/' /etc/elasticsearch/elasticsearch.yml
# start services
systemctl enable elasticsearch.service
chkconfig elasticsearch on

service elasticsearch start
