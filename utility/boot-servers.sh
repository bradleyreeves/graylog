#!/bin/bash

# Master script to start services and install binaries

# exit on any failure
set -e
# echo all commands
#set -x

#App name
APP=$1
COUNT=$2
MAX_COUNT=$3
INSTANCE_TYPE="$4"
PASS=$5


. ../conf/config.sh
. ../conf/map.sh

if [ -f ../conf/aws-resource-ids.sh ]
then
	. ../conf/aws-resource-ids.sh
else
	echo "conf/aws-resource-ids.sh not found. Have you run install.sh?"
	exit
fi

# prepare bootstrap file for user-data by appending common configs
echo '#! /bin/bash' > bootstrap-$APP-temp.sh
cat ../conf/config.sh ../start/config-aws.sh >> bootstrap-$APP-temp.sh
#Set the password for Admin
if [ "$APP" == "graylog" ]
then
	#Do not print password
	set +x
	echo 'PASSWORD='$PASS >> bootstrap-$APP-temp.sh
	PASS_SECRET=$(pwgen -N 1 -s 96)
	echo 'PASS_SECRET='$PASS_SECRET >> bootstrap-$APP-temp.sh
	#set -x
fi  
if [ "$ENV" == "dev" ]
then
	# get the app bootstrap for dev env. use region to get centos vanilla ami
	cat ../bootstrap/bootstrap.sh ../bootstrap/bootstrap-$APP.sh >> bootstrap-$APP-temp.sh
	get_ami_by_region
else
	# skip bootstraps. use account ami with preinstalled app
	get_ami_by_app
fi
cat ../start/$APP-start.sh ../bootstrap/bootstrap-tag.sh >> bootstrap-$APP-temp.sh

#----------launch config---------------------------------
aws autoscaling create-launch-configuration --launch-configuration-name $STACK_NAME-$ENV-$APP --image-id $IMAGE --instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME --security-groups $SECURITY_GROUP --iam-instance-profile $PROFILE --user-data file://bootstrap-$APP-temp.sh

rm bootstrap-$APP-temp.sh

#----------auto scaling group----------------------------
aws autoscaling create-auto-scaling-group --auto-scaling-group-name $STACK_NAME-$ENV-$APP --launch-configuration-name $STACK_NAME-$ENV-$APP \
--load-balancer-names $STACK_NAME-$ENV --min-size $COUNT --max-size $MAX_COUNT --desired-capacity $COUNT --vpc-zone-identifier "$SUBNET_LIST"

aws autoscaling put-scaling-policy --auto-scaling-group-name $STACK_NAME-$ENV-$APP --policy-name $STACK_NAME-$ENV-$APP-scale-up --adjustment-type ChangeInCapacity --scaling-adjustment 1
aws autoscaling put-scaling-policy --auto-scaling-group-name $STACK_NAME-$ENV-$APP --policy-name $STACK_NAME-$ENV-$APP-scale-down --adjustment-type ChangeInCapacity --scaling-adjustment -1

POLICY_UP_JSON=$(aws autoscaling describe-policies --auto-scaling-group-name $STACK_NAME-$ENV-$APP --policy-names $STACK_NAME-$ENV-$APP-scale-up | grep PolicyARN)
POLICY_UP_ARN=$(echo $POLICY_UP_JSON | grep "PolicyARN" | sed -e 's/[,|"| ]//g' | sed -e 's/PolicyARN://g')

POLICY_DOWN_JSON=$(aws autoscaling describe-policies --auto-scaling-group-name $STACK_NAME-$ENV-$APP --policy-names $STACK_NAME-$ENV-$APP-scale-down | grep PolicyARN)
POLICY_DOWN_ARN=$(echo $POLICY_DOWN_JSON | grep "PolicyARN" | sed -e 's/[,|"| ]//g' | sed -e 's/PolicyARN://g')

aws cloudwatch put-metric-alarm --alarm-name $STACK_NAME-$ENV-$APP-high-cpu --alarm-description "Alarm if CPU too high" --alarm-actions $POLICY_UP_ARN \
--metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 60 --evaluation-periods 3 --threshold 75 --comparison-operator GreaterThanThreshold 
aws cloudwatch put-metric-alarm --alarm-name $STACK_NAME-$ENV-$APP-low-cpu --alarm-description "Alarm if CPU too low" --alarm-actions $POLICY_DOWN_ARN \
--metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 60 --evaluation-periods 3 --threshold 25 --comparison-operator LessThanThreshold 

