# Prepare OCP for Cloud Paks

## Install managed-nfs-storage Storage Class

### On NFS server

> :warning: Run this on NFS server

```
cat > installNFSServer.sh << EOF
pvcreate /dev/sdb
vgcreate exports /dev/sdb
lvcreate -n exports -l 100%VG exports
mkdir /exports
mkfs.xfs -f -n ftype=1 -i size=512 -n size=8192 /dev/exports/exports
echo "/dev/mapper/exports-exports  /exports  xfs defaults,noatime 1 2" >> /etc/fstab
mount /exports
df -hT /exports
lvs
echo "/exports *(rw,sync,no_root_squash)" >> /etc/exports
[ ! -z $(rpm -qa nfs-utils) ] && echo nfs-utils installed || { echo nfs-utils not installed; yum install -y nfs-utils rpcbind; }
systemctl restart nfs
showmount -e
systemctl enable nfs
systemctl stop firewalld
systemctl disable firewalld
EOF
```

```
chmod +x installNFSServer.sh && ./installNFSServer.sh
```

### On Controller

#### Test nfs access

##### Install nfs utils if necessary

> :warning: Run this on Controller

```
[ ! -z $(rpm -qa nfs-utils) ] && echo nfs-utils installed \
|| { echo nfs-utils not installed; yum install -y nfs-utils rpcbind; }
```


##### Mount resource and test NFS server availability

> :warning: Run this on Controller

```
[ ! -d /mnt/nfs-$OCP ] && mkdir /mnt/nfs-$OCP && mount -t nfs nfs-$OCP:/exports /mnt/nfs-$OCP

touch /mnt/nfs-$OCP/SUCCESS && echo "RC="$?
```

> :warning: Next command shoud display **SUCCESS**

```
sshpass -e ssh -o StrictHostKeyChecking=no nfs-$OCP ls /exports/ 
```

##### Clean things

> :warning: Run this on Controller

```
rm -f /mnt/nfs-$OCP/SUCCESS && echo "RC="$?

sshpass -e ssh -o StrictHostKeyChecking=no nfs-$OCP ls /exports/

umount /mnt/nfs-$OCP && rmdir /mnt/nfs-$OCP/ 
```

#### Add managed-nfs-storage storage class 


##### Log in Cluster

> :warning: Run this on Controller

```
oc login https://lb-$OCP:8443 -u admin -p admin --insecure-skip-tls-verify=true
```

##### Install and test storage class

> :warning: Run this on Controller

```
unzip $WORKDIR/nfs-client.zip -d $WORKDIR

cd $WORKDIR/nfs-client/

oc new-project storage

NAMESPACE=$(oc project -q)

sed -i -e 's/namespace:.*/namespace: '$NAMESPACE'/g' ./deploy/rbac.yaml

oc create -f deploy/rbac.yaml

oc adm policy add-scc-to-user \
hostmount-anyuid system:serviceaccount:$NAMESPACE:nfs-client-provisioner

sed -i -e 's/<NFS_HOSTNAME>/nfs-'$OCP'/g' deploy/deployment.yaml

oc create -f deploy/class.yaml

oc create -f deploy/deployment.yaml

oc get pods

oc logs $(oc get pods | awk 'NR>1 {print $1}')

oc create -f deploy/test-claim.yaml

oc create -f deploy/test-pod.yaml
```

> :warning: Next commands have to display **SUCCESS**

```
VOLUME=$(oc get pvc | awk '$1 ~ "test-claim" {print $3}')

sshpass -e ssh -o StrictHostKeyChecking=no \
nfs-$OCP ls /exports/$(oc project -q)-test-claim-$VOLUME && cd ~
```



## Exposing openshift Registry

> :bulb: Target is to be able to push docker images from Controller to Openshift registry in a secure way.

### On Controller

##### Log in cluster default project

> :warning: Run this on Controller

```
oc login https://lb-$OCP:8443 -u admin -p admin --insecure-skip-tls-verify=true -n default
```

##### Install jq 

> :bulb: jq is a json parser for command line

> :warning: Run this on Controller

```
[ -z $(command -v jq) ] && { wget -c https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && chmod +x jq-linux64 && mv jq-linux64 /usr/local/sbin/jq; } || echo jq installed
```

##### Check docker registry route

> :warning: Termination should display **passthrough** if not proceed as describe [here](https://docs.openshift.com/container-platform/3.11/install_config/registry/securing_and_exposing_registry.html#exposing-the-registry)

> :warning: Run this on Controller

```
oc get route/docker-registry -o json | jq -r .spec.tls.termination
```

##### Get OCP docker registry hostname

> :warning: Run this on Controller

```
REG_HOST=$(oc get route/docker-registry -o json | jq -r .spec.host)
```

##### Add OCP certificate authority to docker

> :warning: Run this on Controller

```
mkdir -p /etc/docker/certs.d/$REG_HOST

scp m1-$OCP:/etc/origin/master/ca.crt /etc/docker/certs.d/$REG_HOST
```

##### Log to OCP docker registry

> :warning: Run this on Controller

```
docker login -u $(oc whoami) -p $(oc whoami -t) $REG_HOST
```

> :bulb: If login has been successfull, Docker should have added an entry in ** ~/.docker/config.json**.


##### Tag a docker image with OCP docker registry hostname and push it

> :warning: Run this on Controller

```
docker pull busybox

docker tag docker.io/busybox $REG_HOST/$(oc project -q)/busybox
```

> :warning: Now you have to be able to push docker images from controller to OCP docker registry
```
docker push $REG_HOST/$(oc project -q)/busybox
```

>:checkered_flag::checkered_flag::checkered_flag:


[Make a snapshot](https://github.com/bpshparis/ocp-esx/blob/master/Install-OCP.md#If-necessary-revert-to-last-snapshot)
