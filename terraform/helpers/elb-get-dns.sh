#!/bin/bash

aws elb describe-load-balancers --load-balancer-names nomad-worker-elb | jq -r ".LoadBalancerDescriptions[].DNSName"
