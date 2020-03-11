https://github.com/bpshparis/ocp-esx/blob/master/Prepare-OCP-for-Cloud-Paks.md#install-managed-nfs-storage-storage-class

oc edit sc managed-nfs-storage

metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"

oc project openshift-config

# On OCP 43 Only
oc patch configs.imageregistry.operator.openshift.io/cluster --type merge -p '{"spec":{"managementState":"Managed"}}'
# On OCP 43 Only

oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"storage":{"pvc":{"claim": ""}}}}'
oc patch configs.imageregistry.operator.openshift.io/cluster --type merge -p '{"spec":{"defaultRoute":true}}'


