####Installs a Graylog 2.0 cluster on AWS autoscaling servers.

For detailed usage guides, see the readme files in dev and prod directories.

####Environments
	dev boots servers slowly as it installs and configures all services through user-data
	prod boots servers quickly as it uses the dev AMI images, then uses user-data to configure servers

####AWS CLI
	See the following install instructions:
	http://docs.aws.amazon.com/cli/latest/userguide/installing.html
	To configure the CLI, see:
	http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html
	
####config.sh
	Master config file
	Changes here affect such things as environment, server count, and memory for ElasticSearch
	When installing different environments, be sure to modify map.sh with different subnet values

####Download graylog key
	note: this is only necessary if you need to ssh into the machines. Not required for install
	https://console.aws.amazon.com/s3/home?region=us-west-2&bucket=pegs-keys&prefix= 
	Change the file permissions to 600, i.e. chmod 600 graylog.pem

####Commands

install:  
>	./install.sh
	
uninstall:  
>	./uninstall.sh

kill any app's servers  
>	. ../utility/kill-server.sh <app-name>

kill all app servers  
>	for APP in elastic-search graylog mongo  
>	do  
>		. ../utility/kill-servers.sh $APP  
>	done


start 3 elastic search nodes  
MAX=N  
MIN=1  
>	. ../utility/boot-servers.sh elastic-search 3 "r3.large" 2> ../log/elastic-search.out


start 2 mongo servers  
This will create two replica sets,  
one for mongo configuration  
and one for storing data  
MAX=3  
MIN=1  
>	. ../utility/boot-servers.sh mongo 2 "t2.micro" 2> ../log/mongo.out

start 2 graylog servers  
MAX=N  
MIN=1  
this will prompt for a master password, input required
>	. ../utility/boot-servers.sh graylog 2 2> ../log/graylog.out

####Send messages 
	note: any arbitrary field may be sent; go ahead and generate custom values to analyze
	see the logstash folder for detailed instructions on installing and running logstash on CRS log servers
	