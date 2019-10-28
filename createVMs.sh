#!/bin/sh

[ "$1" != "" ] && echo || { echo "USAGE: give ocp cluster name as first parmeter e.g. ./createVM.sh ocp9. Exiting..."; exit 1; }

OCP=$1
DATASTORE_PATH="/vmfs/volumes/V7000F-Volume-10TB/$OCP"
CTL_VM="ctl-$OCP"
LB_VM="lb-$OCP"
MASTER_VM="m1-$OCP m2-$OCP m3-$OCP"
NODE_VM="n1-$OCP n2-$OCP n3-$OCP"
INFRA_VM="i1-$OCP i2-$OCP i3-$OCP"
NFS_VM="nfs-$OCP"
ROOT0_DISK="/vmfs/volumes/datastore1/vmdk/rhel.vmdk"
MASTER_VMX="/vmfs/volumes/datastore1/vmdk/master.vmx"
INFRA_VMX="/vmfs/volumes/datastore1/vmdk/infra.vmx"
NODE_VMX="/vmfs/volumes/datastore1/vmdk/node.vmx"
LB_VMX="/vmfs/volumes/datastore1/vmdk/lb.vmx"
NFS_VMX="/vmfs/volumes/datastore1/vmdk/nfs.vmx"
CTL_VMX="/vmfs/volumes/datastore1/vmdk/ctl.vmx"

createCtlVmdk (){

for VM_NAME in $CTL_VM; do
	echo $VM_NAME
	if [ $? -eq 0 ]; then
		vmkfstools -i $ROOT0_DISK $DATASTORE_PATH/$VM_NAME/root0.vmdk
		vmkfstools -c 40G $DATASTORE_PATH/$VM_NAME/root1.vmdk
	fi
done

}

createMasterVmdk (){

for VM_NAME in $MASTER_VM; do
	echo $VM_NAME
	if [ $? -eq 0 ]; then
		vmkfstools -i $ROOT0_DISK $DATASTORE_PATH/$VM_NAME/root0.vmdk
		vmkfstools -c 60G $DATASTORE_PATH/$VM_NAME/root1.vmdk
		vmkfstools -c 50G $DATASTORE_PATH/$VM_NAME/docker0.vmdk
		vmkfstools -c 10G $DATASTORE_PATH/$VM_NAME/etcd0.vmdk
	fi
done

}

createNodeVmdk (){

for VM_NAME in $NODE_VM; do
	echo $VM_NAME
	if [ $? -eq 0 ]; then
		vmkfstools -i $ROOT0_DISK $DATASTORE_PATH/$VM_NAME/root0.vmdk
		vmkfstools -c 40G $DATASTORE_PATH/$VM_NAME/root1.vmdk
		vmkfstools -c 100G $DATASTORE_PATH/$VM_NAME/docker0.vmdk
		vmkfstools -c 20G $DATASTORE_PATH/$VM_NAME/origin0.vmdk
	fi
done

}

createInfraVmdk (){

for VM_NAME in $INFRA_VM; do
	echo $VM_NAME
	if [ $? -eq 0 ]; then
		vmkfstools -i $ROOT0_DISK $DATASTORE_PATH/$VM_NAME/root0.vmdk
		vmkfstools -c 40G $DATASTORE_PATH/$VM_NAME/root1.vmdk
		vmkfstools -c 100G $DATASTORE_PATH/$VM_NAME/docker0.vmdk
		vmkfstools -c 20G $DATASTORE_PATH/$VM_NAME/origin0.vmdk
	fi
done

}

createLbVmdk (){

for VM_NAME in $LB_VM; do
	echo $VM_NAME
	if [ $? -eq 0 ]; then
		vmkfstools -i $ROOT0_DISK $DATASTORE_PATH/$VM_NAME/root0.vmdk
	fi
done

}

createNfsVmdk (){

for VM_NAME in $NFS_VM; do
	echo $VM_NAME
	if [ $? -eq 0 ]; then
		vmkfstools -i $ROOT0_DISK $DATASTORE_PATH/$VM_NAME/root0.vmdk
		vmkfstools -c 100G $DATASTORE_PATH/$VM_NAME/exports0.vmdk
	fi
done

}

createCtlVm (){

for VM_NAME in $CTL_VM; do
	echo $VM_NAME
	mkdir $DATASTORE_PATH/$VM_NAME
	cp -v $MASTER_VMX $DATASTORE_PATH/$VM_NAME/$VM_NAME.vmx
	if [ $? -eq 0 ]; then
		sed -i 's/toBeChanged/'$VM_NAME'/g' $DATASTORE_PATH/$VM_NAME/$VM_NAME.vmx
		vim-cmd solo/registervm $DATASTORE_PATH/$VM_NAME/$VM_NAME.vmx
	fi
done

}

createMasterVm (){

for VM_NAME in $MASTER_VM; do
	echo $VM_NAME
	mkdir $DATASTORE_PATH/$VM_NAME
	cp -v $MASTER_VMX $DATASTORE_PATH/$VM_NAME/$VM_NAME.vmx
	if [ $? -eq 0 ]; then
		sed -i 's/toBeChanged/'$VM_NAME'/g' $DATASTORE_PATH/$VM_NAME/$VM_NAME.vmx
		vim-cmd solo/registervm $DATASTORE_PATH/$VM_NAME/$VM_NAME.vmx
	fi
done

}

createNodeVm (){

for VM_NAME in $NODE_VM; do
	echo $VM_NAME
	mkdir $DATASTORE_PATH/$VM_NAME
	cp -v $NODE_VMX $DATASTORE_PATH/$VM_NAME/$VM_NAME.vmx
	if [ $? -eq 0 ]; then
		sed -i 's/toBeChanged/'$VM_NAME'/g' $DATASTORE_PATH/$VM_NAME/$VM_NAME.vmx
		vim-cmd solo/registervm $DATASTORE_PATH/$VM_NAME/$VM_NAME.vmx
	fi
done

}

createInfraVm (){

for VM_NAME in $INFRA_VM; do
	echo $VM_NAME
	mkdir $DATASTORE_PATH/$VM_NAME
	cp -v $INFRA_VMX $DATASTORE_PATH/$VM_NAME/$VM_NAME.vmx
	if [ $? -eq 0 ]; then
		sed -i 's/toBeChanged/'$VM_NAME'/g' $DATASTORE_PATH/$VM_NAME/$VM_NAME.vmx
		vim-cmd solo/registervm $DATASTORE_PATH/$VM_NAME/$VM_NAME.vmx
	fi
done

}

createLbVm (){

for VM_NAME in $LB_VM; do
	echo $VM_NAME
	mkdir $DATASTORE_PATH/$VM_NAME
	cp -v $LB_VMX $DATASTORE_PATH/$VM_NAME/$VM_NAME.vmx
	if [ $? -eq 0 ]; then
		sed -i 's/toBeChanged/'$VM_NAME'/g' $DATASTORE_PATH/$VM_NAME/$VM_NAME.vmx
		vim-cmd solo/registervm $DATASTORE_PATH/$VM_NAME/$VM_NAME.vmx
	fi
done

}

createNfsVm (){

for VM_NAME in $NFS_VM; do
	echo $VM_NAME
	mkdir $DATASTORE_PATH/$VM_NAME
	cp -v $NFS_VMX $DATASTORE_PATH/$VM_NAME/$VM_NAME.vmx
	if [ $? -eq 0 ]; then
		sed -i 's/toBeChanged/'$VM_NAME'/g' $DATASTORE_PATH/$VM_NAME/$VM_NAME.vmx
		vim-cmd solo/registervm $DATASTORE_PATH/$VM_NAME/$VM_NAME.vmx
	fi
done

}

registerVms (){

find  / -type f -name "[^\.]*.$OCP.vmx" -exec vim-cmd solo/registervm '{}' \;

}

addCtlVmdk (){

for VM_NAME in $CTL_VM; do
    echo $VM_NAME
	VMID=$(vim-cmd vmsvc/getallvms | awk '{if (NR > 1) print $1 " " $2 }' | grep $VM_NAME | awk '{print $1}')

	if [ ! -z "$VMID" ]; then
		vim-cmd vmsvc/device.diskaddexisting $VMID $DATASTORE_PATH/$VM_NAME/root0.vmdk 0 0
		vim-cmd vmsvc/device.diskaddexisting $VMID $DATASTORE_PATH/$VM_NAME/root1.vmdk 0 1
	fi;
done

}

addMasterVmdk (){

for VM_NAME in $MASTER_VM; do
    echo $VM_NAME
	VMID=$(vim-cmd vmsvc/getallvms | awk '{if (NR > 1) print $1 " " $2 }' | grep $VM_NAME | awk '{print $1}')

	if [ ! -z "$VMID" ]; then
		vim-cmd vmsvc/device.diskaddexisting $VMID $DATASTORE_PATH/$VM_NAME/root0.vmdk 0 0
		vim-cmd vmsvc/device.diskaddexisting $VMID $DATASTORE_PATH/$VM_NAME/root1.vmdk 0 1
		vim-cmd vmsvc/device.diskaddexisting $VMID $DATASTORE_PATH/$VM_NAME/docker0.vmdk 0 2
		vim-cmd vmsvc/device.diskaddexisting $VMID $DATASTORE_PATH/$VM_NAME/etcd0.vmdk 0 3
	fi;
done

}

addNodeVmdk (){

for VM_NAME in $NODE_VM; do
    echo $VM_NAME
	VMID=$(vim-cmd vmsvc/getallvms | awk '{if (NR > 1) print $1 " " $2 }' | grep $VM_NAME | awk '{print $1}')

	if [ ! -z "$VMID" ]; then
		vim-cmd vmsvc/device.diskaddexisting $VMID $DATASTORE_PATH/$VM_NAME/root0.vmdk 0 0
		vim-cmd vmsvc/device.diskaddexisting $VMID $DATASTORE_PATH/$VM_NAME/root1.vmdk 0 1
		vim-cmd vmsvc/device.diskaddexisting $VMID $DATASTORE_PATH/$VM_NAME/docker0.vmdk 0 2
		vim-cmd vmsvc/device.diskaddexisting $VMID $DATASTORE_PATH/$VM_NAME/origin0.vmdk 0 3
	fi;
done

}

addInfraVmdk (){

for VM_NAME in $INFRA_VM; do
    echo $VM_NAME
	VMID=$(vim-cmd vmsvc/getallvms | awk '{if (NR > 1) print $1 " " $2 }' | grep $VM_NAME | awk '{print $1}')

	if [ ! -z "$VMID" ]; then
		vim-cmd vmsvc/device.diskaddexisting $VMID $DATASTORE_PATH/$VM_NAME/root0.vmdk 0 0
		vim-cmd vmsvc/device.diskaddexisting $VMID $DATASTORE_PATH/$VM_NAME/root1.vmdk 0 1
		vim-cmd vmsvc/device.diskaddexisting $VMID $DATASTORE_PATH/$VM_NAME/docker0.vmdk 0 2
		vim-cmd vmsvc/device.diskaddexisting $VMID $DATASTORE_PATH/$VM_NAME/origin0.vmdk 0 3
	fi;
done

}

addLbVmdk (){

for VM_NAME in $LB_VM; do
    echo $VM_NAME
	VMID=$(vim-cmd vmsvc/getallvms | awk '{if (NR > 1) print $1 " " $2 }' | grep $VM_NAME | awk '{print $1}')

	if [ ! -z "$VMID" ]; then
		vim-cmd vmsvc/device.diskaddexisting $VMID $DATASTORE_PATH/$VM_NAME/root0.vmdk 0 0
	fi;
done

}

addNfsVmdk (){

for VM_NAME in $NFS_VM; do
    echo $VM_NAME
	VMID=$(vim-cmd vmsvc/getallvms | awk '{if (NR > 1) print $1 " " $2 }' | grep $VM_NAME | awk '{print $1}')

	if [ ! -z "$VMID" ]; then
		vim-cmd vmsvc/device.diskaddexisting $VMID $DATASTORE_PATH/$VM_NAME/root0.vmdk 0 0
		vim-cmd vmsvc/device.diskaddexisting $VMID $DATASTORE_PATH/$VM_NAME/exports0.vmdk 0 1
	fi;
done

}

createVm (){
	createCtlVm
	createMasterVm
	createNodeVm
	createInfraVm
	createLbVm
	createNfsVm
}

createVmdk (){
	createCtlVmdk
	createMasterVmdk
	createNodeVmdk
	createInfraVmdk
	createLbVmdk
	createNfsVmdk
}

addVmdk (){
	addCtlVmdk
	addMasterVmdk
	addNodeVmdk
	addInfraVmdk
	addLbVmdk
	addNfsVmdk
}

createVm
createVmdk
addVmdk

#createNfsVm
#createNfsVmdk
#addNfsVmdk

exit 0;
