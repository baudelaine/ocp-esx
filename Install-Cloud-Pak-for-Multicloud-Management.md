# Install Cloud Pak for Multicloud Management

## Pre-installation tasks

### On First Master Node

#### Enable the Admission and Validating Webhooks

##### Write the plugin configuration file

> :warning: Run this on first Master

```
cat > admissionWebhooks.yaml << EOF
    MutatingAdmissionWebhook:
      configuration:
        apiVersion: apiserver.config.k8s.io/v1alpha1
        kubeConfigFile: /dev/null
        kind: WebhookAdmission
    ValidatingAdmissionWebhook:
      configuration:
        apiVersion: apiserver.config.k8s.io/v1alpha1
        kubeConfigFile: /dev/null
        kind: WebhookAdmission
EOF
```

##### Add the plugin file to master configuration.

> :warning: Run this on first Master

```
sed -i -e '/^\s\{2\}pluginConfig:/r admissionWebhooks.yaml' /etc/origin/master/master-config.yaml
```


#### Restart apiserver and controllers

> :warning: Run this on first Master

```
/usr/local/bin/master-restart api
/usr/local/bin/master-restart controllers
```

### On Controller

#### Prepare for Elasticsearch

> :warning: **vm.max_map_count** has to be set to **262144** to all nodes

##### Check

> :warning: Run this on Controller

```
for node in lb m1 m2 m3 n1 i1 n2 i2 n3 i3; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; sysctl -n vm.max_map_count'; done
```

##### Update if necessary

> :warning: Run this on Controller

```
for node in lb m1 m2 m3 n1 i1 n2 i2 n3 i3; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; sysctl -w vm.max_map_count=262144; echo "vm.max_map_count=262144" | tee -a /etc/sysctl.conf'; done
```

## Install the IBM Cloud Pak for Multicloud Management

### On Controller

#### Obtain the installation file

> :bulb: Download part number **CC4L8EN** either from [IBM Passport Advantage](https://www.ibm.com/software/passportadvantage/pao_customer.html) or from [XL](https://w3-03.ibm.com/software/xl/download/ticket.wss).

<!--
```
mount /mnt/iicbackup/produits/

rsync /mnt/iicbackup/produits/ISO/ibm_cloud_pak_for_mcm/ibm-cp4mcm-core-1.2-x86_64.tar.gz ~
```
-->


#### Add 50G in root logical volume

##### On ESX

> :warning: If session is new, please [set-esx-environment-variables](https://github.com/bpshparis/ocp-esx/blob/master/Build-Cluster.md#set-esx-environment-variables) first.

> :warning: Run this on ESX

```
DISK=$DATASTORE/$OCP/ctl-$OCP/root2.vmdk
BUS=0
VMID=$(vim-cmd vmsvc/getallvms | awk '$2 ~ "ctl-ocp" && $1 !~ "Vmid" {print $1}')
NUM=$(vim-cmd vmsvc/device.getdevices $VMID | grep -i -c 'label = "Hard disk')

vmkfstools -c 50G $DISK

vim-cmd vmsvc/device.diskaddexisting $VMID $DISK $BUS $NUM
```

##### On Controller

>:warning: Set **DISK**, **PART**, **VG** and **LV** variables accordingly in **$WORKDIR/extendRootLV.sh** before proceeding 

> :warning: Run this on Controller

```
$WORKDIR/extendRootLV.sh
```


#### Load the container images into the local registry

> :bulb: To avoid network failure, launch installation on **locale console** or in a **screen**

> :warning: Run this on Controller

```
[ ! -z $(command -v screen) ] && echo screen installed || yum install screen -y
screen -mdS ADM && screen -r ADM
```

```
tar xvf ~/ibm-cp4mcm-core-1.2-x86_64.tar.gz -O | sudo docker load
```

<br>

:hourglass_flowing_sand: :smoking::coffee::smoking::coffee::smoking::coffee::smoking: :coffee: :hourglass_flowing_sand: :beer::beer::beer::pill:  :zzz::zzz: :zzz::zzz: :zzz::zzz::hourglass_flowing_sand: :smoking::coffee: :toilet: :shower: :smoking: :coffee::smoking: :coffee: :smoking: :coffee: :hourglass: 

<br>

>:bulb: Leave screen with **Ctrl + a + d**

>:bulb: Come back with **screen -r ADM**

<br>

:checkered_flag::checkered_flag::checkered_flag:

<br>

[Save your work](https://github.com/bpshparis/ocp-esx/blob/master/Install-OCP.md#Make-a-snapshot)


#### Create MCM installation directory and move to it

> :warning: Run this on Controller

```
[ ! -d ~/mcm ] && mkdir ~/mcm; cd ~/mcm
```

#### Extract the cluster directory

> :warning: Run this on Controller

```
docker run --rm -v $(pwd):/data:z -e LICENSE=accept --security-opt label:disable ibmcom/mcm-inception-amd64:3.2.3 cp -r cluster /data
```

#### Login to cluster

> :warning: Run this on Controller

```
oc login https://lb-$OCP:8443 -u admin -p admin \
--insecure-skip-tls-verify=true
```

#### Create cluster configuration files

> :warning: Run this on Controller

```
oc config view > cluster/kubeconfig
```

#### Update the installation config.yaml

##### Add worker nodes

###### Write nodes file

> :warning: Run this on Controller

```
cat > nodes.yaml << EOF
    - n1-$OCP.iicparis.fr.ibm.com
    - n2-$OCP.iicparis.fr.ibm.com
    - n3-$OCP.iicparis.fr.ibm.com
EOF
```

###### Clean config.yaml

> :warning: Run this on Controller

```
sed -i -e '/^\s\{2\}master:/, /^\s\{2\}proxy:/{//!d}'  cluster/config.yaml
sed -i -e '/^\s\{2\}proxy:/, /^\s\{2\}management:/{//!d}'  cluster/config.yaml
sed -i -e '/^\s\{2\}management:/, /^$/{//!d}' cluster/config.yaml
```

###### Add nodes to config.yaml

> :warning: Run this on Controller

```
sed -i -e '/^\s\{2\}master:/r nodes.yaml' cluster/config.yaml
sed -i -e '/^\s\{2\}proxy:/r nodes.yaml' cluster/config.yaml
sed -i -e '/^\s\{2\}management:/r nodes.yaml' cluster/config.yaml
```

##### Add Storage Class

###### Get Storage Class Name

> :warning: Run this on Controller

```
SC=$(oc get sc | awk 'NR>1 {print $1}') && echo $SC
```

###### Add Storage Class name to config.yaml

> :warning: Run this on Controller

```
sed -i -e 's/\(^storage_class: \).*$/\1'$SC'/'  cluster/config.yaml
```

##### Add default admin password

> :warning: Run this on Controller

```
PWD="admin"

sed -i -e 's/^# \(default_admin_password:\)/\1 '$PWD'/'  cluster/config.yaml
```

##### Set password rules

###### Uncomment password rules

> :warning: Run this on Controller

```
sed -i -e 's/^# \(password_rules:\)/\1/'  cluster/config.yaml

```

###### Delete password rules

> :warning: Run this on Controller

```
sed -i -e '/^password_rules:/, /^$/{//!d}' cluster/config.yaml
```

###### Add permissive rule

> :warning: Run this on Controller

```
cat > permissiveRule.yaml << EOF
  - '(.*)'
EOF

sed -i -e '/^password_rules:/r permissiveRule.yaml' cluster/config.yaml
```


### Install Cloud Pak for Multicloud Management on a Red Hat OpenShift cluster

> :warning: To avoid network failure, launch installation on locale console or in a screen

> :warning: Run this on Controller

```
[ ! -z $(command -v screen) ] && echo screen installed || yum install screen -y

screen -mdS ADM && screen -r ADM
```

> :warning: Move in cluster directory

```
cd cluster
```

```
docker run -t --net=host -e LICENSE=accept -v $(pwd):/installer/cluster:z -v /var/run:/var/run:z -v /etc/docker:/etc/docker:z --security-opt label:disable ibmcom/mcm-inception-amd64:3.2.3 install-with-openshift
```

<br>

:hourglass_flowing_sand: :smoking::coffee::smoking::coffee::smoking::coffee::smoking: :coffee: :hourglass_flowing_sand: :beer::beer::beer::pill:  :zzz::zzz: :zzz::zzz: :zzz::zzz::hourglass_flowing_sand: :smoking::coffee: :toilet: :shower: :smoking: :coffee::smoking: :coffee: :smoking: :coffee: :hourglass: 

<br>

>:bulb: Leave screen with **Ctrl + a + d**

>:bulb: Come back with **screen -r ADM**

> :bulb: If something went wrong check logs in **mcm/cluster/logs** directory.

<br>

:checkered_flag::checkered_flag::checkered_flag:

<br>

[Save your work](https://github.com/bpshparis/ocp-esx/blob/master/Install-OCP.md#Make-a-snapshot)


