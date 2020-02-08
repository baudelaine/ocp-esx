# Prepare OCP

## On Controller

#### Copy inventory file to default ansible file

> :warning: Run this on Controller

	sed 's/-ocp./-'$OCP'/g' $WORKDIR/hosts-cluster > /etc/ansible/hosts

#### Check hosts

> :warning: Run this on Controller

	grep -e 'ocp[0-9]\{1,\}' /etc/ansible/hosts


#### Extend root Volume Group on cluster nodes

> :warning: Run this on Controller

>:warning: Set **DISK**, **PART**, **VG** and **LV** variables accordingly in **$WORKDIR/extendRootLV.sh** before proceeding

	for node in m1 m2 m3 n1 i1 n2 i2 n3 i3; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; /root/extendRootLV.sh'; done

#### Check root Volume Group on cluster nodes

> :warning: Run this on Controller

	for node in m1 m2 m3 n1 i1 n2 i2 n3 i3; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; lvs'; done

#### Check ansible can speak with every nodes in the cluster

> :warning: Run this on Controller

	ansible OSEv3 -m ping

#### Set Docker storage

> :warning: Run this on Controller

```
ansible nodes -a 'systemctl stop docker'
```


```
for node in m1 m2 m3 n1 i1 n2 i2 n3 i3; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; [ -d /var/lib/docker ] && rm -rf /var/lib/docker/* || mkdir /var/lib/docker; du -h /var/lib/docker'; done
```


```
cat > setDockerStorage.sh << EOF
ansible nodes -a 'du -h /var/lib/docker'
ansible nodes -a 'pvcreate /dev/sdc'
ansible nodes -a 'vgcreate docker /dev/sdc'
ansible nodes -a 'lvcreate -n docker -l 100%VG docker'
ansible nodes -a 'mkfs.xfs -f -n ftype=1 -i size=512 -n size=8192 /dev/docker/docker'
ansible nodes -m lineinfile -a 'path=/etc/fstab line="/dev/mapper/docker-docker  /var/lib/docker  xfs defaults,noatime 1 2"'
ansible nodes -a 'mount /var/lib/docker'
ansible nodes -a 'df -hT /var/lib/docker'
ansible nodes -a 'lvs'
ansible nodes -a 'systemctl start docker'
ansible nodes -a 'systemctl is-active docker'
EOF
```


	chmod +x setDockerStorage.sh && ./setDockerStorage.sh

#### Set OCP storage

> :warning: Run this on Controller

```
for node in m1 m2 m3 n1 i1 n2 i2 n3 i3; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; [ -d /var/lib/origin ] && rm -rf /var/lib/origin/* || mkdir /var/lib/origin; du -h /var/lib/origin'; done
```


```
cat > setOCPStorage.sh << EOF
ansible nodes -a 'pvcreate /dev/sdd'
ansible nodes -a 'vgcreate origin /dev/sdd'
ansible nodes -a 'lvcreate -n origin -l 100%VG origin'
ansible nodes -a 'mkfs.xfs -f -n ftype=1 -i size=512 -n size=8192 /dev/origin/origin'
ansible nodes -m lineinfile -a 'path=/etc/fstab line="/dev/mapper/origin-origin  /var/lib/origin  xfs defaults,noatime 1 2"'
ansible nodes -a 'mount /var/lib/origin'
ansible nodes -a 'df -hT /var/lib/origin'
ansible nodes -a 'lvs'
EOF
```


	chmod +x setOCPStorage.sh && ./setOCPStorage.sh


#### Set ETCD storage

> :warning: Run this on Controller

```
for node in m1 m2 m3; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; [ -d /var/lib/etcd ] && rm -rf /var/lib/etcd/* || mkdir /var/lib/etcd; du -h /var/lib/etcd'; done
```


```
cat > setETCDStorage.sh << EOF
ansible etcd -a 'pvcreate /dev/sde'
ansible etcd -a 'vgcreate etcd /dev/sde'
ansible etcd -a 'lvcreate -n etcd -l 100%VG etcd'
ansible etcd -a 'mkfs.xfs -f -n ftype=1 -i size=512 -n size=8192 /dev/etcd/etcd'
ansible etcd -m lineinfile -a 'path=/etc/fstab line="/dev/mapper/etcd-etcd  /var/lib/etcd  xfs defaults,noatime 1 2"'
ansible etcd -a 'mount /var/lib/etcd'
ansible etcd -a 'df -hT /var/lib/etcd'
ansible etcd -a 'lvs'
EOF
```


	chmod +x setETCDStorage.sh && ./setETCDStorage.sh

#### Check nodes logical volume

> :warning: Run this on Controller

	ansible nodes -a 'lvs'

# Make a snapshot

## On Controller

> :warning: Run this on Controller

```
for node in lb m1 m2 m3 n1 i1 n2 i2 n3 i3 nfs; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; poweroff'; done
```

## On ESX

#### Check all vms are Powered off

> :warning: Run this on ESX

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.getstate " $1}' | sh

#### Make a snapshot

> :warning: Run this on ESX

	export SNAPNAME=ReadyForOCP
	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.create " $1 " '$SNAPNAME' "}' | sh

#### Check snapshot

> :warning: Run this on ESX

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.get " $1}' | sh

#### Power cluster vms on

> :warning: Run this on ESX

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh
