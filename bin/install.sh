#! /bin/bash

# Automated install of everything graylog

. ../conf/config.sh

CODE=$(curl --write-out %{http_code} --silent http://graylog.pegs-services.com/)
if [ "$CODE" == "200" ]
then
	echo "Healthy Graylog cluster already running under name '$STACK_NAME-$ENV'"
	exit 0
fi

# exit on any failure
set -e
# echo all commands
#set -x
 
# set password
set +x
while true
do
   echo "Please set the password for user admin, followed by [ENTER]:"
   read -s PASSWORD
   echo "enter password again:"
   read -s PASSWORD1
   if [ "$PASSWORD" == "$PASSWORD1" ]
	  then
		 echo "Password set"
		 #set -x
		 break
	  else
		  echo "two passwords don't match, please try again."
	fi
done

# rollback if install fails
trap \
	'if [ "$?" != "0" ]; \
then \
	echo "Script failed, rolling back."; \
	./uninstall.sh
fi' \
exit

# Start the background aws resources. This will start everything except the servers themselves
# This command outputs the subnet list and security group ID to conf/aws-resource-ids.sh
. ../utility/install-aws-resources.sh

# Start autoscaling groups (servers). All stderr sent to log files log/*.out

# start elastic search nodes
# MAX=N
# MIN=1
. ../utility/boot-servers.sh elastic-search $ELASTIC_SEARCH_INSTANCE_NUM $ELASTIC_SEARCH_MAX_NUM "r3.large"

# start 2 nodes for each of the following apps
# Graylog will get rid of mongo db in future versions, based on their documents.
. ../utility/boot-servers.sh mongo $MONGO_INSTANCE_NUM $MONGO_MAX_NUM "t2.micro"

# start graylog server nodes
# MAX=N
# MIN=1
# Do not print password
set +x
. ../utility/boot-servers.sh graylog $GRAYLOG_INSTANCE_NUM $GRAYLOG_MAX_NUM "t2.medium" $PASSWORD
#set -x

# Do not print password
set +x
# Do not exit if this curl fails
set +e
# Get load balancer DNS name from AWS
LOAD_BALANCER_JSON=$(aws elb describe-load-balancers --load-balancer-names $STACK_NAME-$ENV | grep DNSName)
LOAD_BALANCER=$(echo $LOAD_BALANCER_JSON | sed -e 's/[,|"| ]//g' | sed -e 's/DNSName://g')

echo "Waiting for Graylog to respond ok. This could take 5 minutes."
for (( i=1; i<=50; i++ ))
do
	CODE=$(curl --write-out %{http_code} --silent $LOAD_BALANCER:12900/system/lbstatus | sed -e 's/ALIVE//g')
	if [ "$CODE" == "200" ]
	then
		echo "Graylog response: ok"
		# create input
		INPUT=$(curl -XPOST $LOAD_BALANCER:12900/system/inputs -d \
			'{"title":"GELF HTTP", "type":"org.graylog2.inputs.gelf.http.GELFHttpInput", "global":"true", "configuration": 
			{ "recv_buffer_size": 1048576, "max_message_size": 2097152, "bind_address": "0.0.0.0", "port": 12201, "tls_enable": 
			false, "use_null_delimiter": true } }' -H "Content-Type: application/json" -u admin:$PASSWORD | sed -e 's/.*id"://g' | sed -e 's/["|\}]//g')
		# start input
		curl -XPUT $LOAD_BALANCER:12900/system/inputstates/$INPUT
		break
	fi
	if [ "$i" -ge "50" ]
 	then
 		echo "Failed to get proper response from Graylog."
 		echo "Check the load balancer and verify 2 healthy instances"
 		echo "If no inputs have been created, try running this command manually (replace 'pass' with the password you created earlier):"
 		read -r -d '' WARNING <<- EOM 
		curl -XPOST $LOAD_BALANCER:12900/system/inputs -d 
		'{"title":"GELF HTTP", "type":"org.graylog2.inputs.gelf.http.GELFHttpInput", "global":"true", "configuration": 
		{ "recv_buffer_size": 1048576, "max_message_size": 2097152, "bind_address": "0.0.0.0", "port": 12201, "tls_enable": 
		false, "use_null_delimiter": true } }' -H "Content-Type: application/json" -u admin:pass
		EOM
		echo $WARNING
	fi
	sleep 6
done
#set -x

echo "Waiting for ElasticSearch status 'green'. This could take 5 minutes."
for (( i=1; i<=50; i++ ))
do
	STATUS=$(curl $LOAD_BALANCER:12900/system/indexer/overview -u admin:$PASSWORD)
	if [[ $STATUS == *"\"health\":{\"status\":\"green\""* ]]
	then
		echo "ElasticSearch status: green"
		break
	fi
	if [ "$i" -ge "50" ]
	then
		echo "Failed to get proper status from ElasticSearch cluster. Check ElasticSearch servers for error logging"
	fi
	sleep 6
done

unset PASSWORD PASSWORD1

echo "Successful Graylog Install"
echo "Graylog URL: $LOAD_BALANCER"
echo "Example curl: curl -XPOST $LOAD_BALANCER:12202/gelf -p0 -d '{\"short_message\":\"Hello there\", \"host\":\"example.org\", \"facility\":\"test\", \"_foo\":\"bar\"}' -u admin:pass"
