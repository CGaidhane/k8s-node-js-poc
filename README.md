# k8s-node-js-poc

deploy ec2 instance as DAC/jump server server
allow outbound traffice from NACL (it getting any issue connecting from sssh client)
congigure aws access keys by aws configure command

sudo yum update -y
sudo yum install git

to verify aws cli
aws ec2 describe-instances \
    --instance-ids i-00c3bab7183942107
	
install kubectl
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.23.15/2023-01-11/bin/linux/amd64/kubectl
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.23.15/2023-01-11/bin/linux/amd64/kubectl.sha256
openssl sha1 -sha256 kubectl
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin
echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc
kubectl version --short --client


install eksctl

curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

check by eksctl version


create EKS cluster using below command (~18 mins):

[ec2-user@ip-172-31-27-83 ~]$ eksctl create cluster \
--name tcs-test \
--version 1.23 \
--region eu-central-1 \
--nodegroup-name linux-nodes \
--node-type t2.micro \
--nodes 2 \
--nodes-min 1 \
--nodes-max 3


or with yaml file:

eksctl create cluster -f tcs-test-cluster.yaml

apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: tcs-test
  region: eu-central-1
  version: "1.23"
nodeGroups:
  - name: linux-nodes
    instanceType: t2.micro
    desiredCapacity: 2
    minSize: 1
    maxSize: 3
    volumeSize: 20
	
	
CloudWatch logging will not be enabled for cluster "tcs-test" in "eu-central-1"
you can enable it with 'eksctl utils update-cluster-logging --enable-types={SPECIFY-YOUR-LOG-TYPES-HERE (e.g. all)} --region=eu-central-1 --cluster=tcs-test'


*************************************************************************************************************************************************************************************


Install helm

Doc page link:
https://helm.sh/docs/intro/install/

run below commmands to install helm 3:
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 777 get_helm.sh
./get_helm.sh

verify:
helm version

helm repo list

kubectl create ns jenkins

jenkins helm chart link:
https://bitnami.com/stack/jenkins/helm

helm repo add bitnami https://charts.bitnami.com/bitnami
helm install jenkins bitnami/jenkins -n jenkins

above will fail with "Error: INSTALLATION FAILED: Kubernetes cluster unreachable: exec plugin: invalid apiVersion "client.authentication.k8s.io/v1alpha1""
because helm v is 3.9.0 and it's known issue there

revert back to helm v3.8.2 and run it again
curl -L https://git.io/get_helm.sh | bash -s -- --version v3.8.2

helm install jenkins bitnami/jenkins -n jenkins

if you are getting Error: INSTALLATION FAILED: failed to download "bitnami/jenkins", try clearing the local cache of the helm client and updating the repository index:

helm repo update

*************************************************************************************************************************************************************************************

kubectl get all -n jenkins
helm list -n jenkins
helm get values jenkins -n jenkins
helm get values jenkins -a -n jenkins > values.yml

We need to create storage class, Persistent volume and Persistent Volume Claim

create sc.yml:

kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: aws-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer

kubectl apply -f sc.yml

create pv.yml:

apiVersion: v1
kind: PersistentVolume
metadata:
  name: jenkins-pv-volume
  namespace: jenkins
  labels:
    type: local
spec:
  storageClassName: aws-storage
  claimRef:
    name: jenkins-pv-claim
    namespace: jenkins
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  local:
    path: /mnt
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - ip-192-168-7-95.eu-central-1.compute.internal     >>>>>>>>>>>>>>>>>>>>>>   change this
		  
kubectl apply -f pv.yml

delete existing PVC
jenkins   Pending                                      gp2            26m

kubectl delete pvc jenkins -n jenkins

create pvc.yml:

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-pv-claim
  namespace: jenkins
spec:
  storageClassName: aws-storage
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
	  
	  
kubectl apply -f pvc.yml

copy pvc name and edit jenkins deployment:

under spec at very last

      volumes:
      - name: jenkins-data
        persistentVolumeClaim:
          claimName: jenkins-pv-claim

new jenkins pod will run  0/1     Running   0

there is a Readiness probe failed: issue and we need to change initialdelayseconds = 300 and periodseconds = 30 in jenkins deployment:

jenkins will be up, use classic loadbalancer DNS name to access it

