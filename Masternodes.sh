#!/bin/bash
#
#Kindly change the IP address and kubeadm init output of join token in this script.
# Script to install a single node K8s cluster
#
# Usage:  $ curl https://raw.githubusercontent.com/BalajiSankarCircana/K8-Cluster/main/Masternodes.sh | sh

### Disable SELINUX ####

cat /etc/sysconfig/selinux | grep SELINUX=
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
cat /etc/sysconfig/selinux | grep SELINUX=
setenforce 0
######################

###Installing Helm####

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh


### Make DNS local entries ### Change it as per your requirement #####
cat <<EOF>>  /etc/hosts

10.36.11.76  master1
10.36.11.84  workernode1
EOF
######################

### Check the connectivity of your cluster nodes #########
ping -c 2 workernode1
######################


### Disable the Firewall ########
systemctl stop firewalld.service
systemctl disable firewalld
systemctl status firewalld
######################

### Kubernetes prerequisite #######
RAM=`cat /proc/meminfo | grep MemTotal | awk '{print ($2 / 1024) / 1024 ,"GiB"}'`
CPU=`cat /proc/cpuinfo | grep processor`

sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
swapoff -a
echo "Your system RAM is $RAM"
echo "Your system CPU are $CPU"
######################


### Preparation for Docker installation #########
modprobe br_netfilter
lsmod | grep br_netfilter

echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
sysctl -a | grep net.bridge.bridge-nf-call-iptables
######################



### Docker installation steps #######
sudo yum -y remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine buildah
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
containerd config default | sudo tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
systemctl start docker
systemctl enable docker
docker run hello-world
######################




### Kubernetes installation steps #####
sudo cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOF


yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable kubelet
systemctl start kubelet
#####################

swapoff -a
kubeadm init 

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
### You should now deploy a Pod network to the cluster. ####
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
