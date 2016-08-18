# Pre-reqs 
(on your local machine / ansible host)

* git
* ansible ~= 2.1.0 (use stable-2.1)
* python ~= 2.7.6
* awscli >= 1.10 
* mysql >= 5.5
* boto >= 2.40
* Download [JCE_policy-8.zip](http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip) to root of cloned directory


# Warning
* Hortonworks version of Hue will not install on centos 7
* Hue requires python 2.6, HDP requires 2.7, they cannot be installed side by side

# Quickstart
```shell
export EC2_REGION=us-west-2
export AWS_ACCESS_KEY_ID=KEY
export AWS_SECRET_ACCESS_KEY=SECRET_KEY
export DATALAKE_NAME=jreynolds
export ENVIRONMENT=dev
export RDS_HOST=$DATALAKE_NAME-$ENVIRONMENT.cmq3trivul8e.us-west-2.rds.amazonaws.com
export VPC_BASE=10.101
export SUBNET_BASE=100
export VPN_KEY_NAME=ec2_vpn_server_key
export CA_KEY_NAME=ec2_ca_key
export CLUSTER_NODE_KEY_NAME=ec2_cluster_node_key 
export OPENVPN_PASSWORD=[PASSWORD]

eval `ssh-agent -s`
ssh-add /PATH/TO/PEM/$VPN_KEY_NAME.pem
ssh-add /PATH/TO/PEM/cert_signing_server.pem
ssh-add /PATH/TO/PEM/$CLUSTER_NODE_KEY_NAME.pem

# if Ansible is not on your PATH
# source ~/ansible/hacking/env-setup

# create Cloudformation Stacks and server instances
ansible-playbook main.yml -i ec2.py

# configure OpenVPN (must use different ec2.ini to require public ip)
EC2_INI_PATH=ec2_public_ip.ini ./ec2.py --refresh-cache
EC2_INI_PATH=ec2_public_ip.ini ansible-playbook roles/openvpn/main.yml -i ec2.py
# restore private IP inventory
./ec2.py --refresh-cache

# Connect to VPN - https://$DATALAKE_NAME-vpn-a.vpicu.net/admin and modify the 
# Vpn Settings -> routing -> specify private subnet access to $(VPC_BASE).0.0/16
# e.g., the whole vpc; click 'update running server' when finished

# install default packages, jdk, sign/distribute certificates, 
ansible-playbook baseline.yml -i ec2.py

# configure ambari server, create mysql users & databases on RDS
ansible-playbook ambari.yml -i ec2.py --extra-vars="drop_databases=True"

# use last octet of private IP for each instance
export AMBARI_HOSTNAME=datanode-N.$ENVIRONMENT.$DATALAKE_NAME.datalake
export NAMENODE_HOSTNAME=namenode-N.$ENVIRONMENT.$DATALAKE_NAME.datalake
export DATANODE_HOSTNAME_1=datanode-N.$ENVIRONMENT.$DATALAKE_NAME.datalake
export DATANODE_HOSTNAME_2=datanode-N.$ENVIRONMENT.$DATALAKE_NAME.datalake
export BLUEPRINT_NAME=datalake_v0
export CLUSTER_NAME=$DATALAKE_NAME\_$ENVIRONMENT
export AMBARI_ADMIN=admin
export AMBARI_PWD=admin

# update your /etc/hosts file to include the private IP and node hostnames

# generate ambari blueprint config file
# the default linux truststore password is 'changeit'
ansible-playbook ambari-datalake-config-generate.yml --extra-vars="datanode_1_hostname=$DATANODE_HOSTNAME_1 datanode_2_hostname=$DATANODE_HOSTNAME_2 ambari_hostname=$AMBARI_HOSTNAME blueprint_name=$BLUEPRINT_NAME rds_hostname=$RDS_HOST namenode_hostname=$NAMENODE_HOSTNAME default_password=[PASSWORD] rds_master_username=master rds_master_password=[PASSWORD]  rds_rangerkms_password=[PASSWORD] knox_secret=[SECRET] rds_hive_password=[PASSWORD] keystore_password=[PASSWORD] keystore_key_password=[PASSWORD] kms_masterkey_password=[PASSWORD] rds_oozie_password=[PASSWORD] truststore_password=changeit amb_ranger_password=[PASSWORD]"

# execute the following curl commands
curl --insecure -H "X-Requested-By: ambari" -X POST -u $AMBARI_ADMIN:$AMBARI_PWD --data "@./ambari-datalake-blueprint.json" https://$AMBARI_HOSTNAME:8443/api/v1/blueprints/$BLUEPRINT_NAME

# Request cluster creations
curl --insecure -H "X-Requested-By: ambari" -X POST -u $AMBARI_ADMIN:$AMBARI_PWD --data "@./ambari-datalake-$ENVIRONMENT-config.json" https://$AMBARI_HOSTNAME:8443/api/v1/clusters/$CLUSTER_NAME

# Optional: track cluster creation status (number at end of uri will vary)
curl --insecure -H "X-Requested-By: ambari" -X GET -u $AMBARI_ADMIN:$AMBARI_PWD https://$AMBARI_HOSTNAME:8443/api/v1/clusters/$CLUSTER_NAME/requests/1

# Run oozie ssl configuration
ansible-playbook oozie.yml -i ec2.py --extra-vars="datalake_name=$DATALAKE_NAME cluster_name=$CLUSTER_NAME cluster_env=$ENVIRONMENT ambari_hostname=$AMBARI_HOSTNAME"

# Cleanup tasks
ansible-playbook cleanup.yml -i ec2.py

# Browse to https://$AMBARI_HOSTNAME:8443 to view the cluster dashboard
```

# Optional steps: revoking ssl certificates from temp certificate authority
```shell
sudo su
cd /root/ca/
# find the ID of the certificate to revoke
more intermediate/index.txt
# revoke it
openssl ca -revoke intermediate/newcerts/1000.pem -config intermediate/openssl.cnf
```