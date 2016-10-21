#!/bin/bash

# create elastic loadbalancer with listeners for ports:
# 9999 fabio loadbalance port for services
# 9998 fabio ui
# 8500 consul web-ui -> http://localhost:8500/ui

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

aws elb create-load-balancer --load-balancer-name nomad-worker \
    --scheme internal \
    --listeners "Protocol=HTTP, LoadBalancerPort=80,InstanceProtocol=HTTP, InstancePort=9999" \
    "Protocol=HTTP, LoadBalancerPort=9998,InstanceProtocol=HTTP, InstancePort=9998" \
    "Protocol=HTTP, LoadBalancerPort=8500,InstanceProtocol=HTTP, InstancePort=8500" \
    --subnets $(echo -n $ELB_SUBNET_IDS) \
    --security-groups $(echo -n $SECURITY_GROUP_ID)

aws elb configure-health-check --load-balancer-name nomad-worker \
    --health-check Target=HTTP:9998/health,Interval=15,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3
