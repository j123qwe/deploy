#!/bin/bash

## Begin installation of packages on Debian/Ubuntu systems

## Variables
DEBIAN_FRONTEND=noninteractive
RED='\e[0;41;30m'
STD='\e[0;0;39m'
DTE=$(date +%Y%m%d%H%M%S)

## Functions

install_ssh(){
	until [[ -n ${GITHUB} ]]; do
		read -p "Enter GitHub username: " GITHUB #Get GitHub account to import SSH keys
	done
	sudo dpkg -s ssh-import-id | grep installed > /dev/null
	if [ $? -eq 1 ]; then
		sudo apt update && sudo apt -y install ssh-import-id
	fi
	ssh-import-id-gh ${GITHUB} #Import SSH key(s) from GitHub
	unset GITHUB
}

set_timezone(){
	sudo timedatectl set-timezone America/Chicago
}

install_dot(){
	# Install VIM Tools if necessary
	dpkg -l | grep vim-scripts > /dev/null #Check to see if vim-scripts is installed
	if [ $? != 0 ]; then
		echo "vim-addon (vim-scripts) not installed, installing"
		sudo apt update && sudo apt -y install vim-scripts
	fi

	# Install TMUX if necessary
	dpkg -l | grep tmux > /dev/null #Check to see if tmux is installed
	if [ $? != 0 ]; then
		echo "tmux not installed, installing"
		sudo apt update && sudo apt -y install tmux
	fi

	#Install DOT files
	mkdir -p ~/.dotbackup
	for DOTFILE in $(find dotfiles/. -maxdepth 1 -name "dot.*" -type f  -printf "%f\n" | sed 's/^dot//g'); do
	    echo "Backing up ~/${DOTFILE} to ~/.dotbackup/${DOTFILE}.${DTE}.bak..."
	    cp ~/${DOTFILE} ~/.dotbackup/${DOTFILE}.${DTE}.bak
	    echo "Installing new file to  ~/${DOTFILE}..."
	    cp dotfiles/dot${DOTFILE} ~/${DOTFILE}
	done
	printf "\n\nPlease type \e[1;31msource ~/.bashrc\e[0m to immediately activate new .bashrc settings.\n\n\n"
}

update(){
	sudo apt update
	sudo apt upgrade -y
}

install_utils(){
	sudo apt install -yq \
		htop \
		whois \
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
	sudo sed -i '/swap/d' /etc/fstab #Remove swap partition from fstab
	sudo dpkg -s docker.io | grep installed > /dev/null
	if [ $? -eq 1 ]; then
		install_docker #Docker is not installed
	fi
	sudo cp k8s/daemon.json /etc/docker/
	sudo mkdir -p /etc/systemd/system/docker.service.d
	sudo systemctl daemon-reload
	sudo systemctl restart docker
	
	sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
	sudo add-apt-repository "deb https://apt.kubernetes.io/ kubernetes-xenial main"
	sudo apt update
	sudo apt install -y kubelet kubeadm kubectl nfs-common open-iscsi
	sudo apt-mark hold kubelet kubeadm kubectl #Freezes updates for main K8S apps
	sudo modprobe iscsi_tcp
	sudo cp k8s/kubectl /etc/bash_completion.d/
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
    echo "Adding the following to /etc/exports..."
    echo "${NFSMOUNT} ${SUBNET}(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports 
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
	echo "1. Install SSH Keys from GitHub"
	echo "2. Set timezone to Central"
	echo "3. Install dotfiles"
	echo "4. Upgrade packages"
	echo "5. Install utilities"
	echo "6. Install Docker"
	echo "7. Install Kubernetes"
	echo "8. Install NFS Server"
	echo "9. Install Webmin"
	echo "0. Exit"
}

read_options(){
	local choice
read -p "Enter choice: " choice
	case $choice in
		1) install_ssh ;;
		2) set_timezone ;;
		3) install_dot ;;
		4) update ;;
		5) install_utils ;;
		6) install_docker ;;
		7) install_kubernetes ;;
		8) install_nfs_server ;;
		9) install_webmin ;;
		0) exit 0;;
		*) echo -e "Error..." && sleep 1
	esac
}

## Execute

#Launch installation menu
while true
do
	show_menus
	read_options
done
