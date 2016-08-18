#!/bin/sh
# Resize the root partition of AMI in case it is given larger than default size
start_sector=$(sudo fdisk -lu | grep ^/dev/xvda1 |  awk -F" "  '{ print $3 }')

#delete and recreate the partition
cat <<EOF | sudo fdisk -c -u /dev/xvda
d
n
p
1
$start_sector

w
EOF

# done, need to reboot after this
echo "please reboot your machine"