#! /bin/bash
# install common utilities

# echo all commands
set -x

# install pip
curl $AWS_BUCKET"get-pip.py" | python

# install aws cli, --ignore-installed  is required
pip install awscli --ignore-installed six

# install java 8
yum install -y \
    java-1.8.0-openjdk \
    java-1.8.0-openjdk-devel \
    java-1.8.0-openjdk-headless \
    java-1.8.0-openjdk-javadoc \
	epel-release
