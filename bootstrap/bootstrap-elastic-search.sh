# Install elasticsearch binaries

# echo all commands
set -x

# install elasticsearch
rpm -ivh $AWS_BUCKET"elasticsearch-2.3.3.rpm"

# get config
curl -o elasticsearch.yml $AWS_BUCKET"elasticsearch.yml"
mkdir /usr/share/elasticsearch/config
mv -f elasticsearch.yml  /etc/elasticsearch/elasticsearch.yml
