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

REG=$(oc get routes -n default | awk '$1 ~ "docker-registry" {print $2}')

docker login -u $(oc whoami) -p $(oc whoami -t) $REG

https://blog.openshift.com/getting-started-helm-openshift/


curl -LO https://get.helm.sh/helm-v2.14.3-linux-amd64.tar.gz 

tar xvzf helm-v2.14.3-linux-amd64.tar.gz -C $(echo $PATH | cut -d':' -f1)

:bulb: Toggle label
oc label node w1-ocp1.iicparis.fr.ibm.com node-role.kubernetes.io/worker=true
oc label node w1-ocp1.iicparis.fr.ibm.com node-role.kubernetes.io/worker-


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

cp -v ~/cpd/charts/ibm-watson-assistant-prod/values.yaml ~/cpd/charts/ibm-watson-assistant-prod/values-override.yaml 

vi ~/cpd/charts/ibm-watson-assistant-prod/values-override.yaml

'{"global":{"podAntiAffinity":"Disable"}}'

INT_REG=$(oc -n default get dc docker-registry -o jsonpath='{.spec.template.spec.containers[].env[?(@.name=="REGISTRY_OPENSHIFT_SERVER_ADDR")].value}{"\n"}')
'{"global": "image":{{"repository":"$INT_REG"}}}'

'{"global": "icp":{{"proxyHostname":""}}}'

'{"global":{"languages":{"french":true}}}'

'{"global":{"zenNamespace":"$PROJECT"}}'

'{"global":{"license":"accept"}}'


sshpass -e scp -o StrictHostKeyChecking=no ~/cpd/charts/ibm-watson-assistant-prod/values-override.yaml root@web:/mnt/iicbackup/produits/ocp/$OCP/wa-values-override.yaml

sshpass -e ssh -o StrictHostKeyChecking=no root@web "chmod -R +r /mnt/iicbackup/produits/web"


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

// Test Assistant
// !!! Need jq commands installed to run

URL="https://cpd-cpd-cpd.apps.ocp1.iicparis.fr.ibm.com/assistant/my-141-wa/instances/1584555597793/api"
BEARER="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFkbWluIiwic3ViIjoiYWRtaW4iLCJpc3MiOiJLTk9YU1NPIiwiYXVkIjoiRFNYIiwicm9sZSI6IkFkbWluIiwicGVybWlzc2lvbnMiOltdLCJ1aWQiOiIxMDAwMzMwOTk5IiwiaWF0IjoxNTg0OTY0ODUzfQ.E0JLYWpp_PdANbEz19g3BJddDnpwYvkEJ0txALJrJ-BSfzh4vw5FqNhtC5n_j-0TphyRKKDjdoaYqW71X6NjF1fXIw0zSZMp46MQmMJaw6vJJlHueDNLrAB5kTOwvgYI9A_fxyqIGmk1Y8SnWGbi2moSFQ4MZHqNhDJMKYdBM6JevGAkku4nIy6JDIrdPPWlIGRAEHNQYx0nvOeUEcbNitT7qMG0nP4ActguTK3ZKHyS7XLDYeqKnvjOfbiZu3EL0EGXjXQqQwQuqBNMDWTUwgDKKIvGsAvFe_HX3VzOf7y7w6drix3L7cIBTs8Sb5NIsAFr8Ezhiky8qnA2UQ888g"

VERSION="2019-02-28"

// Test Assistant V1

SKILL_ID="6a570077-a4c7-41bf-bb74-789c3752b6a5"

MESSAGE="blablabla."
FILE="message.json"

cat > $FILE << EOF
{
	"input":{
		"text": "$MESSAGE"
	}
}
EOF

jq . $FILE

OUTPUT=$(curl -k -H "Authorization: Bearer $BEARER" -X POST -H 'Content-Type:application/json' -d @$FILE $URL/v1/workspaces/$SKILL_ID/message?version=$VERSION)
CONTEXT=$(echo $OUTPUT | jq -c .context)
echo $OUTPUT | jq .

cat > $FILE << EOF
{
	"input":{
		"text": "$MESSAGE"
	},
	"context": $CONTEXT
}
EOF
jq . $FILE

OUTPUT=$(curl -k -H "Authorization: Bearer $BEARER" -X POST -H 'Content-Type:application/json' -d @$FILE $URL/v1/workspaces/$SKILL_ID/message?version=$VERSION)
CONTEXT=$(echo $OUTPUT | jq -c .context)
echo $OUTPUT | jq .

// Test Assistant V2

ASSISTANT_ID="9ca183ff-8c84-4353-b8c4-a9e89b6f9f8b"

SESSION_ID=$(curl -k -H "Authorization: Bearer $BEARER" -X POST $URL/v2/assistants/$ASSISTANT_ID/sessions?version=$VERSION | jq -r .session_id) && echo $SESSION_ID

MESSAGE="blablabla."
FILE="message"
cat > $FILE << EOF
{
	"input":{
		"text": "$MESSAGE",
        "options":{
            "debug": true,
            "return_context": true
        }
	}
}
EOF
jq . $FILE

curl -k -H "Authorization: Bearer $BEARER" -X POST -H 'Content-Type:application/json' -d @$FILE $URL/v2/assistants/$ASSISTANT_ID/sessions/$SESSION_ID/message?version=$VERSION | jq .




### Speech

https://blog.openshift.com/getting-started-helm-openshift/

wget -c http://web/soft/helm-v2.9.0-linux-amd64.tar.gz


#### install tiller 2.9.0

oc login https://lb-$OCP:8443 -u admin -p admin --insecure-skip-tls-verify=true

oc new-project tiller

export TILLER_NAMESPACE=tiller

helm init --client-only

oc process -f  http://web/soft/tiller-template.yaml -p TILLER_NAMESPACE="${TILLER_NAMESPACE}" -p HELM_VERSION=v2.9.0 | oc create -f -

oc rollout status deployment tiller

helm version

Client: &version.Version{SemVer:"v2.9.0", GitCommit:"f6025bb9ee7daf9fee0026541c90a6f557a3e0bc", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.9.0", GitCommit:"f6025bb9ee7daf9fee0026541c90a6f557a3e0bc", GitTreeState:"clean"}


PROJECT="cpd"

oc login https://lb-$OCP:8443 -u admin -p admin --insecure-skip-tls-verify=true -n $PROJECT

REG=$(oc get routes -n default | awk '$1 ~ "docker-registry" {print $2}')

docker login -u $(oc whoami) -p $(oc whoami -t) $REG 


cd ~/cpd

oc project $PROJECT

wget -c http://web/cloud-pak/ibm-watson-speech-prod-1.1.1.tar.gz
tar xvzf ibm-watson-speech-prod-1.1.1.tar.gz 
http://web/cloud-pak/ibm-watson-speech-pack-prod-1.1.1.tar.gz
tar xvzf ibm-watson-speech-pack-prod-1.1.1.tar.gz

cd charts/
tar xvzf ibm-watson-speech-prod-1.1.3.tgz 
cd ~/cpd/charts/ibm-watson-speech-prod/ibm_cloud_pak/pak_extensions/pre-install/clusterAdministration
chmod +x loadImagesOpenShift.sh 

// Check space in cluster registry
//oc get pods -n default | awk '$1 ~ "docker-registry" {print "oc exec -it " $1 " bash -n default"}'

./loadImagesOpenShift.sh --path ~/cpd --namespace $PROJECT --registry $REG


docker images | grep es-es
docker push docker-registry-default.apps.ocp1.iicparis.fr.ibm.com/cpd/es-es-broadbandmodel:2019-12-16---00-01-04-master-360
docker push docker-registry-default.apps.ocp1.iicparis.fr.ibm.com/cpd/es-es-narrowbandmodel:2019-12-16---00-01-04-master-360
docker push docker-registry-default.apps.ocp1.iicparis.fr.ibm.com/cpd/es-es-laurav3voice:2019-12-16---00-01-04-master-360
docker push docker-registry-default.apps.ocp1.iicparis.fr.ibm.com/cpd/es-es-enriquev3voice:2019-12-16---00-01-04-master-360

docker images | grep fr-fr
docker push docker-registry-default.apps.ocp1.iicparis.fr.ibm.com/cpd/fr-fr-broadbandmodel:2019-12-16---00-01-04-master-360
docker push docker-registry-default.apps.ocp1.iicparis.fr.ibm.com/cpd/fr-fr-narrowbandmodel:2019-12-16---00-01-04-master-360
docker push docker-registry-default.apps.ocp1.iicparis.fr.ibm.com/cpd/fr-fr-reneev3voice:2019-12-16---00-01-04-master-360



cd ~/cpd/charts/ibm-watson-speech-prod/ibm_cloud_pak/pak_extensions/pre-install/clusterAdministration
chmod +x createLocalPVs.sh
./createLocalPVs.sh -l node-role.kubernetes.io/compute

oc get pv -n cpd

./labelNamespace.sh $PROJECT

oc apply -f - << EOF
apiVersion: v1
kind: Secret
metadata:
  name: minio
type: Opaque
data:
  accesskey: YWRtaW4=
  secretkey: cGFzc3dvcmQ=
EOF

oc apply -f - << EOF
apiVersion: v1
data:
  pg_repl_password: YWRtaW4=
  pg_su_password: cGFzc3dvcmQ=
kind: Secret
metadata:
  name: user-provided-postgressql # this name can be anything you choose
type: Opaque
EOF

vi ~/cpd/charts/ibm-watson-speech-prod/values.yaml

INT_REG=$(oc -n default get dc docker-registry -o jsonpath='{.spec.template.spec.containers[].env[?(@.name=="REGISTRY_OPENSHIFT_SERVER_ADDR")].value}{"\n"}') && echo $INT_REG
'{"global":{"icpDockerRepo":"$INT_REG/$PROJECT"}}'

SECRET=$(oc get secrets | grep default-dockercfg | awk '{print $1}') && echo $SECRET
'{"global":{"imagePullSecretName":"$SECRET"}}'

'{"global":"image":{"repository":"$INT_REG/$PROJECT"}}}'
'{"global":"image":{"pullSecret":"$SECRET"}}}'


cd ~/cpd/charts/ibm-watson-speech-prod
cp -v values.yaml values-copy.yaml

PROJECT="cpd"
INT_REG=$(oc -n default get dc docker-registry -o jsonpath='{.spec.template.spec.containers[].env[?(@.name=="REGISTRY_OPENSHIFT_SERVER_ADDR")].value}{"\n"}') && echo $INT_REG
SECRET=$(oc get secrets | grep default-dockercfg | awk '{print $1}') && echo $SECRET

sed -i -e "s/\(^    zenNamespace:\) zen$/\1 $PROJECT/g"  values.yaml
grep -e '^    zenNamespace:'  values.yaml

sed -i -e "s;\(^    icpDockerRepo:\) image-registry.openshift-image-registry.svc:5000/zen$;\1 $INT_REG\/$PROJECT;g"  values.yaml
grep -e '^    icpDockerRepo:'  values.yaml

sed -i -e "s;\(^      repository:\) image-registry.openshift-image-registry.svc:5000/zen$;\1 $INT_REG/$PROJECT;g"  values.yaml
grep -e '^      repository:'  values.yaml

SECRET=$(oc get secrets | grep default-dockercfg | awk '{print $1}') && echo $SECRET

sed -i -e "s/\(^      pullSecret:\) default-dockercfg-wtpn2$/\1 $SECRET/g"  values.yaml
grep -e '^      pullSecret:'  values.yaml

sed -i -e "s/\(^    imagePullSecretName:\) default-dockercfg-wtpn2$/\1 $SECRET/g"  values.yaml
grep -e '^    imagePullSecretName:'  values.yaml

grep -e 'storageClass'  values.yaml


screen -mdS ADM && screen -r ADM

PROJECT="cpd"

oc login https://lb-$OCP:8443 -u admin -p admin --insecure-skip-tls-verify=true -n $PROJECT

REG=$(oc get routes -n default | awk '$1 ~ "docker-registry" {print $2}') && echo $REG

docker login -u $(oc whoami) -p $(oc whoami -t) $REG

cd ~/cpd


helm install charts/ibm-watson-speech-prod --namespace $PROJECT --name my-111-speech --tiller-namespace $PROJECT --tls

watch kubectl get job,pod,svc,secret,cm,pvc --namespace cpd
watch kubectl get pod,job,svc,secret,cm,pvc --namespace cpd

helm status --tls my-111-speech --tiller-namespace $PROJECT

helm del --purge my-111-speech --tiller-namespace $PROJECT

oc delete role my-111-speech-speech-to-text-gw-role

// Test STT
// !!! Need jq and tee commands to run

BEARER="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFkbWluIiwic3ViIjoiYWRtaW4iLCJpc3MiOiJLTk9YU1NPIiwiYXVkIjoiRFNYIiwicm9sZSI6IkFkbWluIiwicGVybWlzc2lvbnMiOltdLCJ1aWQiOiIxMDAwMzMwOTk5IiwiaWF0IjoxNTg0OTA4NDIyfQ.w40DIWPDsoywkeO1YMUE0Q37GOa9GDSG-LGyG5pVSmzbWdX6eQtygaT_S7VVMiGmJJXZvf6t7LaFl1aS48Fn05WzXe1K42neKFvhD1Gzt0ILDAW0TjO2GSHaewYmKUIH3sUEWagw3gC3LMbtAqDWBuf3JRH3wXJ95dqdY83YWWiW2VmZHodjQilJRYybAi1khau8tjX1R2aTz8HfRBSxy673E-6aTCfr6vWBOVyMkfXtM89jBE3aStzKeVEs1jcv3O_t23EgGbm4n6tWNLKr_ZTz-TkIPWeSxehhnIqc5x5ZBZSk7Lrglp5XWjdfxpWHOIzy0iEs_3TQmnYTeCQZLA"
URL="https://cpd-cpd-cpd.apps.ocp1.iicparis.fr.ibm.com/speech-to-text/my-111-speech/instances/1584904929592/api"
METHOD="/v1/recognize"

MODEL="es-ES_BroadbandModel"
SOUND="es.mp3"
RESP="stt-es.json"
curl -k -X POST -H "Authorization: Bearer $BEARER" --header 'Content-Type: audio/mp3' --header 'Transfer-Encoding: chunked' --data-binary @${SOUND} ${URL}${METHOD}'?model='${MODEL} | tee $RESP

TRANSCRIPT=$(jq -c -r '[.results[].alternatives[].transcript | rtrimstr(" ")] | join(". ")' $RESP) && echo $TRANSCRIPT

// Test TTS
// !!! Need jq and sponge commands to run

REQ="tts-es.json"

cat > $REQ << EOF
{
  "text": ""
}
EOF

jq --arg NEWTEXT "${TRANSCRIPT}." '.text = $NEWTEXT' $REQ | sponge $REQ
jq . $REQ

BEARER="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFkbWluIiwic3ViIjoiYWRtaW4iLCJpc3MiOiJLTk9YU1NPIiwiYXVkIjoiRFNYIiwicm9sZSI6IkFkbWluIiwicGVybWlzc2lvbnMiOltdLCJ1aWQiOiIxMDAwMzMwOTk5IiwiaWF0IjoxNTg0OTYyNjEyfQ.szuHNVjzHezg9BhGuHtI2R4n5XFSThgSikLDGNIjdJGX3yvNrq2d4UE7J5nGHu82hMGMTwpjj_CbMVm5J9SdokTAmU8FkWzwvewPR2kgCFOE-syvEPDuiUiNNmUM5qcFpVfiaX5RWHmw-SIswZKPFkW97XGMZkKFHR0Vdy3S1P2ZOt-usmHaVhBq0P9VfLd0yL_HOWW0zlT0xK7R3x1kR3uI9FytvO4pa71IrAi7m6MuDn-yDEZLbAJrY1UBxi2YC51_ezV6_wQxwSIYXnchUblF-iX8dTNdS7dJ0olcPGXAK7Nj_zhCR7qcO1pCK6BHNWsewGbd-mFYErdEhz2Mtg"
URL="https://cpd-cpd-cpd.apps.ocp1.iicparis.fr.ibm.com/text-to-speech/my-111-speech/instances/1584962612016/api"

VOICE="es-ES_EnriqueV3Voice"
VOICE="es-ES_LauraV3Voice"
METHOD="/v1/synthesize"
SPEECH="tts-es.mp3"

curl -k -X POST -H "Authorization: Bearer $BEARER" -H 'Content-Type: application/json' -H 'Accept: audio/mp3' --output $SPEECH -d @${REQ} ${URL}${METHOD}'?voice='${VOICE}


### Discovery

Flags:
  -h, --help                  Display this message
  -c, --cluster-host          The hostname of the master node of the targeted
                              cluster. Discovery needs this to make API calls
                              to schedule training jobs.
  -C, --cp4d-namespace        The Kubernetes namespace that the CP4D
                              application is running in
  -d, --module                Path to the module directory, or a module tar
                              archive
  -e, --release-name          The Helm release name to use
                              (default: '${default_name}')
  -i, --interactive           Interactive installation. Use 'true' or 1 to run
                              in interactive mode. Use 'false' or 0 to run in
                              non-interactive mode.
  -I, --cluster-ip            The IPv4 address of the node specified using
                              '--cluster-host' must also be provided. If the
                              node's hostname is not accessible by services
                              running within the cluster Watson Discovery will
                              fallback to this IP address. As such, you must
                              ensure this address can be accessed by pods running
                              in the cluster's Kubernetes environment.
  -l, --log-file              The file to write logs to
                              (default: '${default_log_file}")
  -n, --namespace             The namespace to install to
  -o, --openshift             Specify 'true' or 1 to do an OpenShift installation,
                              and 'false' or 0 for an IBM Cloud Private Foundations
                              installation.
  -O, --overwrite-yaml        The name of a Helm values override file to apply
                              when installing modules.
  -r, --registry-pull-prefix  The Docker image prefix for Kubernetes to use to
                              pull images from the cluster's Docker registry.
  -R, --registry-push-prefix  The Docker image prefix to tag images with to
                              push them into the cluster's Docker registry.
  -s, --storage-class         The Kubernetes StorageClass to use for Persistent
                              Volumes
  -S, --shared-storage-class  Specify a separate StorageClass for Persistent
                              Volumes that require the ReadWriteMany access
                              mode.
  -t, --timeout               The timeout to use for install steps
                              (default: '${default_timeout}')
  -w, --tiller-namespace      The namespace Tiller is running in


cd ~/cpd/deploy
./deploy.sh -d ~/cpd/ibm-watson-discovery -s managed-nfs-storage -S managed-nfs-storage -R docker-registry-default.apps.ocp1.iicparis.fr.ibm.com -r docker-registry.default.svc:5000 -n cpd -o true -e my-211-disco -C cpd -w tiller -c lb-ocp1.iicparis.fr.ibm.com -I 172.16.187.10 -i false



kubectl create -f - << EOF
apiVersion: security.openshift.io/v1
kind: SecurityContextConstraints
metadata:
  name: ibm-discovery-prod-scc
allowHostDirVolumePlugin: false
allowHostIPC: false
allowHostNetwork: false
allowHostPID: false
allowHostPorts: false
allowPrivilegedContainer: false
allowPrivilegeEscalation: false
allowedCapabilities: []
allowedFlexVolumes: []
allowedUnsafeSysctls: []
defaultAddCapabilities: []
forbiddenSysctls:
- "*"
fsGroup:
  type: MustRunAs
  ranges:
    - max: 65535
      min: 1
readOnlyRootFilesystem: false
requiredDropCapabilities:
- ALL
runAsUser:
  type: MustRunAsNonRoot
seccompProfiles:
  - docker/default
seLinuxContext:
  type: RunAsAny
supplementalGroups:
  type: MustRunAs
  ranges:
  - max: 65535
    min: 1
volumes:
- configMap
- downwardAPI
- emptyDir
- persistentVolumeClaim
- projected
- secret
priority: 0
EOF


#### Head Restarting a pod

oc get deployments -n openshift-console -o wide

oc get pods -n openshift-console -o wide

oc scale --replicas=0 deployment/console -n openshift-console

oc scale --replicas=2 deployment/console -n openshift-console

watch oc get pods -n openshift-console -o wide

#### Tail Restarting a pod


-->
