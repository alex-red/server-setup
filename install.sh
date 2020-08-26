#!/usr/bin/env bash

### README
#
# Author: Alex Red
# Github: https://github.com/alex-red/server-setup
# Required packages: curl, wget, unzip
# Recommended distro: Ubuntu
#

### Config

### Packages to install
micro=true # text editor
bat=true # cat alternative
bat_source="https://github.com/sharkdp/bat/releases/download/v0.15.4/bat_0.15.4_amd64.deb"
htop=true
dust=true # du -sh alternative
dust_source="https://github.com/bootandy/dust/releases/download/v0.5.2/dust-v0.5.2-x86_64-unknown-linux-gnu.tar.gz"
exa=true # ls alternative
exa_source="https://github.com/ogham/exa/releases/download/v0.9.0/exa-linux-x86_64-0.9.0.zip"
fd=true # find command alternative
fd_source="https://github.com/sharkdp/fd/releases/download/v8.1.1/fd_8.1.1_amd64.deb"
rg=true # better grep
rg_source="https://github.com/BurntSushi/ripgrep/releases/download/11.0.2/ripgrep_11.0.2_amd64.deb"

### Other configs

# NOTE: doing this will override some native cli commands which may interfere with other scripts
INSTALL_ALIASES=true # will create a ~/.custom-cli-aliases file and add to .bashrc replacing original cli tools
INSTALL_ALIASES_FILE=~/.custom-cli-aliases

### Variables

FAILED=()
SUCCESS=()
SKIPPED=()
declare -A CHECK_INSTALLED
CHECK_INSTALLED=( ["micro"]="micro" ["bat"]="cat" ["htop"]="top" ["dust"]="du" ["exa"]="ls" ["fd"]="find" ["rg"]="rg" )

### Helper Functions

exists()
{
	cmd="$1"
	if ${!cmd}; then
		if command -v "$1" &> /dev/null; then
			echo "$1 already exists!"
			SKIPPED+=( "$1" )
			return 0
		else
			return 1
		fi
	else
		return 1
	fi
}

###

if ! command -v curl &> /dev/null; then
	echo "Curl is not installed! Aborting..."
	exit 1
fi

if ! command -v wget &> /dev/null; then
	echo "Wget is not installed! Aborting..."
	exit 1
fi

if ! command -v unzip &> /dev/null; then
	echo "Unzip is not installed! Aborting..."
	exit 1
fi

if exists micro; then
	echo "Skipping Micro"
else
	echo "Downloading Micro (Text Editor)"
	curl https://getmic.ro | bash
	if test -f "./micro"; then
		sudo mv micro /usr/bin
		echo "Installed Micro."
	else
		echo "Failed to download Micro."
	fi
fi

if exists bat; then
	echo "Skipping Bat"
else

	echo "Downloading bat from $bat_source"
	wget $bat_source -O bat.deb
	if test -f "./bat.deb"; then
		sudo dpkg -i bat.deb
		echo "Installed Bat."
	else
		echo "Failed to download bat from $bat_source."
	fi

	rm bat.deb
fi

if exists htop; then
	echo "Skipping htop"
else
	echo "Downloading htop"
	sudo apt install htop -y

	if exists htop; then
		echo "Installed htop"
	else
		echo "Failed to install htop"
	fi
fi


if exists dust; then
	echo "Skipping dust"
else
	echo "Dowloading dust"
	wget $dust_source -O dust.tar.gz
	mkdir dust
	tar xzf dust.tar.gz -C ./dust
	if test -f ./dust/*/dust; then
		sudo mv ./dust/*/dust /usr/bin
		echo "Installed dust"
	else
		echo "Failed to dowload dust"
	fi

	rm -rf dust
	rm dust.tar.gz
fi

if exists exa; then
	echo "Skipping exa"
else
	echo "Downloading exa"
	wget $exa_source -O exa.zip
	unzip exa.zip
	if test -f ./exa-linux-x86_64; then
		sudo mv ./exa-linux-x86_64 /usr/bin/exa
		echo "Installed exa"
	else
		echo "Failed to download exa"
	fi

	rm exa.zip
fi

if exists fd; then
	echo "Skipping fd"
else

	echo "Downloading fd from $fd_source"
	wget $fd_source -O fd.deb
	if test -f "./fd.deb"; then
		sudo dpkg -i fd.deb
		echo "Installed fd."
	else
		echo "Failed to download fd from $fd_source."
	fi

	rm fd.deb
fi

if exists rg; then
	echo "Skipping ripgrep"
else
	echo "Downloading rg from $rg_source"
	wget $rg_source -O rg.deb
	if test -f "./rg.deb"; then
		sudo dpkg -i rg.deb
		echo "Installed ripgrep."
	else
		echo "Failed to download ripgrep from $rg_source."
	fi

	rm rg.deb
fi

### Post Processing
ALIASES=""

for cmd in "${!CHECK_INSTALLED[@]}"; do
	cmd_alias="${CHECK_INSTALLED[$cmd]}"
	if ${!cmd}; then
	    if command -v "$cmd" &> /dev/null; then
   			if [[ ! " ${SKIPPED[@]} " =~ " $cmd " ]]; then
	   			SUCCESS+=("$cmd")	
		   	fi
	  		ALIASES="${ALIASES} alias $cmd_alias=$cmd\n"  	
   		else
			if [[ ! " ${SKIPPED[@]} " =~ " $cmd " ]]; then
   		   		FAILED+=("$cmd")
		   	fi
   		fi
	fi
done

if $INSTALL_ALIASES; then
	echo -e "\nAdding aliases to $INSTALL_ALIASES_FILE"
	touch $INSTALL_ALIASES_FILE
	echo -e "$ALIASES" > $INSTALL_ALIASES_FILE

	if test -f $INSTALL_ALIASES_FILE; then
		echo -e "Adding $INSTALL_ALIASES_FILE to your .bashrc"
		grep -qxF "source $INSTALL_ALIASES_FILE" ~/.bashrc || echo "source $INSTALL_ALIASES_FILE" >> ~/.bashrc
	fi
fi

echo -e "\n\e[33m\e[34mSuccessfully Installed:"
echo -e "\e[33m=======================\n"

for cmd in ${SUCCESS[*]}; do
	echo -e "\e[1m$cmd - ✅"
done

echo -e "\n\e[91mFailed to install:"
echo -e "\e[33m=======================\n"

for cmd in ${FAILED[*]}; do
	echo -e "\e[1m$cmd - ❌"
done

echo -e "\n\n\e[96mSkipped:"
echo -e "\e[33m=======================\n"

for cmd in ${SKIPPED[*]}; do
	echo -e "\e[1m$cmd"
done


