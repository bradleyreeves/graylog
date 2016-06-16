# Install mongo binaries

# echo all commands
set -x

# configure repo
curl -o mongodb-org-3.2.repo $AWS_BUCKET"mongodb-org-3.2.repo"
mv -f mongodb-org-3.2.repo  /etc/yum.repos.d/mongodb-org-3.2.repo

# install mongo 
rpm --import $AWS_BUCKET"server-3.2.asc"
yum install -y mongodb-org
