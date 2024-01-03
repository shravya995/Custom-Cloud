## Ceph

# Microceph setup
sudo su -
sudo snap install microceph --channel=quincy/stable && snap refresh --hold microceph
sudo snap connect microceph:hardware-observe
sudo snap connect microceph:block-devices
sudo microceph cluster bootstrap
sudo microceph status
lsblk | grep -v loop
sudo microceph disk add /dev/disk1 --wipe
sudo microceph disk add /dev/disk2 --wipe
sudo microceph disk add /dev/disk3 --wipe
sudo microceph status
sudo ceph status

# Enabling ceph dashboard
sudo microceph.ceph config set mgr mgr/dashboard/ssl false
sudo microceph.ceph config set mgr mgr/dashboard/server_port 8888
sudo microceph.ceph mgr module enable dashboard
sudo echo -n "password" > /var/snap/microceph/current/conf/password.txt
sudo microceph.ceph dashboard ac-user-create -i /etc/ceph/password.txt admin administrator
rm /var/snap/microceph/current/conf/password.txt

# radosgw-admin setup
sudo microceph enable rgw --port 8080
export hostname=$(hostname -I)
sudo microceph.radosgw-admin realm create --rgw-realm=cephzonerealm --default
sudo microceph.radosgw-admin zonegroup create --rgw-zonegroup=us --endpoints=http://$hostname:8080 --rgw-realm=cephrealm --master --default
sudo microceph.radosgw-admin zone create --rgw-zonegroup=us --rgw-zone=us-east --master --endpoints=http://$hostname:8080
sudo microceph.radosgw-admin zonegroup delete --rgw-zonegroup=default --rgw-zone=default
sudo microceph.radosgw-admin period update --commit
sudo microceph.radosgw-admin zone delete --rgw-zone=default
sudo microceph.radosgw-admin period update --commit
sudo microceph.radosgw-admin zonegroup delete --rgw-zonegroup=default
sudo microceph.radosgw-admin period update --commit
sudo ceph osd pool rm default.rgw.control default.rgw.control --yes-i-really-really-mean-it
sudo ceph osd pool rm default.rgw.data.root default.rgw.data.root --yes-i-really-really-mean-it
sudo ceph osd pool rm default.rgw.gc default.rgw.gc --yes-i-really-really-mean-it
sudo ceph osd pool rm default.rgw.log default.rgw.log --yes-i-really-really-mean-it
sudo ceph osd pool rm default.rgw.users.uid default.rgw.users.uid --yes-i-really-really-mean-it
sudo microceph.radosgw-admin user create --uid="user" --display-name="user" --access-key=useraccesskey --secret-key=usersecretkey --system
sudo microceph.ceph dashboard set-rgw-credentials
sudo microceph.radosgw-admin period update --commit
sudo apt install -y awscli
sudo microceph.radosgw-admin user list
sudo microceph.radosgw-admin zone list
aws configure --profile=ceph-user
# Provide access-key = useraccesskey, secret-key = usersecretkey, region=default, and the last value as json
# Restart machine after all the above setup statements before running the below command
aws --profile ceph-user --endpoint-url http://192.168.64.6:8080 s3api create-bucket --bucket bucket


## OpenFaaS - Run these setup as user not as root
# Docker
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker

# Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-arm64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# openfaas cli
curl -sSL https://cli.openfaas.com | sudo -E sh

# helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

sudo vi ~/.bashrc
## Add the following command to the last line of bashrc file and save it using :wq
alias kubectl="minikube kubectl --"
source ~/.bashrc

# Setup openfaas on ubuntu
minikube start --driver=docker
kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml
helm repo add openfaas https://openfaas.github.io/faas-netes/
helm repo update
export PASSWORD=$(head -c 12 /dev/urandom | shasum| cut -d' ' -f1)
echo $PASSWORD
kubectl -n openfaas create secret generic basic-auth --from-literal=basic-auth-user=admin --from-literal=basic-auth-password="$PASSWORD"
helm upgrade openfaas --install openfaas/openfaas --namespace openfaas --set basic_auth=true --set functionNamespace=openfaas-fn --set generateBasicAuth=true
export Password=$(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode)
echo $Password>dashboard_password.txt
echo $Password
# if you want to port forward gateway instead of using gateway external, use the command below:
kubectl port-forward -n openfaas svc/gateway 8080:8085 & 

# if you don't want to port forward, run the following commands
export OPENFAAS_URL=$(minikube ip):31112
echo -n $PASSWORD | faas-cli login -g http://$OPENFAAS_URL -u admin --password=$Password
kubectl -n openfaas get deployments -l "release=openfaas, app=openfaas"

# Function definition
kubectl get pods -n openfaas
faas-cli template store pull python3-debian
faas-cli new custom-cloud --lang python3-debian

# create two files, access-key.txt, secret-key.txt and add the corresponding values to these text files and run the following commands:

# NOTE: the $gw is going to be the URL of the openfaas dashboard with the port
export gw="http://192.168.49.2:31112"
faas-cli secret create openfaas-aws-access-key --from-file=access-key.txt -g $gw
faas-cli secret create openfaas-aws-secret-key --from-file=secret-key.txt -g $gw

# navigate to custom-cloud folder, update requirements with opencv-python-headless, face-recognition and boto3. 
# open handler.py in the custom-cloud folder and update the code for running the recognition there.
# go to template folder -> python3-debian folder -> Dockerfile. In the dockerfile add ffmpeg in line 14, where there is apt-get install command.
# open custom-cloud.yml file, and add the following settings in indented inside the function key:
```
  functions:
    custom-cloud:
      ...
      secrets:
        - openfaas-aws-access-key
        - openfaas-aws-secret-key
      environment:
        dynamodb_region: us-east-1
        dynamodb_table: CSE546-student-database
```
# Once all the above changes are made, lets deploy the function

# Update the image key in the custom-cloud.yml with your docker hub username. If you don't have a docker hub account, create an account by visiting hub.docker.com. login to docker hub on your machine using the following command.

docker login

# Copy the encoding file to the custom-cloud folder.

faas-cli up -f custom-cloud.yml -g $gw

# You can check the status of the container pod using the following command:

kubectl get pods -n openfaas-fn

#gw is same as above

aws --profile ceph-user --endpoint-url http://192.168.64.6:8080 s3api create-bucket --bucket quiz-on-friday-project-3-input-data

aws --profile ceph-user --endpoint-url http://192.168.64.6:8080 s3api create-bucket --bucket quiz-on-friday-project-3-output-data