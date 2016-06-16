# Install graylog server binaries

# echo all commands
set -x

# install graylog server, move to s3
rpm -Uvh $AWS_BUCKET"graylog-2.0-repository-latest.rpm"
yum install -y graylog-server

# replace config
curl -o server.conf $AWS_BUCKET"server.conf"

mv -f server.conf /etc/graylog/server/server.conf

# install nginx components
yum -y install nginx
yum -y install httpd-tools

sed -i -e 's/location \/ {/location \/ {\nauth_basic "Username and Password are required";\nauth_basic_user_file \/etc\/nginx\/.htpasswd;/' /etc/nginx/nginx.conf
sed -i -e 's/80 default_server;/12202 default_server;/' /etc/nginx/nginx.conf
sed -i -e 's/location \/ {/location \/ {\nproxy_pass         http:\/\/127.0.0.1:12201\/;/' /etc/nginx/nginx.conf
sed -i -e 's/root         \/usr\/share\/nginx\/html;\n//' /etc/nginx/nginx.conf
