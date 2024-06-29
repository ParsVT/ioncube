#!/bin/bash
# #########################################
# Program: ionCube Loader Installation Script
# Developer: Hamid Rabiei, Mohammad Hadadpour
# Update: 1403-04-09
# #########################################
set -e
Color_Off="\e[0m"
Red="\e[0;31m"
Green="\e[0;32m"
Yellow="\e[0;33m"
Blue="\e[0;34m"
Purple="\e[0;35m"
Cyan="\e[0;36m"
INTERNET_STATUS="DOWN"
output() {
	echo -e "$1"
}
checkInternetConnection() {
	TIMESTAMP=$(date +%s)
	ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo -e "\n${Green}Internet connection is UP - $(date +%Y-%m-%d_%H:%M:%S_%Z) - $(($(date +%s) - $TIMESTAMP))${Color_Off}"
		INTERNET_STATUS="UP"
	else
		echo -e "\n${Red}Internet connection is DOWN - $(date +%Y-%m-%d_%H:%M:%S_%Z) - $(($(date +%s) - $TIMESTAMP))${Color_Off}"
		INTERNET_STATUS="DOWN"
		output "Please check the server's internet connection and DNS settings and run the installer again."
		output "\n${Red}The operation aborted!${Color_Off}"
		output "${Yellow}www.parsvt.com${Color_Off}\n"
		exit
	fi
}
installIonCube() {
	cd /tmp
	rm -rf ioncube_loaders_lin*.tar.gz*
	if [ "$ARCH" = "x86_64" ]; then
		wget http://aweb.co/modules/addons/easyservice/Installer/ioncube_loaders_lin_x86-64.tar.gz -O ioncube_loaders_lin_x86-64.tar.gz
	else
		wget http://aweb.co/modules/addons/easyservice/Installer/ioncube_loaders_lin_x86.tar.gz -O ioncube_loaders_lin_x86-64.tar.gz
	fi
	tar xfz ioncube_loaders_lin_x86-64.tar.gz
	PHP_CONFD="/etc/php.d"
	PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
	if [ "$major" = "8" ] || [ "$major" = "9" ]; then
		PHP_EXT_DIR=$(php -r "echo ini_get('extension_dir');")
	else
		PHP_EXT_DIR=$(php-config --extension-dir)
	fi
	cp "ioncube/ioncube_loader_lin_${PHP_VERSION}.so" $PHP_EXT_DIR
	echo "zend_extension = ${PHP_EXT_DIR}/ioncube_loader_lin_${PHP_VERSION}.so" >"${PHP_CONFD}/00-ioncube.ini"
	rm -rf ./ioncube
	rm -rf ioncube_loaders_lin*.tar.gz*
	cd /root
	if [ "$major" = "7" ] || [ "$major" = "8" ] || [ "$major" = "9" ]; then
		systemctl restart httpd
		set +e
		systemctl restart php-fpm
		set -e
	else
		service httpd restart
	fi
}
echo -e "\n${Yellow} ___            __   _______              "
echo -e "| _ \__ _ _ _ __\ \ / /_   _|__ ___ _ __  "
echo -e "|  _/ _\` | '_(_-<\ V /  | |_/ _/ _ \ '  \ "
echo -e "|_| \__,_|_| /__/ \_/   |_(_)__\___/_|_|_|\n"
echo -e "Shell script to install/update ionCube loader on CentOS Linux."
echo -e "Please run as root. if you are not, enter 'n' now and enter 'sudo su' before running the script."
echo -e "Run the script? (y/n): ${Color_Off}"
read -e run
if [ "$run" == n ]; then
	output "\n${Red}The operation aborted!${Color_Off}"
	output "${Yellow}www.parsvt.com${Color_Off}\n"
	exit
else
	checkInternetConnection
	if [ ! -f "/etc/redhat-release" ]; then
		output "\n${Red}Operating system is not supported!${Color_Off}"
		output "ionCube loader installer only installs on CentOS and RHEL-based Linuxes."
		output "You have to install/update ionCube loader manually."
		output "\n${Red}The operation aborted!${Color_Off}"
		output "${Yellow}www.parsvt.com${Color_Off}\n"
		exit
	else
		if [ -f "/etc/redhat-release" ]; then
			fullname=$(cat /etc/redhat-release)
			major=$(cat /etc/redhat-release | tr -dc '0-9.' | cut -d \. -f1)
			ARCH=$(uname -m)
			output "\n${Green}${fullname} ${ARCH}${Color_Off}"
		fi
		set +e
		output "\n${Cyan}Installing required packages...${Color_Off}"
		yum install wget curl expect psmisc net-tools yum-utils zip unzip tar crontabs tzdata -y
		output "${Green}required packages successfully installed!${Color_Off}\n"
		set -e
		wgetfile="/usr/bin/wget"
		curlfile="/usr/bin/curl"
		if [ ! -f "$wgetfile" ] || [ ! -f "$curlfile" ]; then
			output "${Red}required packages failed to install!${Color_Off}"
			output "Please check the server's internet connection and DNS settings and run the installer again."
			output "\n${Red}The operation aborted!${Color_Off}"
			output "${Yellow}www.parsvt.com${Color_Off}\n"
			exit
		fi
		if ! command -v "php" &>/dev/null; then
			output "${Red}PHP is not installed!${Color_Off}"
			output "\n${Red}The operation aborted!${Color_Off}"
			output "${Yellow}www.parsvt.com${Color_Off}\n"
			exit
		else
			output "${Green}PHP is already installed!${Color_Off}\n"
			output "Checking the PHP version..."
			PHP_VER=$(php -r "if (version_compare(PHP_VERSION,'5.6.0','>')) echo 'Ok'; else echo 'Failed';")
			PHP_VERSION=$(php -r "echo PHP_VERSION;")
			if [ "$PHP_VER" = "Ok" ]; then
				cd /root
				output "Current PHP version: ${Green}${PHP_VERSION}${Color_Off}\n"
				output "Checking the ionCube loader version..."
				wget -q http://aweb.co/modules/addons/easyservice/Installer/ic.txt -O /root/IC.php
				set +e
				IONCUBE_VER=$(php -f /root/IC.php)
				IONCUBE_VERSION=$(php -r "error_reporting(0); echo ioncube_loader_version();")
				set -e
				rm -rf /root/IC.php*
				if [ "$IONCUBE_VER" = "Ok" ]; then
					output "Current ionCube loader version: ${Green}${IONCUBE_VERSION}${Color_Off}\n"
					exit
				elif [ "$IONCUBE_VER" = "Upgrade" ]; then
					output "Current ionCube loader version: ${Red}${IONCUBE_VERSION}${Color_Off}"
					output "\n${Cyan}Updating ionCube loader...${Color_Off}"
					installIonCube
					output "${Green}ionCube loader successfully updated!${Color_Off}\n"
				elif [ "$IONCUBE_VER" = "Failed" ]; then
					output "Current ionCube loader version: ${Red}${IONCUBE_VERSION}${Color_Off}"
					output "${Red}ionCube loader version must be greater than 10.0.0${Color_Off}"
					output "\n${Red}The operation aborted!${Color_Off}"
					output "${Yellow}www.parsvt.com${Color_Off}\n"
					exit
				else
					output "ionCube loader is not installed!"
					output "\n${Cyan}Installing ionCube loader...${Color_Off}"
					installIonCube
					output "${Green}ionCube loader successfully installed!${Color_Off}\n"
				fi
			else
				output "Current PHP version: ${Red}${PHP_VER}${Color_Off}"
				output "${Red}PHP version must be greater than 5.5${Color_Off}"
				output "\n${Red}The operation aborted!${Color_Off}"
				output "${Yellow}www.parsvt.com${Color_Off}\n"
				exit
			fi
		fi
	fi
fi
