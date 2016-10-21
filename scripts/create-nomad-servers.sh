#!/bin/bash

source ./env.sh

echo "AMI_ID=$AMI_ID"
echo "COUNT_WORKERS=$COUNT_WORKERS"
echo "INSTANCE_PROFILE=$INSTANCE_PROFILE"
echo "INSTANCE_TYPE_WORKERS=$INSTANCE_TYPE_WORKERS"
echo "INSTANCE_TYPE_SERVERS=$INSTANCE_TYPE_SERVERS"
echo "SSH_KEYNAME=$SSH_KEYNAME"
echo "VPC_ID=$VPC_ID"
echo "SECURITY_GROUP_ID=$SECURITY_GROUP_ID"
echo "SUBNET_ID=$SUBNET_ID"
echo "ELB_SUBNET_IDS=$ELB_SUBNET_IDS"

# default user is ubuntu!

# create nomad servers (ubuntu 16.04 eu-west-1)
aws ec2 run-instances --iam-instance-profile Arn=$INSTANCE_PROFILE --image-id $AMI_ID \
    --count 3 --instance-type $INSTANCE_TYPE_SERVERS --key-name $SSH_KEYNAME \
    --security-group-ids  $(echo -n $SECURITY_GROUP_ID) \
    --subnet-id $(echo -n $SUBNET_ID) --user-data file://server-install.sh > output-servers.json \
    --block-device-mappings file://block-device-mapping.json

# create tags for ec2-instances
INSTANCE_IDS=$(cat output-servers.json | jq ".Instances[].InstanceId" | tr -d '"' | paste -sd " " -)
aws ec2 create-tags --resources $(echo -n $INSTANCE_IDS) --tags Key=Name,Value=nomad-server-dev
