#!/bin/sh
# get IPs based on tags

# exit on any failure
set -e
# echo all commands
#set -x

#TODO add tags to autoscaling group that specify cluster
#CLUSTER=$1
APP=$1

if [ -z "$APP" ]
then
    echo "string to search for app nodes is required as first parameter"
    exit
fi

if [ -z "$REGION" ]
then
	# Get the region for this instance
	EC2_AVAIL_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
	EC2_REGION=$(echo $EC2_AVAIL_ZONE | sed 's/[a-z]$//')
else
	# Use the variable set in conf/config.sh
	EC2_REGION=$REGION
fi

aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $APP --region $EC2_REGION | \
grep InstanceId | sed -e 's/[,|"| ]//g' | sed -e 's/InstanceId://g'
