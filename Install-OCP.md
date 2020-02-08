# Install OCP

## On Controller

#### Check ansible can speak with every nodes in the cluster

> :warning: Run this on Controller

	ansible OSEv3 -m ping

#### Check every nodes in the cluster can speak to registry.redhat.io

> :warning: Run this on Controller

	ansible nodes -a 'ping -c 2 registry.redhat.io'

#### Set ansible hosts with you Redhat partner credential

> :warning: Run this on Controller

> :warning: Escape **'$'** character in your password if necessary.

> e.g. OREG_PWD="mypa\\$sword"

```
OREG_ID="myid"
OREG_PWD="mypa\$sword"

sed -i 's/\(oreg_auth_user=\).*$/\1'$OREG_ID'/' /etc/ansible/hosts
sed -i 's/\(oreg_auth_password=\).*$/\1'$OREG_PWD'/' /etc/ansible/hosts
```	

#### Check your access to OpenShift registry

> :warning: Run this on Controller

> :warning: docker login should return **Login Succeeded**

> :bulb: A new entry should have been added to **~/.docker/config.json** 

```
OREG=$(docker info | awk -F ': https://' '$1 ~ "Registry" {print $2}' | awk -F '/' '{print $1}') && echo $OREG
OREG_ID=$(cat /etc/ansible/hosts | awk -F'=' '$1 ~ "^oreg_auth_user" {print $2}')
OREG_PWD=$(cat /etc/ansible/hosts | awk -F'=' '$1 ~ "^oreg_auth_password" {print $2}')

docker login -u $OREG_ID -p $OREG_PWD $OREG
```

> :warning: Skopeo should return informations about **ose-docker-registry** image

```
[ ! -z $(command -v skopeo) ] && echo skopeo installed || yum install skopeo -y

skopeo inspect --tls-verify=false --creds=$OREG_ID:$OREG_PWD docker://$OREG/openshift3/ose-docker-registry:latest
```



#### Launch OCP installation

> :warning: Run this on Controller

> :bulb: To avoid network failure, launch installation on **locale console** or in a **screen**

```
[ ! -z $(command -v screen) ] && echo screen installed || yum install screen -y
screen -mdS ADM && screen -r ADM

```

##### Launch prerequisites

> :warning: Run this on Controller

```
cd /usr/share/ansible/openshift-ansible && ansible-playbook playbooks/prerequisites.yml
```

##### Launch deploy_cluster

> :warning: Run this on Controller

```
ansible-playbook playbooks/deploy_cluster.yml
```

<br>

>:hourglass_flowing_sand: :smoking::coffee::smoking::coffee::smoking::coffee::smoking: :coffee: :hourglass_flowing_sand: :beer::beer::beer::pill:  :zzz::zzz: :zzz::zzz: :zzz::zzz::hourglass_flowing_sand: :smoking::coffee: :toilet: :shower: :smoking: :coffee::smoking: :coffee: :smoking: :coffee: :hourglass: 

<br><br>

>:bulb: Leave screen with **Ctrl + a + d**

>:bulb: Come back with **screen -r ADM**

> :bulb: If something went wrong have a look at **~/openshift-ansible.log** and revert to [last snapshot](https://github.com/bpshparis/ocp-esx/blob/master/Install-OCP.md#If-necessary-revert-to-last-snapshot).

<br>

:checkered_flag::checkered_flag::checkered_flag:


# Check Openshift Installation

## On first master

#### Give admin cluster-admin role

> :warning: Run this on First Master

```
oc login -u system:admin
```

```
oc create clusterrolebinding registry-controller --clusterrole=cluster-admin --user=admin
```


## On Controller


#### Install oc Client Tools if necessary

If both **oc** and **kubectl** are not found then download [oc Client Tools](https://www.okd.io/download.html) and copy **oc** and **kubectl** in your $PATH

> :warning: Run this on Controller if necessary

	wget -c https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz

<!--
	rsync -avg --progress /mnt/iicbackup/produits/ISO/add-ons/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz .
-->

	tar xvzf openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz --strip-components 1 -C /usr/local/sbin



### Check install

#### Login to cluster

> :warning: Run this on Controller

	oc login https://lb-$OCP:8443 -u admin -p admin --insecure-skip-tls-verify=true

### Check Environment health

> :bulb: ​OCP certificate authority  can be found in your first master **/etc/origin/master/ca.crt**.

#### Checking complete environment health

> :warning: Run this on Controller

Proceed as describe [here](https://docs.openshift.com/container-platform/3.11/day_two_guide/environment_health_checks.html#day-two-guide-complete-deployment-health-check)

#### Checking Hosts Router Registry and Network connectivity

> :warning: Run this on Controller

Proceed as describe [here](https://docs.openshift.com/container-platform/3.11/day_two_guide/environment_health_checks.html#day-two-guide-host-health)



# Make a snapshot

## On Controller

### Poweroff all vms

> :warning: Run this on Controller

```
for node in lb m1 m2 m3 n1 i1 n2 i2 n3 i3 nfs; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; poweroff'; done
```

## On ESX

### Make a snapshot

#### Check all vms are powered off

> :warning: Run this on ESX

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.getstate " $1}' | sh


#### Make a snapshot

> :warning: Set SNAPNAME value before proceeding.

> :warning: Run this on ESX

```
SNAPNAME=""

vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.create " $1 " '$SNAPNAME' "}' | sh
```

#### Check snapshot

> :warning: Run this on ESX

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.get " $1 }' | sh

#### Power cluster vms on

> :warning: Run this on ESX

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh

### If necessary revert to last snapshot

> :warning: This will work *out of the box* only if vms have the **same snapshot history**.

#### Get last snapshot id from first master

> :warning: Run this on ESX

```
export SNAPIDS=$(vim-cmd vmsvc/getallvms | awk '$2 ~ "m1-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.get " $1 }' | sh | awk -F' : ' '$1 ~ "--Snapshot Id " {print $2}') && echo $SNAPIDS

export SNAPID=$(echo $SNAPIDS | awk '{print $NF}') && echo $SNAPID
```

#### Revert to last snapshot

> :warning: Run this on ESX

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.revert " $1 " " '$SNAPID' " suppressPowerOn" }' | sh

#### Power cluster vms on

> :warning: Run this on ESX

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh
