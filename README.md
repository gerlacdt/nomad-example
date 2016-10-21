# Nomad tutorial

This guide is shamelessly copied from Kelsey Hightower's great presentation at
[hashiconf-eu-2016](https://github.com/kelseyhightower/hashiconf-eu-2016)

[AWS](https://aws.amazon.com/) is used instead of
[Google Cloud Platform](https://cloud.google.com/)

## Instructions

### Install consul and nomad

The guide is based on [consul-v0.7.0](https://www.consul.io/downloads.html) and
[nomad-v0.4.1](https://www.nomadproject.io/downloads.html)

```bash
# download consul and nomad to your laptop
# put them in your $PATH
```

### Adjust environment variables

``` bash
cp scripts/env.sh.tmpl scripts/env.sh

# adjust environment variables
vim scripts/env.sh
```

### Create nomad servers and join them to a cluster

```bash
./create-nomad-servers.sh

# wait till they are ready

# get ips
NOMAD_SERVER_IPS=$(./get_nomad_server_ips.sh)
MASTER_IP=$(echo -n $NOMAD_SERVER_IPS | awk '{print $1}')

# create consul and nomad master cluster
nomad server-join --address="http://$MASTER_IP:4646" $(echo -n $NOMAD_SERVER_IPS | awk '{print $2,$3}')
consul join --rpc-addr="$MASTER_IP:8400" $(echo -n $NOMAD_SERVER_IPS | awk '{print $2,$3}')

# check nomad and consul master nodes
nomad server-members --address="http://$MASTER_IP:4646"
consul members --rpc-addr="$MASTER_IP:8400"
```

### Create nomad workers

```bash
./create-nomad-workers.sh

# wait till they are ready

NOMAD_WORKER_IPS=$(./get_nomad_worker_ips.sh)

# check nomad workers
nomad node-status --address="http://$MASTER_IP:4646"
```

### Create ELB

``` bash
./elb-create.sh
./elb-register-nomad-workers.sh
export ELB=$(./elb-get-dns.sh)
```

### Rollout consul workers

```bash
nomad plan --address=http://$MASTER_IP:4646 consul.nomad
nomad run --address=http://$MASTER_IP:4646 consul.nomad
nomad status --address=http://$MASTER_IP:4646 consul
```

### Rollout fabio (zero-conf load balancing)

```bash
nomad plan --address=http://$MASTER_IP:4646 fabio.nomad
nomad run --address=http://$MASTER_IP:4646 fabio.nomad
nomad status --address=http://$MASTER_IP:4646 fabio
```

### consul and fabio web-uis

``` bash
# consul
http://$ELB:8500/ui

# fabio
http://$ELB:9998
```

### Rollout helloapp v1

```bash
nomad plan --address=http://$MASTER_IP:4646 helloapp.nomad
nomad run --address=http://$MASTER_IP:4646 helloapp.nomad
nomad status --address=http://$MASTER_IP:4646 helloapp

# make some requests
curl -s -H "Host: hello.internal" http://$ELB/version
curl -s -H "Host: hello.internal" http://$ELB/hello
curl -s -H "Host: hello.internal" http://$ELB/health

nomad logs -f --address=http://$MASTER_IP:4646 -stderr <alloc-id>
```

### Scale helloapp v1

```bash
# set count = 5

nomad plan --address=http://$MASTER_IP:4646 helloapp.nomad
nomad run --address=http://$MASTER_IP:4646 helloapp.nomad
```

### Poll helloapp periodically

```bash
while true; do curl -s -H "Host: hello.internal" http://$ELB/version; sleep 1; done
```

### Update helloapp v2
```bash
# set new docker image helloapp v2

nomad plan --address=http://$MASTER_IP:4646 helloapp.nomad
nomad run --address=http://$MASTER_IP:4646 helloapp.nomad
nomad status --address=http://$MASTER_IP:4646 helloapp
```

### Blue-green Deployment / Canary

```bash
nomad stop --address=http://$MASTER_IP:4646 helloapp

nomad plan --address=http://$MASTER_IP:4646 helloapp-blue-green.nomad
nomad run --address=http://$MASTER_IP:4646 helloapp-blue-green.nomad
nomad status --address=http://$MASTER_IP:4646 helloapp-blue-green

# change route weight for fine-grained routing
# fabio route overrides
route weight hello-service hello.internal weight 1.0 tags "blue"   # v0.1.0
route weight hello-service hello.internal weight 1.0 tags "green"  # v0.2.0
```

### Install Redis

```bash
nomad plan --address=http://$MASTER_IP:4646 redis.nomad
nomad run --address=http://$MASTER_IP:4646 redis.nomad
nomad status --address=http://$MASTER_IP:4646 redis
nomad logs -f --address=http://$MASTER_IP:4646 <alloc-id>

# lookup redis port
curl $ELB:8500/v1/catalog/service/cache-redis | jq
```

### Create Schedule Batch Job

``` bash
nomad plan batch.nomad
nomad run batch.nomad
nomad status batch
nomad status <batch/periodic-id>
nomad logs --address=http://$MASTER_IP:4646 <alloc-id>
```

# Cleanup

```bash
./elb-delete.sh
./delete-nomad-workers.sh
./delete-nomad-servers.sh
```

# References

* [nomad](https://www.nomadproject.io/)
* [Large-scale cluster management at Google with Borg](http://research.google.com/pubs/pub43438.html)
