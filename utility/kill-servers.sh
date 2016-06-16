#!/bin/bash

# Kill launch config and autoscaling group, including servers

# echo all commands
set -x

#App name
APP=$1

ASG_ARN=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name $APP | grep AutoScalingGroupARN)

if [ "$ASG_ARN" != "" ]
then
	#----------auto scaling group----------------------------
	aws autoscaling update-auto-scaling-group --auto-scaling-group-name $APP --desired-capacity 0 --min-size 0 --max-size 0
	./../utility/execute-aws.sh "aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $APP"
else
	echo Autoscaling Group does not exist
fi

#----------launch config---------------------------------
aws autoscaling delete-launch-configuration --launch-configuration-name $APP
