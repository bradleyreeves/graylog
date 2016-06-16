#! /bin/bash
# Tag AWS Servers

# echo all commands
set -x

INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
aws ec2 create-tags --resources $INSTANCE_ID --tags Key=node,Value=$STACK_NAME-$ENV-$APP
