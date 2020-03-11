#!/bin/sh

ME=${0##*/}
RED="\e[31m"
YELLOW="\e[33m"
LBLUE="\e[34m"
GREEN="\e[32m"
NC="\e[0m"

OCP=""
WEB_SRV_URL="http://172.16.160.150/$OCP"
<<<<<<< HEAD
# RAW_IMG_URL="$WEB_SRV_URL/rhcos-4.3.0-x86_64-metal.raw.gz"
RAW_IMG_URL="$WEB_SRV_URL/rhcos-4.2.18-x86_64-metal-bios.raw.gz"
=======
RAW_IMG_URL="$WEB_SRV_URL/rhcos-4.2.18-x86_64-metal-bios.raw.gz"
# RAW_IMG_URL="$WEB_SRV_URL/rhcos-4.3.0-x86_64-metal.raw.gz"
>>>>>>> 155c0ad7ce519f33a6a760dd009648ec49a8a344
DNS="172.16.160.100"
DOMAIN="iicparis.fr.ibm.com"
IF="ens192"
MASK="255.255.224.0"
GATEWAY="172.16.186.17"
ISO_PATH="/media/iso"
RW_ISO_PATH="/media/isorw"
ISO_CFG=$RW_ISO_PATH/isolinux/isolinux.cfg


VMS="bs-$OCP m1-$OCP m2-$OCP m3-$OCP w1-$OCP w2-$OCP w3-$OCP"
# VMS="bs-$OCP m1-$OCP m2-$OCP m3-$OCP w1-$OCP w2-$OCP w3-$OCP w4-$OCP w5-$OCP"
KERNEL_CMD_LINE="coreos.inst=yes"
DEVICE="sda"
NEW_KERNEL_CMD_LINE="$KERNEL_CMD_LINE coreos.inst.install_dev=$DEVICE coreos.inst.image_url=$RAW_IMG_URL"
MKISOFS_ARGS="-U -A \"RHCOS-x86_64\" -V \"RHCOS-x86_64\" -volset \"RHCOS-x86_64\" -J -joliet-long -r -v -T -x ./lost+found -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot"

[ -z $(command -v mkisofs) ] && yum install -y genisoimage || echo -e mkisofs installed

activateTimeout (){
    sed -i -e 's/^timeout.*$/timeout 100/' $ISO_CFG
    [ $(grep -c '  menu default' $ISO_CFG ) -eq 0 ] && sed -i -e '/  menu label \^Install RHEL CoreOS/a\  menu default\' $ISO_CFG
}

reloadRWIsoPath (){
    [ -d $RW_ISO_PATH ] && rm -rf $RW_ISO_PATH/* || mkdir $RW_ISO_PATH
    [ -d $ISO_PATH ] && rsync -avg --progress $ISO_PATH/ $RW_ISO_PATH
}

initNewKernelCmdLine (){
    NEW_KERNEL_CMD_LINE="$KERNEL_CMD_LINE coreos.inst.install_dev=$DEVICE coreos.inst.image_url=$RAW_IMG_URL"
}

init (){
    reloadRWIsoPath
    activateTimeout
    initNewKernelCmdLine
}

buildIso (){

for VM_NAME in $VMS; do
	echo $VM_NAME
    init
    HOST=$VM_NAME.$DOMAIN
    IP=$(dig +short $HOST)
    # IGN=$WEB_SRV_URL/$VM_NAME.ign
    # case $VM_NAME in bs-*) IGN=$WEB_SRV_URL/append-bootstrap.ign;; esac
    case $VM_NAME in bs-*) IGN=$WEB_SRV_URL/bootstrap.ign;; esac
    case $VM_NAME in m*) IGN=$WEB_SRV_URL/master.ign;; esac
    case $VM_NAME in w*) IGN=$WEB_SRV_URL/worker.ign;; esac
    NEW_KERNEL_CMD_LINE="$NEW_KERNEL_CMD_LINE coreos.inst.ignition_url=$IGN ip=$IP::$GATEWAY:$MASK:$HOST:$IF:none nameserver=$DNS"
    # echo "KERNEL_CMD_LINE="$KERNEL_CMD_LINE
    # echo "NEW_KERNEL_CMD_LINE="$NEW_KERNEL_CMD_LINE
    sed -i -e "s!$KERNEL_CMD_LINE!$NEW_KERNEL_CMD_LINE!" $ISO_CFG
    mkisofs $MKISOFS_ARGS -o $VM_NAME.iso $RW_ISO_PATH/

done

}

writeAppendBsIgn (){

cat > append-bootstrap.ign << EOF
{
"ignition": {
    "config": {
    "append": [
        {
        "source": "$WEB_SRV_URL/bootstrap.ign",
        "verification": {}
        }
    ]
    },
    "timeouts": {},
    "version": "2.1.0"
},
"networkd": {},
"passwd": {},
"storage": {},
"systemd": {}
}
EOF

}


buildIgn (){

for VM_NAME in $VMS; do
	echo $VM_NAME
    HOST=$VM_NAME.$DOMAIN
    NEW_IGN=$VM_NAME.ign
    DATA="data:,$HOST"
    FILE='{"filesystem":"root","path":"/etc/hostname","mode":420,"contents":{"source":""}}'
    FILE=$(echo $FILE | jq -c --arg DATA "$DATA" '.contents.source = $DATA')
    echo "FILE="$FILE

    case $VM_NAME in

        bs*)
            IGN="bootstrap.ign"
            [ ! -f "$IGN" ] && wget -c $WEB_SRV_URL/$IGN
            writeAppendBsIgn
            ;;

        m*)
            IGN="master.ign"
            [ ! -f "$IGN" ] && wget -c $WEB_SRV_URL/$IGN
            jq  '.storage += {files: []}' $IGN | sponge $IGN
            jq --argjson FILE "$FILE" '.storage.files += [$FILE]' $IGN > $NEW_IGN
            ;;

        w*)
            IGN="worker.ign"
            [ ! -f "$IGN" ] && wget -c $WEB_SRV_URL/$IGN
            jq  '.storage += {files: []}' $IGN | sponge $IGN
            jq --argjson FILE "$FILE" '.storage.files += [$FILE]' $IGN > $NEW_IGN
            ;;

    esac

done

}

case $1 in

	ign)
		echo "Build $OCP igns..."
        buildIgn
		;;

	iso)
		echo "Build $OCP isos..."
        buildIso
		;;

	*)
		echo "Build $OCP isos..."
        # buildIgn
        buildIso
		;;

esac

exit 0;
