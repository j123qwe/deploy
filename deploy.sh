#!/bin/bash

##Begin installation of packages on Debian/Ubuntu systems

##Variables
DEBIAN_FRONTEND=noninteractive
GITHUB=j123qwe #GitHub account to import SSH keys from

##Functions

update(){
	sudo apt update
	sudo apt upgrade -y
}

install(){
	sudo apt install -yq \
		htop \
		tshark \
		wireshark \
		multitail \
		lrzsz \
		ssh-import-id
}

install_docker(){
	#Install required packages
	sudo apt install -yq \
		apt-transport-https \
		ca-certificates \
		curl \
		gnupg-agent \
		software-properties-common
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - #Download Docker GPG key
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" #Add Docker repository
	sudo apt update #Refresh APT
	sudo apt install docker-ce docker-ce-cli containerd.io #Install Docker
}

config(){
	ssh-import-id-gh ${GITHUB} #Import SSH key(s) from GitHub
}

##Execute
#update
#install
install_docker
#config
