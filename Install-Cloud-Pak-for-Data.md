# Install Cloud Pak for Data

## On Controller

### Pre-installation tasks

#### Obtain the installation file

Download part number **CC3Y1ML** either from [IBM Passport Advantage](https://www.ibm.com/software/passportadvantage/pao_customer.html) or from [XL](https://w3-03.ibm.com/software/xl/download/ticket.wss).

<!--
```
mount /mnt/iicbackup/produits
rsync  /mnt/iicbackup/produits/ISO/add-ons/icp4d/cpd/cloudpak4data-ee-v2.5.0.0.tgz ~
```
-->

#### Run installer to download cloudpak4data-ee-v2.5.0.0.tgz

> :information_source: Run this on Controller

```
chmod +x CP4D_EE_Installer_V2.5.bin && ./CP4D_EE_Installer_V2.5.bin
```

#### Untar cloudpak4data-ee-v2.5.0.0.tgz in cpd directory

> :information_source: Run this on Controller

```
mkdir cpd && cd cpd && tar xvzf ../cloudpak4data-ee-v2.5.0.0.tgz
```

#### Get entitlement key

Get the key from [My IBM](https://myibm.ibm.com/products-services/containerlibrary)

#### Save the apikey and username

> :information_source: Run this on Controller

```
export USERNAME="cp"
export APIKEY="myEntitlementKey"
```

#### Test your entitlement key against cp.icr.io registry

> :information_source: Run this on Controller

```
docker login -u $USERNAME -p $APIKEY cp.icr.io
```

##### Try to pull something

> :information_source: Run this on Controller

```
docker pull cp.icr.io/cp/cpd/zen-meta-couchdb:v2.5.0.0-210
```

> :warning: If pull failed with **repository cp.icr.io/cp/cpd/zen-meta-couchdb not found: does not exist or no pull access** then connect to IBM intranet and get username and apikey this way :

> :information_source: Run this on Controller with **IBM intranet connection**

>```
>USERNAME=$(curl http://icpfs1.svl.ibm.com/zen/cp4d-builds/2.5.0.0/production/internal/repo.yaml | awk -F ": " ' $1 ~ "username" {print $2}') && echo $USERNAME
>```
> :bulb: username should be something like **iamapikey**

>```
>APIKEY=$(curl http://icpfs1.svl.ibm.com/zen/cp4d-builds/2.5.0.0/production/internal/repo.yaml | awk -F ": " ' $1 ~ "apikey" {print $2}') && echo $APIKEY
>```

#### Add username and apikey to repo.yaml

> :information_source: Run this on Controller

```
sed -i -e 's/\(^\s\{4\}username: \).*$/\1'$USERNAME'/' repo.yaml

sed -i -e 's/\(^\s\{4\}apikey: \).*$/\1'$APIKEY'/' repo.yaml
```

### Setting up your Cloud Pak for Data environment

#### Log in cluster

> :information_source: Run this on Controller

```
oc login https://lb-$OCP:8443 -u admin -p admin --insecure-skip-tls-verify=true
```

#### Set Cloud Pak for Data project name

> :information_source: Run this on Controller

	export PROJECT="cpd"

#### Preview the list of resources that must be created on the cluster

##### Dry run

> :information_source: Run this on Controller

```
chmod +x bin/cpd-linux
bin/cpd-linux adm --repo repo.yaml --assembly lite --namespace $PROJECT
```

##### Apply

> :information_source: Run this on Controller

```
bin/cpd-linux adm --repo repo.yaml --assembly lite --namespace $PROJECT --apply
```

#### Grant cpd-admin-role to the project administration user

> :information_source: Run this on Controller

```
export PROJECT_ADMIN="admin"

oc adm policy add-role-to-user cpd-admin-role $PROJECT_ADMIN --role-namespace=$PROJECT -n $PROJECT
```

### Install Cloud Pak for Data on a Redhat OpenShift cluster

> :warning: To avoid network failure, launch installation on locale console or in a screen

> :information_source: Run this on Controller

```
[ ! -z $(command -v screen) ] && echo screen installed || yum install screen -y

pkill screen; screen -mdS ADM && screen -r ADM
```

```
bin/cpd-linux \
--repo ./repo.yaml \
--assembly lite \
--namespace $PROJECT \
--storageclass managed-nfs-storage \
--transfer-image-to docker-registry-default.apps.$OCP.iicparis.fr.ibm.com/$PROJECT \
--target-registry-password $(oc whoami -t) \
--target-registry-username $(oc whoami) \
--cluster-pull-prefix docker-registry.default.svc:5000/$PROJECT
```

<br>

:hourglass_flowing_sand: :smoking::coffee::smoking::coffee::smoking::coffee::smoking: :coffee: :hourglass_flowing_sand: :beer::beer::beer::pill:  :zzz::zzz: :zzz::zzz: :zzz::zzz::hourglass_flowing_sand: :smoking::coffee: :toilet: :shower: :smoking: :coffee::smoking: :coffee: :smoking: :coffee: :hourglass: 

<br>

>:bulb: Leave screen with **Ctrl + a + d**

>:bulb: Come back with **screen -r ADM**

> :bulb: If something went wrong check logs in **~/cpd/bin/cpd-linux-workspace/Logs/** directory and revert to [last snapshot](https://github.com/bpshparis/ocp-esx/blob/master/Install-OCP.md#If-necessary-revert-to-last-snapshot).

<br>

:checkered_flag::checkered_flag::checkered_flag:

<br>

[Save your work](https://github.com/bpshparis/ocp-esx/blob/master/Install-OCP.md#Make-a-snapshot)

<!-- 

PROJECT="cpd"

oc login https://lb-$OCP:8443 -u admin -p admin --insecure-skip-tls-verify=true -n $PROJECT

docker login -u $(oc whoami) -p $(oc whoami -t) docker-registry-default.apps.$OCP.iicparis.fr.ibm.com 

https://blog.openshift.com/getting-started-helm-openshift/


curl -LO https://get.helm.sh/helm-v2.14.3-linux-amd64.tar.gz 

tar xvzf helm-v2.14.3-linux-amd64.tar.gz -C $(echo $PATH | cut -d':' -f1)

:bulb: Toggle label
oc label node w1-ocp1.iicparis.fr.ibm.com node-role.kubernetes.io/worker=true
oc label node w1-ocp1.iicparis.fr.ibm.com node-role.kubernetes.io/worker-

REG=$(oc get routes -n default | awk '$1 ~ "registry-console" {print $2}')

cd ~/cpd/charts/ibm-watson-assistant-prod/ibm_cloud_pak/pak_extensions/pre-install/clusterAdministration
./loadImagesOpenShift.sh --path ~/cpd --namespace $PROJECT --registry $REG


# Considerations for DEV clusters having less then 5 nodes.
#    In such a case you have to provide the list of 5 nodes as a parameter, but you can specify a node multiple times in the list.
#      e.g., --nodeAffinities node1,node2,node1,node2
#    Notice that for such a cluster you have to set --values global.podAntiAffinity=Disable

./createLocalVolumePV.sh --release my-141-wa --path /mnt/local-storage/storage/watson/assistant --nodeAffinities w1-ocp1.iicparis.fr.ibm.com,w2-ocp1.iicparis.fr.ibm.com,w3-ocp1.iicparis.fr.ibm.com,w1-ocp1.iicparis.fr.ibm.com,w2-ocp1.iicparis.fr.ibm.com,w3-ocp1.iicparis.fr.ibm.com 

kubectl get persistentvolumes -l release=my-141-wa --show-labels

./labelNamespace.sh $PROJECT


cd ~/cpd

oc login https://lb-$OCP:8443 -u admin -p admin --insecure-skip-tls-verify=true -n $PROJECT

docker login -u $(oc whoami) -p $(oc whoami -t) docker-registry-default.apps.$OCP.iicparis.fr.ibm.com 

oc adm policy add-scc-to-group restricted system:serviceaccounts:$PROJECT

export TILLER_NAMESPACE=$PROJECT

oc get secret helm-secret -n $TILLER_NAMESPACE -o yaml|grep -A3 '^data:'|tail -3 | awk -F: '{system("echo "$2" |base64 --decode > "$1)}'
export HELM_TLS_CA_CERT=$PWD/ca.cert.pem
export HELM_TLS_CERT=$PWD/helm.cert.pem
export HELM_TLS_KEY=$PWD/helm.key.pem
helm version  --tls

vi ~/cpd/charts/ibm-watson-assistant-prod/values-override.yaml

'{"global":{"podAntiAffinity":"Disable"}}'

INT_REG=$(oc -n default get dc docker-registry -o jsonpath='{.spec.template.spec.containers[].env[?(@.name=="REGISTRY_OPENSHIFT_SERVER_ADDR")].value}{"\n"}')
'{"global": "image":{{"repository":"$INT_REG"}}}'

'{"global": "icp":{{"proxyHostname":""}}}'

'{"global":{"languages":{"french":true}}}'

'{"global":{"zenNamespace":"$PROJECT"}}'

'{"global":{"license":"accept"}}'


sshpass -e scp -o StrictHostKeyChecking=no ~/cpd/charts/ibm-watson-assistant-prod/values-override.yaml root@web:/mnt/iicbackup/produits/ocp/$OCP/wa-values-override.yaml

sshpass -e ssh -o StrictHostKeyChecking=no root@web "chmod -R +r /mnt/iicbackup/produits/ocp"


cd ~/cpd

oc get secrets | grep default-dockercfg

helm install charts/ibm-watson-assistant-prod --tls --set master.slad.dockerRegistryPullSecret=default-dockercfg-76hk2 --values charts/ibm-watson-assistant-prod/values-override.yaml --namespace cpd --name my-141-wa --values charts/ibm-watson-assistant-prod/ibm_cloud_pak/pak_extensions/pre-install/clusterAdministration/wa-persistence.yaml --tiller-namespace cpd

watch kubectl get job,pod,svc,secret,cm,pvc --namespace cpd

helm status --tls my-141-wa --tiller-namespace cpd


NOTES:

If IBM Watson Assistant in IBM Cloud Pak for Data was successfully installed:

Create a Watson Assistant instance at the following CP4D web UI (typically at https://cpd-cpd-cpd.apps./zen/#/addons
   Select the "Watson Assistant" Add-on.
   Click "Provision Instance".
   Give the instance a name and click "Create".

To find API URL and token:
   Go to CP4D web UI (typically at https://cpd-cpd-cpd.apps./zen/#/myInstances ).
   Select "My Instances" from the [=] Navigation Menu, if not in the "My Instances" page.
   Select "View details" from the "..." menu for the Watson Assistant instance.
   Find the URL and "Bearer token" in "Connection details".
   Set TOKEN variable same as "Bearer token".
   Set API_URL variable same as Url.

To list workspaces:
   curl $API_URL/v1/workspaces?version=2018-09-20 -H "Authorization: Bearer $TOKEN" -k

To access tooling (UI):
   Select "View Details" from the "..." menu for the Watson Assistant instance: https://cpd-cpd-cpd.apps./zen/#/myInstances
   Click "Open Watson Assistant".


Note: The syntax of the URL for the IBM Cloud Pak for Data user interface has changed with V2.5. If you are using an older version of IBM Cloud Pak for Data, check for the appropriate URL syntax and use that in place of https://cpd-cpd-cpd.apps..


-->
