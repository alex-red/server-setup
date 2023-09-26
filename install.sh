#!/usr/bin/env bash

### README
#
# Author: Alex Red
# Github: https://github.com/alex-red/server-setup
# Required packages: curl, wget, unzip
# Recommended distro: Debian-based (e.g., Ubuntu)
#

### Other configs

# NOTE: doing this will override some native cli commands which may interfere with other scripts
INSTALL_ALIASES=true # will create a ~/.custom-cli-aliases file and add to .bashrc replacing original cli tools
INSTALL_ALIASES_FILE=~/.custom-cli-aliases
BASH_COLOURS=true # will add bash colors 

### Variables

FAILED=()
SUCCESS=()
SKIPPED=()
DOWNLOAD_PATH="./downloads"
INSTALL_DOCKER=true

### Pre-checks

if ! command -v curl &> /dev/null; then
  echo "Curl is not installed! Aborting..."
  exit 1
fi

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

# a function to pretty print echo statements with color
# example: echo_color "This is a message" "green"
echo_color() {
  message="$1"
  color="$2"
  case $color in
    "red")
      echo -e "\e[31m$message\e[0m"
      ;;
    "green")
      echo -e "\e[32m$message\e[0m"
      ;;
    "yellow")
      echo -e "\e[33m$message\e[0m"
      ;;
    "blue")
      echo -e "\e[34m$message\e[0m"
      ;;
    "purple")
      echo -e "\e[35m$message\e[0m"
      ;;
    "cyan")
      echo -e "\e[36m$message\e[0m"
      ;;
    *)
      echo -e "\e[37m$message\e[0m"
      ;;
  esac
}

### Config

# install eget if it doesn't exist
if ! command -v eget &> /dev/null; then
  echo_color "Installing eget..." "blue"
  curl -o eget.sh https://zyedidia.github.io/eget.sh
  shasum -a 256 eget.sh # verify with hash below
  bash eget.sh

  # mv eget to /usr/local/bin
  sudo mv eget /usr/local/bin/
  rm eget.sh
fi

# if download folder doesn't exist, create it
if [ ! -d "$DOWNLOAD_PATH" ]; then
  mkdir $DOWNLOAD_PATH
fi

# cd into download folder
cd $DOWNLOAD_PATH

# map of all the packages to install to their repository name
declare -A PACKAGE_MAP
PACKAGE_MAP=(
  [curl]="curl"
  [unzip]="unzip"
  [wget]="wget"
  [micro]="zyedidia/micro"
  [bat]="sharkdp/bat"
  [htop]="htop"
  [dust]="bootandy/dust"
  [exa]="exa"
  [fd]="sharkdp/fd"
  [rg]="ripgrep"
)

# for each package in the map check if it exists and if not then install it
for package in "${!PACKAGE_MAP[@]}"; do
  if exists "$package"; then
    continue
  fi

  # if the package does not have / in it then it's a system package
  if [[ ! "${PACKAGE_MAP[$package]}" == *"/"* ]]; then
    echo_color "Installing system package: $package" "cyan"
    sudo apt install -y "${PACKAGE_MAP[$package]}"
    continue
  fi

  eget -q -a ^musl "${PACKAGE_MAP[$package]}"

  # if the package binary exists then move it to /usr/local/bin
  if [ -f "./$package" ]; then

    sudo mv $package /usr/local/bin/

    echo_color "Successfully installed $package!" "green"
  else
    echo_color "Failed to install $package!" "red"
  fi
done

# if install docker is true then do a command
if $INSTALL_DOCKER; then
  # if exists docker then do nothing
  if exists "docker"; then
    echo_color "Skipping docker install..." "yellow"
  else
    # install docker
    echo_color "Installing docker..." "cyan"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh

    # add user to docker group
    echo_color "Adding user to docker group..." "cyan"
    sudo usermod -aG docker $USER

    newgrp docker # refresh group

    rm get-docker.sh
  fi
fi

### Post Processing
ALIASES=""

declare -A COMMAND_ALIAS_MAP
# map of commands to their aliases
COMMAND_ALIAS_MAP=(
  ["micro"]="micro"
  ["htop"]="top"
  ["bat"]="bat"
  ["exa"]="exa"
  ["fd"]="fd"
  ["rg"]="rg"
  ["dust"]="dust"
)

# Check if the command from PACKAGE_MAP is installed
# If it is, add it to the list of success
# If it isn't, add it to the list of failed
for cmd in "${!PACKAGE_MAP[@]}"; do
  cmd_alias="${COMMAND_ALIAS_MAP[$cmd]}"
  if command -v "$cmd" &> /dev/null; then
    if [[ ! " ${SKIPPED[@]} " =~ " $cmd " ]]; then
      SUCCESS+=("$cmd")
    fi

    # if cmd_alias is not empty then add an alias for it
    if [[ ! -z "$cmd_alias" ]]; then
      ALIASES="${ALIASES}alias $cmd_alias=$cmd\n"
    fi

  else
    if [[ ! " ${SKIPPED[@]} " =~ " $cmd " ]]; then
      FAILED+=("$cmd")
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
  echo -e "Enabled bash colors"
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

# cd back to the original directory
cd ..

# remove the download folder
rm -rf $DOWNLOAD_PATH

echo -e "\n\e[33mDone! You should reload bash"
