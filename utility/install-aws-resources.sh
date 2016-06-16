#! /bin/bash

. ../conf/config.sh
. ../conf/map.sh

	#----------security group------------------------------
SG_JSON=$(aws ec2 create-security-group --group-name $STACK_NAME-$ENV --description $STACK_NAME-$ENV --vpc-id $VPC_ID | grep GroupId)
SG_ID=$(echo $SG_JSON | sed -e 's/[,|"| ]//g' | sed -e 's/GroupId://g')
	# Saving security group and subnet parameters to conf/aws-resource-ids.sh
echo "SECURITY_GROUP=$SG_ID" > "../conf/aws-resource-ids.sh"
	# repeat for more inbound rules, replace "ingress" with "egress" for outbound rules
    # we only allow pegs' internal access to ports for graylog.
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 12900  --cidr $PEGS_IP_RANGE
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80  --cidr $PEGS_IP_RANGE
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22  --cidr $PEGS_IP_RANGE
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 12202  --cidr $PEGS_IP_RANGE
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 0-65535  --source-group $SG_ID
aws ec2 create-tags --resources $SG_ID --tags Key=Name,Value=$STACK_NAME-$ENV

	#----------subnets---------------------------------------
for ZONE in a b c
do
	# from conf/config.sh
	get_cidr_by_zone
	# create the subnet
	SUBNET_JSON=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET --availability-zone $REGION$ZONE | grep SubnetId)
	# store the subnet id
	SUBNET_ID=$(echo $SUBNET_JSON | sed -e 's/[,|"| ]//g' | sed -e 's/SubnetId://g')
	# tag the subnet
	# calling this too quickly will generate a create-tag limit error
	sleep 5
	aws ec2 create-tags --resources $SUBNET_ID --tags Key=Name,Value="$STACK_NAME-$ENV-$ZONE"
	# create a list of subnet
	SUBNET_LIST="$SUBNET_LIST $SUBNET_ID"

		#------------------route table-----------------------
	aws ec2 associate-route-table --subnet-id $SUBNET_ID --route-table-id rtb-ae020fcb
done
	# remove first space
SUBNET_LIST=`echo $SUBNET_LIST | sed 's/^ //'`
	# save the list of subnets for later
echo "SUBNET_LIST=${SUBNET_LIST// /,}" >> "../conf/aws-resource-ids.sh"

	#----------load balancers--------------------------------
LOAD_BALANCER_JSON=$(aws elb create-load-balancer --load-balancer-name $STACK_NAME-$ENV --security-groups $SG_ID --listeners \
Protocol=HTTP,LoadBalancerPort=12202,InstanceProtocol=HTTP,InstancePort=12202 \
Protocol=HTTP,LoadBalancerPort=12900,InstanceProtocol=HTTP,InstancePort=12900 \
Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=9000 \
--subnets $SUBNET_LIST --scheme internal | grep DNSName)
LOAD_BALANCER=$(echo $LOAD_BALANCER_JSON | sed -e 's/[,|"| ]//g' | sed -e 's/DNSName://g')
aws elb configure-health-check --load-balancer-name $STACK_NAME-$ENV --health-check "Target=HTTP:12900/system/lbstatus,Interval=10,Timeout=5,UnhealthyThreshold=2,HealthyThreshold=2"

echo "See conf/aws-resource-ids.sh for subnet and security group IDs"