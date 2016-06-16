# SELinux permissive mode, not persistent. Allow apps to open ports.
setenforce 0

# Set timezone on servers to arizona
timedatectl set-timezone America/Phoenix
rm /etc/localtime
cp /usr/share/zoneinfo/America/Phoenix /etc/localtime
    
# set region
rm -rf ~/.aws
mkdir ~/.aws
cat > ~/.aws/config <<ENDAWS
[default]
region=$REGION
ENDAWS
