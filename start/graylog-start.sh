#!/bin/bash
# start/restart graylog server

APP=graylog

chmod -R 777 /etc/graylog

# Do not print password_secret or password
set +x
#Set password_secret
sed -i -e 's/password_secret =.*/password_secret = '$PASS_SECRET'/' /etc/graylog/server/server.conf

#Set password
PASSWORD_HASH=$(echo -n "$PASSWORD" | sha256sum | awk '{print $1}')
sed -i -e 's/root_password_sha2 =.*/root_password_sha2 = '$PASSWORD_HASH'/' /etc/graylog/server/server.conf
set -x

#Set index prefix
sed -i -e 's/elasticsearch_index_prefix =.*/elasticsearch_index_prefix = pegselasticsearch'$ENV'/' /etc/graylog/server/server.conf

#Set elasticsearch cluster
sed -i -e 's/elasticsearch_cluster_name =.*/elasticsearch_cluster_name = pegselasticsearch'$ENV'/' /etc/graylog/server/server.conf

#Set timezone
sed -i -e 's/#root_timezone =.*/root_timezone = America\/Phoenix/' /etc/graylog/server/server.conf

#Set shards
sed -i -e 's/elasticsearch_shards =.*/elasticsearch_shards = 5/' /etc/graylog/server/server.conf

#Set replicas
sed -i -e 's/elasticsearch_replicas =.*/elasticsearch_replicas = 1/' /etc/graylog/server/server.conf

#Set nginx password
htpasswd -b -c /etc/nginx/.htpasswd admin $PASSWORD
unset PASSWORD

sysctl -w net.core.rmem_max=1048576

DEFAULT_ELASTIC_SEARCH_PORT=${1:-9300}

# get elastic search node ips
curl -o get-servers.sh  https://s3-us-west-2.amazonaws.com/graylog-config/get-servers.sh
chmod 777 get-servers.sh
ELASTIC_NODES=(`./get-servers.sh $STACK_NAME-$ENV-elastic-search`)

# build string for elastic search connections
for ID in "${ELASTIC_NODES[@]}"
do 
	IP=$(aws ec2 describe-instances --instance-id $ID | \
	grep PrivateIpAddress | sed -e "s/[ ,PrivateIpAddress\:\[\"]//g" | \
	uniq -u | \
	sed '/^$/d')
	ELASTIC_SEARCH_CONF=$ELASTIC_SEARCH_CONF"$IP:$DEFAULT_ELASTIC_SEARCH_PORT,"
done

CONF1=`echo elasticsearch_discovery_zen_ping_unicast_hosts =  $ELASTIC_SEARCH_CONF | sed 's/,$//'`
CONF2=`echo discovery.zen.ping.unicast.hosts: [$ELASTIC_SEARCH_CONF | sed "s/,$/\]/"`

# get mongo nodes
MONGO_CONF=""
MONGO_NODES=(`./get-servers.sh $STACK_NAME-$ENV-mongo`)
for ID in "${MONGO_NODES[@]}"
do 
	IP=$(aws ec2 describe-instances --instance-id $ID | \
	grep PrivateIpAddress | sed -e "s/[ ,PrivateIpAddress\:\[\"]//g" | \
	uniq -u | \
	sed '/^$/d')
    MONGO_CONF=$MONGO_CONF"$IP,"
done

MONGO_CONF=`echo mongodb_uri = mongodb://$MONGO_CONF | sed "s/,$/\/graylog2/"`

if [ -z "${CONF1}" ]
then
    echo "missing required elastic search parameter $1"
    exit
fi

if [ -z "${CONF2}" ]
then
    echo "missing required elastic search parameter $2"
    exit
fi

if [ -z "${MONGO_CONF}" ]
then
    echo "missing required mongo db parameter $3"
    exit
fi

echo $CONF1 >> /etc/graylog/server/server.conf
echo $CONF2 >> /etc/graylog/server/server.conf
echo $MONGO_CONF >> /etc/graylog/server/server.conf

systemctl restart graylog-server
systemctl restart nginx
