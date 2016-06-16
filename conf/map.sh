#! /bin/bash

# map image / app
# these are located in us-west-2. This should be expanded to other regions.
get_ami_by_app () {
	case "$APP" in
	    "elastic-search")
			IMAGE=ami-64ad5404
	    ;;
	    "mongo")
			IMAGE=ami-5b3ec53b
	    ;;
	    "graylog")
			IMAGE=ami-8802f9e8
	    ;;
	    *)
	            echo $"No image found for specified APP: $APP"
	            exit 1
	esac
}


# map image / region
get_ami_by_region () {
	case "$REGION" in
	    "us-west-2")
			IMAGE=ami-d2c924b2
	    ;;
	    "us-west-1")
			IMAGE=ami-af4333cf
	    ;;
	    "eu-central-1")
			IMAGE=ami-9bf712f4
	    ;;
	    "eu-west-1")
			IMAGE=ami-7abd0209
	    ;;
	    "ap-southeast-1")
			IMAGE=ami-f068a193
	    ;;
	    "ap-southeast-2")
			IMAGE=ami-fedafc9d
	    ;;
	    "ap-northeast-1")
			IMAGE=ami-eec1c380
	    ;;
	    "sa-east-1")
			IMAGE=ami-26b93b4a
	    ;;
	    *)
	            echo $"No image found for specified REGION: $REGION"
	            exit 1
	esac
}

# map cidr / zone
get_cidr_by_zone () {
	case $ZONE in
	    a)
			SUBNET="10.150.65.0/27"
	    ;;
	    b)
			SUBNET="10.150.65.32/27"
	    ;;
	    c)
			SUBNET="10.150.65.64/27"
	    ;;
	    *)
	            echo $"Invalid ZONE: $ZONE"
	            exit 1
	esac
}
