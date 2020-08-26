# QOL Server Setup
Scripts for installing QOL/needed packages for Ubuntu servers

# Packages
```bash
micro # CLI text editor (similar to sublime text)
bat # cat alternative
htop # top alternative
dust # du -sh alternative
exa # ls alternative
fd # find alternative
rg (ripgrep) # better grep
```
# Misc

- Alias file (will create alias file replacing existing cli commands)
- Bash colours

# Installation

**Required commands**: `curl, wget, unzip` 

**Distro**: `Ubuntu` *(Debian-based may work)*

## Recommended
```bash
git clone https://github.com/alex-red/server-setup.git
chmod +x install.sh
# edit install.sh first to set preferences
./install.sh
```

## Not Recommended
```bash
curl https://raw.githubusercontent.com/alex-red/server-setup/master/install.sh | bash
```
