#! /bin/bash

VPC_ID="vpc-881f2ded"
DEFAULT_MONGO_REPLICA_PORT=27019
DEFAULT_ELASTIC_SEARCH_PORT=9300
PROFILE="arn:aws:iam::490283132601:instance-profile/graylog"
STACK_NAME=graylog
ENV=prod
KEY_NAME=graylog
PEGS_IP_RANGE="10.113.0.0/16"
VPC_IP_RANGE="10.150.0.0/16"
AWS_BUCKET="https://s3-us-west-2.amazonaws.com/graylog-config/"
REGION="us-west-2"
PUBLIC_ROUTE_TABLE="rtb-82020fe7"
PRIVATE_ROUTE_TABLE="rtb-ae020fcb"
MAX_INTANCES_NUM=10
ROUTE_HOSTED_ZONE=Z22FYYLU55GLDA
ELB_HOSTED_ZONE=Z33MTJ483KN6FU

# autoscaling group configs - desired and maximum number of servers
ELASTIC_SEARCH_INSTANCE_NUM=3
ELASTIC_SEARCH_MAX_NUM=5
GRAYLOG_INSTANCE_NUM=2
GRAYLOG_MAX_NUM=4
MONGO_INSTANCE_NUM=2
MONGO_MAX_NUM=4

# this should be around half the memory available for the instance type being run for elastic search
export ES_MIN_MEM="8g"
export ES_MAX_MEM=$ES_MIN_MEM
export ES_HEAP_SIZE="8g"
