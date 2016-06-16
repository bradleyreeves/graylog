# Automated uninstall of everything graylog
# This can take several minutes

# echo all commands
set -x

. ../conf/config.sh


# protect against accidental uninstall
while true
do
   echo "Please verify the cluster environment, followed by [ENTER]:"
   read -s ENV_TMP
   echo "enter environment again:"
   read -s ENV_TMP1
   if [ "$ENV_TMP" == "$ENV_TMP1" ]
   then
   	  	if [ "$ENV_TMP" == "$ENV" ]
   	  	then
		 	echo "Environment verified"
		 	break
		 else
		 	echo "Does not match environment in config file. Please verify config/config.sh ENV value"
		 fi
	else
		echo "Entered different values, please try again."
	fi
done

# kill all autoscaling groups
APPS=()
for APP in mongo graylog elastic-search
do
	nohup ./../utility/kill-servers.sh $STACK_NAME-$ENV-$APP &> ../log/$APP.out &
	APPS+=($!)
done

# Uninstall the background aws resources. This will remove everything after the servers are gone
. ../utility/uninstall-aws-resources.sh

echo "Waiting for autoscaling groups to delete before complete"
wait ${APPS[0]}
wait ${APPS[1]}
wait ${APPS[2]}
wait ${APPS[3]}
wait ${APPS[4]}

echo "Uninstall complete"
