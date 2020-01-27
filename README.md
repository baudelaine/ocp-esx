## Table of Contents

- [Prerequisites](#prerequisites)
- [Target](#target)
- [Build cluster](https://github.com/bpshparis/ocp-esx/blob/master/Build-Cluster.md)
- [Prepare OCP](https://github.com/bpshparis/ocp-esx/blob/master/Prepare-OCP.md)
- [Install OCP](https://github.com/bpshparis/ocp-esx/blob/master/Install-OCP.md)
- [Prepare OCP for Cloud Paks](https://github.com/bpshparis/ocp-esx/blob/master/Prepare-OCP-for-Cloud-Paks.md)
- [Install Cloud Pak for Data](https://github.com/bpshparis/ocp-esx/blob/master/Install-Cloud-Pak-for-Data.md)
- [Install Cloud Pak for Applications](https://github.com/bpshparis/ocp-esx/blob/master/Install-Cloud-Pak-for-Applications.md)
- [Install Cloud Pak for Multicloud Management](https://github.com/bpshparis/ocp-esx/blob/master/Install-Cloud-Pak-for-Multicloud-Management.md)
- [Install RHEL GUI](https://github.com/bpshparis/ocp-esx/blob/master/Install-RHEL-GUI.md)


# Prerequisites

Be a [Redhat partner](https://partnercenter.redhat.com/Dashboard_page) and ask for [NEW NFR](https://partnercenter.redhat.com/NFR_Redirect) to get access to Openshift packages.

One **ESXi server** in which datastore you should have copied:

- A vmdk file which host  a [minimal](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/chap-simple-install#sect-simple-install) and  [prepared](https://docs.openshift.com/container-platform/3.11/install/host_preparation.html) RHEL7 **booting in DHCP** and **running VMware Tools**. 
- A [bundle](https://github.com/bpshparis/ocp-esx/archive/master.zip)  of scripts and configurations files.

One **DNS server**.

One **DHCP server**.



<!--

#awk '/!container-selinux/{if (NR!=1)print "";next}{printf "%s ",$0}END{print "";}' b

yum install atomic -y

yum install container-selinux container-storage-setup containers-common criu gomtree libnet ostree protobuf-c python-docker python-docker-pycreds python-requests python-websocket-client python2-pysocks python2-urllib3 runc skopeo -y

yum install atomic-openshift atomic-openshift-clients atomic-openshift-hyperkube atomic-openshift-node bind ceph-common dnsmasq flannel iscsi-initiator-utils pyparted atomic-openshift:3.11 atomic-openshift-master:3.11 atomic-openshift-node:3.11 -y



yum install ose-control-plane ose-deployer ose-docker-registry ose-haproxy-router ose-pod registry-console etcd -y



yum install atomic-openshift-excluder atomic-openshift-docker-excluder -y



echo "OPTIONS='--insecure-registry=172.30.0.0/16 --selinux-enabled --log-opt max-size=1M --log-opt max-file=3'" >> 	/etc/sysconfig/docker 



cat >> /etc/sysctl.conf << EOF

net.ipv4.ip_local_port_range = 2048 65000
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.wmem_max = 33554432
net.core.rmem_max = 33554432
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_rmem = 4096 16777216 33554432
net.ipv4.tcp_wmem = 4096 16777216 33554432
net.core.optmem_max = 40960
vm.max_map_count=262144
kernel.sem = 250 1024000 32 4096

EOF

sysctl -p



swapoff -a && sed -i '/ swap / s/^/#/' /etc/fstab



-->

# Target 


> Target is to bluid an Openshift cluster that we'll call **ocp3**



| Hostname                     | IP Address    | Role                 |
| ---------------------------- | ------------- | -------------------- |
| lb-ocp3.iicparis.fr.ibm.com  | 172.16.187.30 | Load Balancer        |
| m1-ocp3.iicparis.fr.ibm.com  | 172.16.187.31 | Master + etcd        |
| m2-ocp3.iicparis.fr.ibm.com  | 172.16.187.32 | Master + etcd        |
| m3-ocp3.iicparis.fr.ibm.com  | 172.16.187.33 | Master + etcd        |
| n1-ocp3.iicparis.fr.ibm.com  | 172.16.187.34 | Computer             |
| i1-ocp3.iicparis.fr.ibm.com  | 172.16.187.35 | Infra                |
| n2-ocp3.iicparis.fr.ibm.com  | 172.16.187.36 | Computer             |
| i2-ocp3.iicparis.fr.ibm.com  | 172.16.187.37 | Infra                |
| n3-ocp3.iicparis.fr.ibm.com  | 172.16.187.38 | Computer             |
| i3-ocp3.iicparis.fr.ibm.com  | 172.16.187.39 | Infra                |
| nfs-ocp3.iicparis.fr.ibm.com | 172.16.187.48 | Persistent Storage   |
| ctl-ocp3.iicparis.fr.ibm.com | 172.16.187.49 | Controller + ansible |


<!--




vim-cmd vmsvc/getallvms | awk '$2 ~ "-ocp" {print "vim-cmd vmsvc/power.shutdown " $1}' | sh

vim-cmd vmsvc/getallvms | awk '$2 ~ "-ocp" {print "vim-cmd vmsvc/power.off " $1}' | sh

vim-cmd vmsvc/getallvms | awk '$2 ~"-ocp" {print "vim-cmd vmsvc/snapshot.create " $1 " ocpPrereqCompleted"}' | sh

vim-cmd vmsvc/getallvms | awk '$2 ~"-ocp" {print "vim-cmd vmsvc/snapshot.create " $1 " beforeOcpPrereq"}' | sh


vim-cmd vmsvc/getallvms | awk '$2 ~"-ocp" {print "vim-cmd vmsvc/snapshot.get " $1 }' | sh

SNAPID=1

vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.off " $1}' | sh
#vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.remove " $1 " " '$SNAPID'}' | sh
vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.revert " $1 " " '$SNAPID' " suppressPowerOn" }' | sh
vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh



Please see https://ibm-cp-applications.apps.ocp76.iicparis.fr.ibm.com to get started and learn more about IBM Cloud Pak for Applications.

The Tekton Dashboard is available at: https://tekton-dashboard-kabanero.apps.ocp76.iicparis.fr.ibm.com.

The IBM Transformation Advisor UI is available at: https://ta.apps.apps.ocp76.iicparis.fr.ibm.com.




export IP_HEAD=172.16.187. && for i in $(seq 50 61); do sshpass -e ssh root@$IP_HEAD$i 'hostname -f; date'; done


for node in ocp5-i1 ocp5-i2; do echo $node; ssh $node 'shutdown -h now'; done

export IP_HEAD=172.16.187.5
#yum install -y sshpass
export SSHPASS=spcspc

for i in $(seq 0 7); do sshpass -e ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$IP_HEAD$i; done

for i in $(seq 0 7); do export SSHPASS=spcspc && export IP_HEAD=172.16.187.5 && echo $IP_HEAD$i; ssh root@$IP_HEAD$i 'hostname -f; date'; echo; done

cd /usr/share/ansible/openshift-ansible
ansible-playbook -i /etc/ansible/hosts playbooks/prerequisites.yml
ansible-playbook -i /etc/ansible/hosts playbooks/deploy_cluster.yml

oc login -u system:admin

oc get nodes


dig +short docker-registry.default.svc.cluster.local

docker login -u $(oc whoami) -p $(oc whoami -t) docker-registry.default.svc.cluster.local:5000

docker login -u $(oc whoami) -p $(oc whoami -t) 172.30.50.52:5000

oc create secret generic dockerhub --from-file=.dockerconfigjson=/root/.docker/config.json> --type=kubernetes.io/dockerconfigjson

oc delete pod --all -n openshift-web-console

oc delete pod --all -n openshift-console

https://docs.openshift.com/container-platform/3.11/getting_started/configure_openshift.html#getting-started-configure-openshift

https://docs.okd.io/latest/minishift/getting-started/quickstart.html

https://docs.openshift.com/container-platform/3.11/install_config/registry/securing_and_exposing_registry.html#exposing-the-registry



https://docs.openshift.com/container-platform/3.11/install_config/registry/securing_and_exposing_registry.html#exposing-the-registry

-->

<!--
# Annexes

## On Controller

#### Create key pair and exchange public key between cluster vms

> PermitUserEnvironment must enabled in target /etc/ssh/sshd_config

	for i in $(seq $FIRST_IP_TAIL $LAST_IP_TAIL); do ssh root@$IP_HEAD$i 'hostname -f; sed -i "s/^#PermitUserEnvironment no/PermitUserEnvironment yes/g" /etc/ssh/sshd_config; systemctl restart sshd'; done


:warning: Set **FIRST** and **LAST** variables acordingly

```
cat > ssh-env << EOF
SSHPASS=spcspc
IP_HEAD=172.16.187.
FIRST=30
LAST=39
EOF
```


```
for i in $(seq $FIRST_IP_TAIL $LAST_IP_TAIL); do scp ssh-env root@$IP_HEAD$i:/root/.ssh/environment; done
```


```
for i in $(seq $FIRST_IP_TAIL $LAST_IP_TAIL); do ssh root@$IP_HEAD$i 'hostname -f; yes y | ssh-keygen -b 4096 -f ~/.ssh/id_rsa -N "" && for i in $(seq $FIRST $LAST); do sshpass -e ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$IP_HEAD$i; done'; done
```

#### Check all vm can access each other without being prompt for a password

	for i in $(seq $FIRST_IP_TAIL $LAST_IP_TAIL); do ssh root@$IP_HEAD$i 'hostname -f; for i in $(seq $FIRST $LAST); do ssh -o StrictHostKeyChecking=no root@$IP_HEAD$i "hostname -f; date"; done'; done


```

```

```

```
-->

```

```

```

```
