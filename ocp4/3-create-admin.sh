htpasswd -c -B -b /root/users.htpasswd admin admin                     
htpasswd -b  /root/users.htpasswd user1 password
htpasswd -b  /root/users.htpasswd user2 password
htpasswd -b  /root/users.htpasswd user3 password
htpasswd -b  /root/users.htpasswd user4 password
htpasswd -b  /root/users.htpasswd user5 password
oc create secret generic htpass-secret --from-file=htpasswd=/root/users.htpasswd  -n openshift-config

oc apply -f - <<EOF
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: htpasswd_provider 
    mappingMethod: claim 
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret 
EOF

sleep 10
oc adm policy add-cluster-role-to-user cluster-admin admin

oc apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
  creationTimestamp: null
  name: thin
  ownerReferences:
  - apiVersion: v1
    kind: clusteroperator
    name: storage
  selfLink: /apis/storage.k8s.io/v1/storageclasses/thin
parameters:
  diskformat: thin
provisioner: kubernetes.io/vsphere-volume
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF
