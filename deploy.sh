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

install_webmin(){
	curl -fsSL http://www.webmin.com/jcameron-key.asc | sudo apt-key add - #Download Webmin GPG key
	sudo add-apt-repository "deb https://download.webmin.com/download/repository sarge contrib" #Add Webmin repository
	sudo apt update #Refresh APT
	sudo apt install -y webmin
}

install_ssh(){
	until [[ -n ${GITHUB} ]]; do
		read -p "Enter GitHub username: " GITHUB #Get GitHub account to import SSH keys
	done
	ssh-import-id-gh ${GITHUB} #Import SSH key(s) from GitHub
	unset GITHUB
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
	echo "5. Install Webmin"
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
		5) install_webmin ;;
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
