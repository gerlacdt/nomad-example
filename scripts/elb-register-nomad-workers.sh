#!/bin/bash

NOMAD_WORKER_INSTANCE_IDS=$(aws ec2 describe-instances \
                        --filters "Name=tag:Name,Values=nomad-worker-dev" \
                        | jq -r ".Reservations[].Instances[].InstanceId")

echo -n $NOMAD_WORKER_INSTANCE_IDS


aws elb register-instances-with-load-balancer \
    --load-balancer-name nomad-worker \
    --instances $(echo -n $NOMAD_WORKER_INSTANCE_IDS)
