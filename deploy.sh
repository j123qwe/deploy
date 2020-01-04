#!/bin/bash

##Begin installation of packages on Debian/Ubuntu systems

##Variables
DEBIAN_FRONTEND=noninteractive
RED='\e[0;41;30m'
STD='\e[0;0;39m'

##Functions

update(){
	sudo apt update
	sudo apt upgrade -y
}

install_utils(){
	sudo apt install -yq \
		htop \
		tshark \
		wireshark \
		multitail \
		lrzsz \
		nload \
		ssh-import-id \
		nfs-common \
		nmap \
		inetutils-traceroute \
		zip \
		apt-transport-https \
		vim-scripts \
		unzip
}

install_ssh(){
	until [[ -n ${GITHUB} ]]; do
		read -p "Enter GitHub username: " GITHUB #Get GitHub account to import SSH keys
	done
	ssh-import-id-gh ${GITHUB} #Import SSH key(s) from GitHub
	unset GITHUB
}


install_docker(){
	#Install required packages
	sudo apt install -yq \
		ca-certificates \
		curl \
		gnupg-agent \
		software-properties-common
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - #Download Docker GPG key
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" #Add Docker repository
	sudo apt update #Refresh APT
	sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose #Install Docker
}

install_kubernetes(){
	sudo swapoff -a #Disable swap
	sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab #Remove swap partition from fstab
	sudo dpkg -s docker.io | grep installed > /dev/null
	if [ $? -eq 1 ]; then
		install_docker #Docker is not installed
	else
		#Docker is installed
	fi
	sudo cat > /etc/docker/daemon.json <<EOF
{
"exec-opts": ["native.cgroupdriver=systemd"],
"log-driver": "json-file",
"log-opts": {
"max-size": "100m"
},
"storage-driver": "overlay2"
}
EOF
	sudo mkdir -p /etc/systemd/system/docker.service.d
	sudo systemctl daemon-reload
	sudo systemctl restart docker
	
	sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
	sudo add-apt-repository "deb https://apt.kubernetes.io/ kubernetes-xenial main"
	sudo apt update
	sudo apt install -y kubelet kubeadm kubectl nfs-common open-iscsi
	sudo apt-mark hold kubelet kubeadm kubectl #Freezes updates for main K8S apps
	sudo modprobe iscsi_tcp
	sudo kubectl completion bash > /etc/bash_completion.d/kubectl 
}


install_nfs_server(){
	until [[ -n ${NFSMOUNT} ]]; do
		read -p "Enter directory name to create for NFS share: " NFSMOUNT
	done
	until [[ -n ${SUBNET} ]]; do
		read -p "Enter IP subnet to allow access, e.g. 192.168.1.0/24: " SUBNET
	done	
	sudo apt update
	sudo apt install -y nfs-kernel-server
	sudo mkdir -p ${NFSMOUNT}
	sudo chown nobody:nogroup ${NFSMOUNT}
	sudo chmod 777 ${NFSMOUNT}
	echo "${NFSMOUNT} ${SUBNET}(rw,sync,no_subtree_check)" >> /etc/exports
	sudo exportfs -a
	sudo systemctl restart nfs-kernel-server
}

install_webmin(){
	curl -fsSL http://www.webmin.com/jcameron-key.asc | sudo apt-key add - #Download Webmin GPG key
	sudo add-apt-repository "deb https://download.webmin.com/download/repository sarge contrib" #Add Webmin repository
	sudo apt update #Refresh APT
	sudo apt install -y webmin
}



show_menus() {
	printf "\n\n"
	echo -e "${RED}~~~~~~~~~~~~~~~~~~~~~"
	echo -e " M A I N - M E N U   "
	echo -e "~~~~~~~~~~~~~~~~~~~~~${STD}"
	echo "1. Upgrade packages"
	echo "2. Install utilities"
	echo "3. Install SSH Keys from GitHub"
	echo "4. Install Docker"
	echo "5. Install Kubernetes"
	echo "6. Install NFS Server"
	echo "7. Install Webmin"
	echo "0. Exit"
}

read_options(){
	local choice
read -p "Enter choice: " choice
	case $choice in
		1) update ;;
		2) install_utils ;;
		3) install_ssh ;;
		4) install_docker ;;
		5) install_kubernetes ;;
		6) install_nfs_server ;;
		7) install_webmin ;;
		0) exit 0;;
		*) echo -e "Error..." && sleep 1
	esac
}

##Execute

#Launch installation menu
while true
do
	show_menus
	read_options
done
