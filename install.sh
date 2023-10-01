#!/usr/bin/env bash

### README
#
# Author: Alex Red
# Github: https://github.com/alex-red/server-setup
# Required packages: curl, wget, unzip
# Recommended distro: Debian-based (e.g., Ubuntu, Debian bookworm)
#

### CONFIGURATION

# NOTE: doing this will override some native cli commands which may interfere with other scripts
INSTALL_ALIASES=true # will create a ~/.custom-cli-aliases file and add to .bashrc replacing original cli tools
INSTALL_ALIASES_FILE=~/.custom-cli-aliases

INSTALL_CONFIGS=true    # will install config files for tmux, micro, etc
OVERWRITE_CONFIGS=false # will overwrite existing configs
# located in .config
# should attempt to merge safely with existing configs

BASH_COLOURS=true # will add bash colors

INSTALL_NERD_FONTS=true # will install nerd fonts
NERD_FONT_DIRECT_LINK="https://github.com/ryanoasis/nerd-fonts/raw/090fbbeebe256dc8078f2e3b3322fe804419b094/patched-fonts/FiraCode/Retina/FiraCodeNerdFontMono-Retina.ttf"
# more over here: https://github.com/ryanoasis/nerd-fonts

INSTALL_FISH=true        # will install fish shell
SET_FISH_AS_DEFAULT=true # will set fish as the default shell
INSTALL_FISH_EXTRAS=true # add Fisher
INSTALL_FISH_NVM=true    # adds NVM through fisher
# adds fisher plugins:
# tide https://github.com/IlanCosman/tide

INSTALL_DOCKER=true

# tmp path for downloads, will be deleted after install
DOWNLOAD_PATH="./downloads"

### Variables

INITIAL_DIR=$(pwd)
FAILED=()
SUCCESS=()
SKIPPED=()

# map of all the packages to install to their repository name
# if not a repository then it's a system package
# TODO: specify specfic versions to be more secure
# comment out any package that you do not want to install
declare -A PACKAGE_MAP
PACKAGE_MAP=(
  [tmux]="tmux"
  [micro]="zyedidia/micro"         # micro editor, vscode-like editor
  [bat]="sharkdp/bat"              # bat, cat with syntax highlighting
  [htop]="htop"                    # htop, top but better
  [dust]="bootandy/dust"           # dust, du but better
  [exa]="exa"                      # exa, ls but better
  [fd]="sharkdp/fd"                # fd, find but better
  [rg]="ripgrep"                   # rg, grep but better
  [zoxide]="ajeetdsouza/zoxide"    # zoxide, cd but better
  [fzf]="junegunn/fzf"             # fzf, fuzzy finder
  [erd]="solidiquis/erdtree"       # erdtree (erd) - modern disk/file utility, combines du, tree, find, wc and ls
  [bottom]="ClementTsang/bottom"   # bottom, like top/htop with more features
  [neofetch]="dylanaraps/neofetch" # neofetch, system info
)

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

### Helper Functions
get_latest_release() {
  git_version=$(
    curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
      grep '"tag_name":' |                                            # Get tag line
      sed -E 's/.*"([^"]+)".*/\1/' |                                  # Pluck JSON value
      sed 's/v//g'
  )

  echo "$git_version"
}

exists() {
  cmd="$1"
  if ${!cmd}; then
    if command -v "$1" &>/dev/null; then
      echo "$1 already exists!"
      SKIPPED+=("$1")
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

### Pre-checks

echo_color "Updating apt..." "blue"
sudo apt update -y

echo_color "Installing curl, wget, unzip, rsync..." "blue"
sudo apt install -y curl wget unzip rsync

if [ $? -eq 0 ]; then
  echo_color "All good!" "green"
else
  echo_color "Failed to locate curl, wget, unzip, rsync!" "red"
  exit 1
fi

### Install Packages

EGET_HASH="0e64b8a3c13f531da005096cc364ac77835bda54276fedef6c62f3dbdc1ee919"

# install eget if it doesn't exist
if ! command -v eget &>/dev/null; then
  echo_color "Installing eget..." "blue"

  curl -o eget.sh https://zyedidia.github.io/eget.sh
  shasum -a 256 eget.sh # verify with hash below

  # if the hash is not the same then exit
  if [[ ! $(shasum -a 256 eget.sh) == "$EGET_HASH" ]]; then
    echo_color "Failed to verify eget hash!" "red"
    exit 1
  fi

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
cd $DOWNLOAD_PATH || exit

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

    sudo mv "$package" /usr/local/bin/

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
    sudo usermod -aG docker "$USER"

    newgrp docker # refresh group

    rm get-docker.sh
  fi
fi

# install nerd fonts
if $INSTALL_NERD_FONTS; then
  # extract font name from the link including the extension
  font_name=$(echo $NERD_FONT_DIRECT_LINK | grep -oP '[^/]*$')
  mkdir -p "$HOME"/.local/share/fonts

  # check if specified font exists
  if [ -f "$HOME/.local/share/fonts/$font_name" ]; then
    echo_color "[Exists] Skipping nerd fonts install..." "yellow"
    SKIPPED+=("nerd fonts")
  else

    echo_color "Installing nerd fonts..." "cyan"
    cd "$HOME"/.local/share/fonts || exit
    curl -fLO $NERD_FONT_DIRECT_LINK

    if [ $? -eq 0 ]; then
      echo_color "Successfully downloaded nerd fonts!" "green"
      fc-cache -fv
      echo_color "Successfully installed nerd fonts!" "green"
      SUCCESS+=("nerd fonts")
    else
      echo_color "Failed to download nerd fonts!" "red"
      FAILED+=("nerd fonts")
    fi

    cd "$INITIAL_DIR" || exit
  fi
fi

# install fish shell
if $INSTALL_FISH; then
  # check if fish exists
  if exists "fish"; then
    echo_color "Skipping fish install..." "yellow"
    SKIPPED+=("fish shell")
  else
    echo_color "Installing fish shell..." "cyan"
    sudo apt install -y fish

    if [ $? -eq 0 ]; then
      echo_color "Successfully installed fish shell!" "green"
      SUCCESS+=("fish shell")
    else
      echo_color "Failed to install fish shell!" "red"
      FAILED+=("fish shell")
    fi
  fi
fi

# set fish as default shell
if $SET_FISH_AS_DEFAULT; then
  if exists "fish"; then
    # check if current shell is fish
    if [[ $SHELL == *"fish"* ]]; then
      echo_color "Fish is already the default shell!" "yellow"
      SKIPPED+=("fish shell default")
    else

      echo_color "Setting fish as default shell..." "cyan"
      chsh -s /usr/bin/fish

      if [ $? -eq 0 ]; then
        echo_color "Successfully set fish as default shell!" "green"
        SUCCESS+=("fish shell default")
      else
        echo_color "Failed to set fish as default shell!" "red"
        FAILED+=("fish shell default")
      fi
    fi
  else
    echo_color "Fish is not installed, skipping setting fish as default shell..." "yellow"
    SKIPPED+=("fish shell default")
  fi
fi

# install fisher if fish exists
if $INSTALL_FISH_EXTRAS; then
  if exists "fish"; then
    if exists "fisher"; then
      echo_color "Skipping fisher install..." "yellow"
      SKIPPED+=("fisher")
    else
      echo_color "Installing fisher..." "cyan"
      curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

      if [ $? -eq 0 ]; then
        echo_color "Successfully installed fisher!" "green"
        SUCCESS+=("fisher")
      else
        echo_color "Failed to install fisher!" "red"
        FAILED+=("fisher")
      fi
    fi
  else
    echo_color "Fish is not installed, skipping fisher install..." "yellow"
    SKIPPED+=("fisher")
  fi
fi

# install fisher extras plugins
if $INSTALL_FISH_EXTRAS; then
  if exists "fish"; then
    if exists "fisher"; then
      # install tide
      echo_color "Installing tide..." "cyan"

      fisher install IlanCosman/tide

      if [ $? -eq 0 ]; then
        echo_color "Successfully installed tide!" "green"
        SUCCESS+=("fisher tide")
      else
        echo_color "Failed to install tide!" "red"
        FAILED+=("fisher tide")
      fi

      # install nvm
      if $INSTALL_FISH_NVM; then
        echo_color "Installing nvm..." "cyan"

        fisher install jorgebucaran/nvm.fish

        if [ $? -eq 0 ]; then
          echo_color "Successfully installed nvm!" "green"
          SUCCESS+=("fisher nvm")
        else
          echo_color "Failed to install nvm!" "red"
          FAILED+=("fisher nvm")
        fi
      fi

    else
      echo_color "Fisher is not installed, skipping fisher plugins install..." "yellow"
      SKIPPED+=("fisher plugins")
    fi
  else
    echo_color "Fish is not installed, skipping fisher plugins install..." "yellow"
    SKIPPED+=("fisher plugins")
  fi
fi

if $INSTALL_CONFIGS; then
  echo_color "Installing configs..." "cyan"

  # if the config folder exists then move it to a backup
  if [ -d ~/.config ]; then
    echo_color "Backing up ~/.config to ~/.config.bak..." "yellow"
    mv ~/.config ~/.config.bak
  fi

  if $OVERWRITE_CONFIGS; then
    rsync -arP ./config/ ~/.config
    echo_color "Overwrote existing configs!" "green"
  else
    rsync -arP --ignore-existing ./config/ ~/.config
    echo_color "Merged configs but ignored existing!" "green"
  fi

  echo_color "Successfully installed configs!" "green"
fi

### Post Processing

# Check if the command from PACKAGE_MAP is installed
# If it is, add it to the list of success
# If it isn't, add it to the list of failed
for cmd in "${!PACKAGE_MAP[@]}"; do
  cmd_alias="${COMMAND_ALIAS_MAP[$cmd]}"
  if command -v "$cmd" &>/dev/null; then
    if [[ ! " ${SKIPPED[@]} " =~ " $cmd " ]]; then
      SUCCESS+=("$cmd")
    fi

    # if cmd_alias is not empty then add an alias for it
    if [[ -n "$cmd_alias" ]]; then
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
  echo -e "$ALIASES" >$INSTALL_ALIASES_FILE

  if test -f $INSTALL_ALIASES_FILE; then
    echo -e "Adding $INSTALL_ALIASES_FILE to your .bashrc"
    grep -qxF "source $INSTALL_ALIASES_FILE" ~/.bashrc || echo "source $INSTALL_ALIASES_FILE" >>~/.bashrc
  fi
fi

if $BASH_COLOURS; then
  echo -e "Enabled bash colors"
  colors="PS1='\[\033[1;36m\]\u\[\033[1;31m\]@\[\033[1;32m\]\h:\[\033[1;35m\]\w\[\033[1;31m\]\$\[\033[0m\] '"
  grep -qxF "$colors" ~/.bashrc || echo "$colors" >>~/.bashrc
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
