#!/bin/bash
# start/restart mongo

APP=mongo

# echo all commands
set -x

mkdir -p /var/lib/mongoconfig
mkdir -p /var/lib/mongoshard

CONFIG_PORT=27019
SHARD_PORT=27018
ROUTER_PORT=27017

# start server
nohup mongod --configsvr --replSet configReplSet --dbpath /var/lib/mongoconfig --bind_ip 0.0.0.0  &> /home/centos/mongoConfig.out&
nohup mongod --shardsvr --replSet shardReplSet --dbpath /var/lib/mongoshard --bind_ip 0.0.0.0  &> /home/centos/mongoShard.out&

curl -o  get-servers.sh  https://s3-us-west-2.amazonaws.com/graylog-config/get-servers.sh
chmod 777 get-servers.sh
MONGO_IDS=(`./get-servers.sh $STACK_NAME-$ENV-mongo`)
MONGO_IPS=()
for ID in "${MONGO_IDS[@]}"
do
	IP=$(aws ec2 describe-instances --instance-id $ID | \
	grep PrivateIpAddress | sed -e "s/[ ,PrivateIpAddress\:\[\"]//g" | \
	uniq -u | \
	sed '/^$/d')
	MONGO_IPS+=($IP)
done

# initiate config replica set
CONF="{ \
   _id: \"configReplSet\", \
   \"version\" : 1, \
   configsvr: true, \
   members: [ \
	  { _id: 0, host: \"${MONGO_IPS[0]}:$CONFIG_PORT\" }, \
	  { _id: 1, host: \"${MONGO_IPS[1]}:$CONFIG_PORT\" } \
   ] \
}"
# Try ten times or until status is ok
# Have seen loops up to 4 times before succeeding
# Graylog will remove mongo in future releases
MONGO_STATUS=1
for (( i=1; i<=10; i++ ))
do
	mongo --port $CONFIG_PORT --eval "rs.initiate($CONF)"
	MONGO_STATUS=$?
	if [ "$MONGO_STATUS" == "0" ]
	then
		break
	fi
	if [ "$i" -ge "10" ]
	then
		echo "Mongo Replica service failed to initiate"
		exit 1
	fi
done
mongo --port $CONFIG_PORT --eval "rs.reconfig($CONF, {force: true} )"

# initiate shard replica set
CONF="{ \
   _id: \"shardReplSet\", \
   \"version\" : 1, \
   configsvr: false, \
   members: [ \
	  { _id: 0, host: \"${MONGO_IPS[0]}:$SHARD_PORT\" }, \
	  { _id: 1, host: \"${MONGO_IPS[1]}:$SHARD_PORT\" } \
   ] \
}"

mongo --port $SHARD_PORT --eval "rs.initiate($CONF)"
mongo --port $SHARD_PORT --eval "rs.reconfig($CONF, {force: true} )"

# build string for replica connections
for IP in "${MONGO_IPS[@]}"
do
	CONFIG_DB=$CONFIG_DB"$IP:$CONFIG_PORT,"
done

# remove last comma
CONFIG_DB=`echo $CONFIG_DB | sed 's/,$//'`

if [ -z "${CONFIG_DB}" ]
then
	echo "CONFIG_DB required as first parameter"
	exit
fi

# start mongos
nohup mongos --port $ROUTER_PORT --configdb configReplSet/$CONFIG_DB  &> /home/centos/mongoRouter.out&

# initiate routers

# add one shard as replicated set
# Waits for mongos to run. Maximum 1 minute
# Graylog will remove mongo in future releases
MONGO_STATUS=1
for (( i=1; i<=10; i++ ))
do
	mongo --port $ROUTER_PORT --eval "sh.addShard( \"shardReplSet/${MONGO_IPS[0]}:$SHARD_PORT,${MONGO_IPS[1]}:$SHARD_PORT\" )"
	MONGO_STATUS=$?
	if [ "$MONGO_STATUS" == "0" ]
	then
		break
	fi
	if [ "$i" -ge "10" ]
	then
		echo "Failed to add shard. This is expected for the first mongo server initiated."
	fi
	sleep 6
done
