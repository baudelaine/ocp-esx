#!/bin/sh
VMNAME=rhel
DATASTORE="datastore1"
DISK=root1.vmdk
SIZE=50G
SCSI="0 1"

which vim-cmd

if [ $? -ne 0 ]; then 
	echo "ERROR !!! vim-cmd not found" 
	echo "Script has to be executed on the ESXi server. Exiting..."
	exit 1
fi

VMID=$(vim-cmd vmsvc/getallvms | awk '{if (NR > 1) print $1 " " $2 }' | grep $VMNAME | awk '{print $1}')

DIR="/vmfs/volumes/$DATASTORE/$VMNAME"

if [ ! -d "$DIR" ]; then echo $DIR "does not exists" && mkdir -p $DIR/test; else echo $DIR "exists"; fi

vmkfstools -c $SIZE $DIR/$DISK

if [ -f "$DIR/$DISK" ]; then vim-cmd vmsvc/device.diskaddexisting $VMID $DIR/$DISK $SCSI; fi

exit 0
