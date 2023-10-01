# QOL Server Setup

Scripts for installing QOL/needed packages for Ubuntu servers

# Packages

```bash
  [tmux]="tmux"
  [rsync]="rsync"
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

  docker
  nerd_fonts
  fish
  fisher
  fisher_tide_theme
```

# Misc

- Alias file (will create alias file replacing existing cli commands)
- Bash colours

# Installation

**Required commands**: `curl, wget, unzip`

**Distro**: `Ubuntu` _(Debian-based may work)_

```bash
git clone https://github.com/alex-red/server-setup.git
chmod +x install.sh
# edit install.sh first to set preferences
./install.sh
```
