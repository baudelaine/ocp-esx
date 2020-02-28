for ho in bs m1 m2 m3 w1 w2 w3
do
  scp -o StrictHostKeyChecking=no /etc/pki/tls/certs/ctl-ocp23.crt core@$ho-ocp23:/tmp
  ssh -o StrictHostKeyChecking=no -l core $ho-ocp23 "sudo cp /tmp/ctl-ocp23.crt /etc/pki/ca-trust/source/anchors/; update-ca-trust"
  ssh -o StrictHostKeyChecking=no -l core $ho-ocp23 "sudo mkdir /etc/containers/certs.d/ctl-ocp23.iicparis.fr.ibm.com\:5000; sudo cp /tmp/ctl-ocp23.crt /etc/containers/certs.d/ctl-ocp23.iicparis.fr.ibm.com\:5000"
done


for ho in bs m1 m2 m3 w1 w2 w3
do
  echo $ho
  ssh -o StrictHostKeyChecking=no -l core $ho-ocp23 "ls /etc/containers/certs.d/ctl-ocp23.iicparis.fr.ibm.com/"
done


Docker still complains about the certificate when using authentication?
When using authentication, some versions of Docker also require you to trust the certificate at the OS level.

UBUNTU
$ cp certs/domain.crt /usr/local/share/ca-certificates/myregistrydomain.com.crt
update-ca-certificates
RED HAT ENTERPRISE LINUX
cp certs/domain.crt /etc/pki/ca-trust/source/anchors/myregistrydomain.com.crt
update-ca-trust