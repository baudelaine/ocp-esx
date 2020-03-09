DNS=172.16.160.100
MASK=255.255.224.0
ROUTER=172.16.186.17
WEB='http:\/\/172.16.160.150\/ocp5'
DOMAIN=iicparis.fr.ibm.com

> ~/.ssh/known_hosts

cd ocpinst


sudo rm -rf master.ign worker.ign metadata.json bootstrap.ign manifests openshift auth .openshift_install.log .openshift_install_state.json
wget -c http://web/stuff/openshift-install-linux-4.2.18.tar.gz
tar xvzf openshift-install-linux-4.2.18.tar.gz
cp -v ../install-config.yaml .
./openshift-install create manifests --dir=$PWD

sed -i 's/mastersSchedulable: true/mastersSchedulable: false/' manifests/cluster-scheduler-02-config.yml
# tar -czf ../sav/manifests.tgz manifests
# tar -czf ../sav/openshift.tgz openshift

rm -f *.ign

./openshift-install create ignition-configs --dir=$PWD

sshpass -e ssh -o StrictHostKeyChecking=no root@web "rm -rf /mnt/iicbackup/produits/ocp/ocp5/ignition/bootstrap/ "
sshpass -e ssh -o StrictHostKeyChecking=no root@web "mkdir -p /mnt/iicbackup/produits/ocp/ocp5/ignition/bootstrap/ "
sshpass -e scp -o StrictHostKeyChecking=no bootstrap.ign root@web:/mnt/iicbackup/produits/ocp/ocp5/ignition/bootstrap/
sshpass -e ssh -o StrictHostKeyChecking=no root@web "chmod -R +r /mnt/iicbackup/produits/ocp/"
for ho in m1-ocp5 m2-ocp5 m3-ocp5 w1-ocp5 w2-ocp5 w3-ocp5
do
    sshpass -e ssh -o StrictHostKeyChecking=no root@web "rm -rf /mnt/iicbackup/produits/ocp/ocp5/ignition/$ho"
    sshpass -e ssh -o StrictHostKeyChecking=no root@web "mkdir -p /mnt/iicbackup/produits/ocp/ocp5/ignition/$ho"
    sshpass -e ssh -o StrictHostKeyChecking=no root@web "chmod -R +r /mnt/iicbackup/produits/ocp/"
    case $ho in m*) ori=master;; esac
    case $ho in w*) ori=worker;; esac
    echo "cat ${ori}.ign | sed 's/"storage":{}/"storage":{"files":[{"filesystem":"root","path":"\/etc\/hostname","mode":420,"contents":{"source":"data:,@@@@@"}}]}/' | sed "s/@@@@@/${ho}.${DOMAIN}/" > $ho.ign"

    cat ${ori}.ign | sed 's/"storage":{}/"storage":{"files":[{"filesystem":"root","path":"\/etc\/hostname","mode":420,"contents":{"source":"data:,@@@@@"}}]}/' | sed "s/@@@@@/${ho}.${DOMAIN}/" > $ho.ign
    sshpass -e scp -o StrictHostKeyChecking=no  $ho.ign root@web:/mnt/iicbackup/produits/ocp/ocp5/ignition/$ho/
    sshpass -e ssh -o StrictHostKeyChecking=no root@web "chmod -R +r /mnt/iicbackup/produits/ocp/"
done

rm -f *.iso
for ho in bs-ocp5_172.16.187.67 m1-ocp5_172.16.187.51 m2-ocp5_172.16.187.52 m3-ocp5_172.16.187.53 w1-ocp5_172.16.187.54 w2-ocp5_172.16.187.55 w3-ocp5_172.16.187.56
do
   mkdir mnt
   sudo mount ../rhcos-4.2.18-x86_64-installer.iso mnt/
   mkdir rhcos
   rsync -a mnt/* rhcos/
   hname=`echo $ho | awk -F_ '{ print $1}'`
   hip=`echo $ho | awk -F_ '{ print $2}'`
   cd rhcos
   if [ $hname = "bs-ocp5" ]; then
       sed -i "s/coreos.inst=yes/coreos.inst=yes ip=$hip::$ROUTER:$MASK:${hname}.${DOMAIN}:ens192:none nameserver=$DNS coreos.inst.install_dev=sda coreos.inst.image_url=${WEB}\/install\/rhcos-4.2.18-x86_64-metal-bios.raw.gz coreos.inst.ignition_url=${WEB}\/ignition\/append-bootstrap.ign/" isolinux/isolinux.cfg
   else
      sed -i "s/coreos.inst=yes/coreos.inst=yes ip=$hip::${ROUTER}:${MASK}:${hname}.${DOMAIN}:ens192:none nameserver=$DNS coreos.inst.install_dev=sda coreos.inst.image_url=${WEB}\/install\/rhcos-4.2.18-x86_64-metal-bios.raw.gz coreos.inst.ignition_url=${WEB}\/ignition\/${hname}\/${hname}.ign/" isolinux/isolinux.cfg
   fi

   sudo mkisofs -U -A "RHCOS-x86_64" -V "RHCOS-x86_64" -volset "RHCOS-x86_64" -J -joliet-long -r -v -T -x ./lost+found -o ../${hname}.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot .
   cd ..
   pwd
   rm -rf rhcos/
   sudo umount $PWD/mnt/
   rm -rf mnt
   sshpass -e ssh -o StrictHostKeyChecking=no root@ocp5 "rm /vmfs/volumes/datastore1/iso/${hname}.iso"
   sshpass -e scp -o StrictHostKeyChecking=no ${hname}.iso root@ocp5:/vmfs/volumes/datastore1/iso
done




   

