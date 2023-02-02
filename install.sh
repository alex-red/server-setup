#!/usr/bin/env bash

### README
#
# Author: Alex Red
# Github: https://github.com/alex-red/server-setup
# Required packages: curl, wget, unzip
# Recommended distro: Ubuntu
#

### Helper Functions
get_latest_release() {
  git_version=$(curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/' |                               # Pluck JSON value
    sed 's/v//g'
    )

  echo $git_version
}

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

### Config

# IS_ARM is true if the system is arm64 or aarch64
IS_ARM=$(if [ $(uname -m) == "aarch64" ] || [ $(uname -m) == "arm64" ]; then echo 1; else echo 0; fi)

### Packages to install
micro=true # text editor
bat=true # cat alternative
bat_version=$(get_latest_release "sharkdp/bat")
# if IS_ARM then return "arm64.deb" otherwise "amd64.deb"
bat_filename="bat_${bat_version}_$(if [ $IS_ARM -eq 1 ]; then echo "arm64.deb"; else echo "amd64.deb"; fi)"
bat_source="https://github.com/sharkdp/bat/releases/download/v${bat_version}/${bat_filename}"
htop=true
dust=true # du -sh alternative
dust_version=$(get_latest_release "bootandy/dust")
# if IS_ARM then return "arm-unknown-linux-gnueabihf.tar.gz" otherwise "x86_64-unknown-linux-gnu.tar.gz"
dust_filename="dust-v${dust_version}-$(if [ $IS_ARM -eq 1 ]; then echo "arm-unknown-linux-gnueabihf.tar.gz"; else echo "x86_64-unknown-linux-gnu.tar.gz"; fi)"
dust_source="https://github.com/bootandy/dust/releases/download/v${dust_version}/${dust_filename}"
exa=true # ls alternative
exa_version=$(get_latest_release "ogham/exa")
# if IS_ARM then return "exa-linux-armv7-v" otherwise "exa-linux-x86_64-v"
exa_filename="$(if [ $IS_ARM -eq 1 ]; then echo "exa-linux-armv7-v"; else echo "exa-linux-x86_64-v"; fi)${exa_version}.zip"
exa_source="https://github.com/ogham/exa/releases/download/v${exa_version}/$exa_filename"
fd=true # find command alternative
fd_version=$(get_latest_release "sharkdp/fd")
# if IS_ARM then return "arm64.deb" otherwise "amd64.deb"
fd_filename="fd_${fd_version}_$(if [ $IS_ARM -eq 1 ]; then echo "arm64.deb"; else echo "amd64.deb"; fi)" # musl is a lightweight libc implementation for linux, it's used to make the binary smaller and more portabl
fd_source="https://github.com/sharkdp/fd/releases/download/v${fd_version}/${fd_filename}"
rg=true # better grep
rg_version=$(get_latest_release "BurntSushi/ripgrep")
# if IS_ARM then return "arm64.deb" otherwise "amd64.deb"
rg_filename=$(if [ $IS_ARM -eq 1 ]; then echo "ripgrep-version-arm-unknown-linux-gnueabihf.tar.gz"; else echo "ripgrep_version_amd64.deb"; fi)
# replace rg_filename "version" with rg_version
rg_filename=${rg_filename/version/$rg_version}
rg_source="https://github.com/BurntSushi/ripgrep/releases/download/${rg_version}/${rg_filename}"

### Other configs

# NOTE: doing this will override some native cli commands which may interfere with other scripts
INSTALL_ALIASES=true # will create a ~/.custom-cli-aliases file and add to .bashrc replacing original cli tools
INSTALL_ALIASES_FILE=~/.custom-cli-aliases
BASH_COLOURS=true # will add bash colors 

### Variables

FAILED=()
SUCCESS=()
SKIPPED=()
declare -A CHECK_INSTALLED
CHECK_INSTALLED=( ["micro"]="micro" ["bat"]="cat" ["htop"]="top" ["dust"]="du" ["exa"]="ls" ["fd"]="find" ["rg"]="rg" )
DOWNLOAD_PATH="./downloads"

### Pre-checks

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

### Main

# wait for all get_latest_release functions to finish

# if download folder doesn't exist, create it
if [ ! -d "$DOWNLOAD_PATH" ]; then
  mkdir $DOWNLOAD_PATH
fi

# cd into download folder
cd $DOWNLOAD_PATH

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
  # if $bat_source ends in .tar.gz then use tar
  if [[ $bat_source == *.tar.gz ]]; then
    wget $bat_source -O bat.tar.gz
    mkdir bat
    tar xzf bat.tar.gz -C ./bat
    if test -f ./bat/*/bat; then
      sudo mv ./bat/*/bat /usr/bin
      echo "Installed Bat."
    else
      echo "Failed to download bat from $bat_source."
    fi
    rm -rf bat
  else
    wget $bat_source -O bat.deb
    if test -f "./bat.deb"; then
      sudo dpkg -i bat.deb
      echo "Installed Bat."
    else
      echo "Failed to download bat from $bat_source."
    fi
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
	if test -f ./bin/exa; then
		sudo mv ./bin/exa /usr/bin/exa
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
  # if $rg_source ends in .tar.gz then use tar
  if [[ $rg_source == *.tar.gz ]]; then
    echo "Downloading rg from $rg_source"
    wget $rg_source -O rg.tar.gz
    mkdir rg
    tar xzf rg.tar.gz -C ./rg
    if test -f ./rg/rg; then
      sudo mv ./rg/rg /usr/bin
      echo "Installed ripgrep."
    else
      echo "Failed to download ripgrep from $rg_source."
    fi
    rm -rf rg
    rm rg.tar.gz
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

if $BASH_COLOURS; then
	echo -e "Enabled bash colours"
	colors="PS1='\[\033[1;36m\]\u\[\033[1;31m\]@\[\033[1;32m\]\h:\[\033[1;35m\]\w\[\033[1;31m\]\$\[\033[0m\] '"
	grep -qxF "$colors" ~/.bashrc || echo "$colors" >> ~/.bashrc
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

### CLEANUP
echo -e "\n\e[33mCleaning up..."

# cd back to original directory
cd ..

# remove download folder
rm -rf $DOWNLOAD_PATH

echo -e "\n\e[33mDone! You should reload bash"
