#!/bin/bash
# ------------------------------------------------------------------------------
# Created by Ulysses Carlos on 11/21/2020 at 11:49 PM
#
# Reinstall_Ubuntu.sh
# This is essentially a more user friendly version of New_installation.sh
# Which reinstalls all the programs I would want in a Ubuntu Reinstallation.
#
# It covers a normal workstation desktop installation, media server installation
# and a minimal build.

# Note:
# This installation script is meant to be used in a Ubuntu Distribution.
#
# TODO: Possibly Replace this with a Python Script as some point?
# ------------------------------------------------------------------------------
#

# ------------------------------------------------------------------------------
# Global Variables
# ------------------------------------------------------------------------------
VERSION_NUMBER="2026-08-29"
DASH_LINE_LENGTH=80
CURRENT_PATH=$(pwd)
USERNAME="$USER"
TEMP_DOWNLOAD_PATH="/tmp/Downloads"
HOME_PATH="/home/$USERNAME/"

# Specified Booleans
# 0 is false, while 1 is true
IS_DESKTOP=1
IS_MEDIA_SERVER=0
IS_HEADLESS_SERVER=0
IS_VALID_UBUNTU_VERSION=1

CLANG_VERSION="22"
DOT_NET_VERSION="10"
GCC_VERSION="16"

INTENDED_UBUNTU_VERSION="26.04"
JAVA_VERSION_LIST=('8' '21' '25')
PLEX_USERNAME="plex"
FCRON_VERSION="3.4.1"

# ------------------------------------------------------------------------------
# Essential Helper Functions
# ------------------------------------------------------------------------------
source "./Util.sh"

# ------------------------------------------------------------------------------
# First things first:
# ------------------------------------------------------------------------------

function update_first() {
    sudo apt update
    sudo apt upgrade -y
}

# ------------------------------------------------------------------------------
# Drivers
# ------------------------------------------------------------------------------
function graphic_drivers() {
    echo_wait "Installing Graphic Drivers."
    sudo ubuntu-drivers install
}

# ------------------------------------------------------------------------------
# Essential Functions
# ------------------------------------------------------------------------------
function essential_programs() {
    echo_wait "Installing some Essential Programs."
    create_required_directories

    if (( IS_HEADLESS_SERVER != 1 ));
       then
           sudo apt install mpv -y
           sudo apt install gnome-disk-utility -y
           sudo apt install qbittorrent -y
           sudo apt install usb-creator-kde -y
    fi

    sudo apt install restic -y
    sudo apt install fail2ban -y
    sudo apt install htop btop git -y
    sudo apt install tmux gedit net-tools -y
    sudo apt install fdupes -y
    sudo apt install fastfetch -y
    sudo apt install ttf-mscorefonts-installer -y
    sudo apt install openssh-server -y
    sudo apt install flatpak -y
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    sudo flatpak install flathub org.nicotine_plus.Nicotine -y

    sudo apt install curl -y
    sudo apt install checkinstall -y

    sudo apt install bleachbit -y
    sudo apt install cryptsetup -y
    sudo apt install p7zip-full unrar -y
    sudo apt install nmap -y

    sudo apt install webp-pixbuf-loader -y
    sudo apt install speedtest-cli -y

    if (( IS_DESKTOP == 1 ));
    then
        sudo apt install thunderbird -y
        sudo apt install hexchat filezilla -y
        sudo apt install texlive-latex-base texlive-latex-extra -y
        sudo apt install texlive-latex-recommended -y
        sudo apt install texlive-xetex -y
        sudo apt install texlive-lang-all -y
        sudo apt install pandoc -y

        sudo apt install keepassxc -y
        sudo apt install libreoffice -y
        sudo apt install hunspell-en-us hunspell-es -y


        sudo apt install baobab eog gnome-system-monitor evince -y
        sudo apt install espeak -y
        setup_kvm

        echo_wait "Installing Calibre Library..."
        sudo -v && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin

        install_yacreader
    fi
}

function setup_kvm() {
    # First, install the requirements:

    sudo apt install qemu-system-x86 libvirt-daemon-system libvirt-clients bridge-utils virtinst virt-manager -y

    # Next, set up any additional permissions here:
    sudo systemctl enable libvirtd
}

function appearance_tools() {
    sudo apt install fonts-firacode -y

    if (( IS_HEADLESS_SERVER != 1 ));
    then
        sudo apt install paper-icon-theme arc-theme -y
        sudo apt install variety -y
    fi
}

# ------------------------------------------------------------------------------
# Web Browsers
# ------------------------------------------------------------------------------
function brave_browser() {
    echo_wait "Now installing Brave Browser."
    sudo apt install apt-transport-https curl -y

    curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -

    echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list

    sudo apt update
    sudo apt install brave-browser -y
}

# ------------------------------------------------------------------------------
# Programming Tools
# ------------------------------------------------------------------------------

function install_text_editors() {
    sudo apt install neovim -y
    install_emacs
}

function install_emacs() {
    sudo apt install dict dict-freedict-eng-spa dict-jargon dict-gcide dict-freedict-spa-eng -y
    sudo apt install libimage-exiftool-perl -y
    sudo apt install emacs emacs-common-non-dfsg -y
    cd_or_exit "$CURRENT_PATH"
}

function install_golang() {
    sudo apt install golang -y
}

function install_java() {
    for i in "${JAVA_VERSION_LIST[@]}"
    do
        sudo apt install "openjdk-${i}-jdk" -y
    done

    sudo apt install libderby-java -y
}

function install_javascript() {
    sudo snap install node --channel=24/stable --classic
    sudo snap install deno
}

function install_cpp {
    sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
    sudo apt install "g++-${GCC_VERSION}" "gcc-${GCC_VERSION}" -y

    # In order to allow clangd to work, you have to add the most recent corresponding
    # libstdc++ version. Otherwise, you'll get strange errors like
    # iostream header not found or whatever randomly.
    # NOTE: If this start happening out of nowhere, check if the latest libstdc++ has been installed.
    sudo apt install "libstdc++-${GCC_VERSION}-dev" -y
    sudo apt install "clang-${CLANG_VERSION}" -y
    sudo apt install valgrind -y

    sudo apt install libpqxx-dev libmysql++-dev -y

    sudo apt install libboost-all-dev -y
    sudo apt install cmake -y
    sudo apt install libspdlog-dev -y

    # For Doxygen:
    sudo apt install doxygen-* -y
    sudo apt install graphviz -y
    sudo apt install googletest -y
}

function install_php() {
    # For now, we'll just install the default version of PHP -- Which is 8.3
    sudo apt install php-all-dev -y
}

function install_csharp() {
    sudo apt install "dotnet${DOT_NET_VERSION}" -y
    cd_or_exit "$CURRENT_PATH"
}

function install_python() {
    sudo apt install python3-pip -y
    sudo apt install python3-venv python-is-python3 -y
    sudo apt install python3-ipython -y
    sudo apt install pipx -y

    # Establish python lsp server
    python3 -m pip install --user python-lsp-server[all] --break-system-packages
    python3 -m pip install --user python-lsp-ruff --break-system-packages

    # Install some pip packages:
    python3 -m pip install jupyterlab --break-system-packages
    python3 -m pip install notebook --break-system-packages
    python3 -m pip install numpy --break-system-packages
    python3 -m pip install ipdb --break-system-packages
    python3 -m pip install tldr --break-system-packages
    pipx install yt-dlp; pipx upgrade yt-dlp
}

function install_rust() {
    sudo apt install rust-all -y
}

function install_sql() {
    sudo apt install mariadb-server -y
    sudo apt install postgresql -y

    # Now install mysql workbench:
    sudo snap install mysql-workbench-community
}


function install_misc_programming() {
    # Racket
    sudo apt install racket -y

    # Static Analyzer for bash
    sudo apt install shellcheck -y
}


function programming_tools() {
    echo_wait "Now installing some Programming libraries and tools."

    # Text Editors
    install_text_editors

    # C/C++
    install_cpp

    # C#
    install_csharp

    # Golang
    install_golang

    # Java
    install_java

    # JavaScript
    install_javascript

    # PHP
    install_php

    # Python
    install_python

    install_misc_programming

    # SQL
    install_sql

    # Just to make sure, return back to your current path:
    cd_or_exit "$CURRENT_PATH"
}

# ------------------------------------------------------------------------------
# Additional Tools
# ------------------------------------------------------------------------------

function multimedia_tools() {
    echo_wait "Installing some multimedia, multimedia editing, and recording software..."

    if (( IS_DESKTOP == 1 ));
    then
        sudo apt install kdenlive -y
        sudo apt install audacity -y
        sudo apt install gimp -y
        sudo apt install easytag -y

        sudo add-apt-repository ppa:obsproject/obs-studio -y
        sudo apt-get install obs-studio -y
        sudo flatpak install flathub org.strawberrymusicplayer.strawberry -y

    fi

    if (( IS_MEDIA_SERVER == 1 ));
    then
        sudo flatpak install flathub tv.kodi.Kodi -y
    fi

    sudo apt-get install pavucontrol -y
}

function install_yacreader() {
    echo_wait "Installing Yacreader..."
    sudo flatpak install YACReader -y
}

function install_vpn() {
    cd "$TEMP_DOWNLOAD_PATH" || (echo "Could not enter $TEMP_DOWNLOAD_PATH. Exiting." && exit)

    local protonvpn_command
    local debian_url
    local debian_file

    protonvpn_command=$(curl -s https://protonvpn.com/support/official-linux-vpn-ubuntu | grep -Eo 'wget[^<"]*/stable/[^<"]*\.deb' | head -n1)

    debian_url=$(echo "$protonvpn_command" | awk '{print $2}')
    debian_file=$(basename "$debian_url")
    echo "$debian_url"
    echo "$debian_file"

    if [[ -n "$debian_url" ]]
    then
        echo "Downloading and installing $debian_file from $debian_url..."
        wget -O "$debian_file" "$debian_url"
        sudo dpkg -i "$debian_file"
    else
        echo "Could not download ProtonVPN debian file."
    fi

    cd_or_exit "$CURRENT_PATH"
}

function install_manual_debian_files() {
    echo_wait "Now downloading and installing some .deb files that have to be installed manually."

    cd "$TEMP_DOWNLOAD_PATH" || (echo "Could not enter $TEMP_DOWNLOAD_PATH. Exiting." && exit)

    if (( IS_DESKTOP == 1 ));
    then

        # Minecraft
        wget "https://launcher.mojang.com/download/Minecraft.deb"

    fi

    # --------------------------------------
    # Now install each .deb file:
    # --------------------------------------

    yes | sudo dpkg -Ri .

    cd_or_exit "$CURRENT_PATH"
}


function vidya() {
    echo_wait "Now installing Steam and some emulators!"
    if (( IS_DESKTOP == 1 || IS_MEDIA_SERVER == 1));
    then
        sudo apt install steam-libs steam-libs-i386 steam-installer -y
        sudo add-apt-repository ppa:pcsx2-team/pcsx2-daily -y
        sudo apt update
        sudo apt install pcsx2-unstable -y

    fi

    if (( IS_DESKTOP == 1 ));
       then
           sudo add-apt-repository ppa:libretro/stable -y
           #sudo apt install libretro-* -y # MAME and MESS are currently BROKEN
           sudo apt install retroarch -y
    fi

    echo "Now, I would like to install wine on your system, but each Ubuntu version requires a different repository. Instead, I'll just enable 32-bit architecture and add the repository key."
    sudo dpkg --add-architecture i386

    cd_or_exit "$HOME_PATH"
    wget -nc https://dl.winehq.org/wine-builds/winehq.key
    sudo apt-key add winehq.key

    cd_or_exit "$CURRENT_PATH"
}

# Handles installing IDEs through snap.
function snap_ides() {
    echo_wait "Now installing snap programs..."
    sudo snap install clion --classic
    sudo snap install pycharm-professional --classic
    sudo snap install intellij-idea-ultimate --classic
    sudo snap install codium --classic

    sudo snap install android-studio --classic
    sudo snap install phpstorm --classic
    sudo snap install rider --classic
}

# Handles applications that can run through the command line.
function snap_applications() {
    sudo snap install node --classic
    sudo snap install bash-language-server --classic

    if (( IS_DESKTOP == 1 ));
    then
        sudo snap install element-desktop
        sudo snap install bitwarden
        sudo snap install spotify
        sudo snap install plex-desktop
        sudo snap install ferdium
        sudo snap install discord

    elif (( IS_MEDIA_SERVER == 1 ));
    then
        sudo snap install plex-htpc
    fi
}

# ------------------------------------------------------------------------------
# Media Server Only Functions
# ------------------------------------------------------------------------------

function install_and_configure_plex() {
    echo_wait "Now installing Plex."
    cd_or_exit "$TEMP_DOWNLOAD_PATH"

    curl -LsSf https://repo.plex.tv/scripts/setupRepo.sh | sudo bash

    echo_wait "Now Configuring Plex:"
    sudo usermod -a -G "$USERNAME" "$PLEX_USERNAME"
    sudo chown "$USER:$USERNAME" "/media/$USER"
    sudo chmod 750 "/media/$USER"
    sudo setfacl -m g:"$USERNAME":rwx "/media/$USER"
    sudo service plexmediaserver restart

    cd_or_exit "$CURRENT_PATH"
}

# ------------------------------------------------------------------------------
# Services
# ------------------------------------------------------------------------------

function install_fcron() {
    cd_or_exit "$TEMP_DOWNLOAD_PATH"
    # cd "$TEMP_DOWNLOAD_PATH"

    echo_wait "Installing fcron dependencies first..."
    sudo apt install git autoconf mailutils docbook docbook-xsl docbook-xml docbook-utils manpages-dev -y

    # Download the tarball
    wget "http://fcron.free.fr/archives/fcron-${FCRON_VERSION}.src.tar.gz"
    tar -xvf "fcron-${FCRON_VERSION}.src.tar.gz"

    # Now install the damn thing
    cd "fcron-${FCRON_VERSION}" && ./configure && make && sudo make install

    # Now enable it:
    sudo systemctl enable fcron

    # Now return:
    cd_or_exit "$CURRENT_PATH"
    # cd "$CURRENT_PATH"
}

function increase_swap_size() {
    SWAP_SIZE="8"

    echo_wait "Temporarily disabling the swap..."
    sudo swapoff -a

    echo_wait "Increasing the size of /swapfile to ${SWAP_SIZE}G."
    sudo fallocate -l "${SWAP_SIZE}G" /swapfile
    sudo chmod 600 /swapfile

    echo_wait "Now creating the swap from /swapfile"
    sudo mkswap /swapfile

    # echo "Now adding /swapfile to /etc/fstab if it doesn't exist."
    # echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

    echo_wait "Now Re-enable the swap."
    sudo swapon -a
}

# ------------------------------------------------------------------------------
# Installation Functions
# ------------------------------------------------------------------------------

function desktop_installation() {
    echo "Now performing a desktop re-installation."
    sleep 1
    update_first

    graphic_drivers
    essential_programs
    brave_browser

    appearance_tools
    programming_tools
    multimedia_tools

    vidya
    snap_ides
    snap_applications

    install_manual_debian_files
    install_fcron
    increase_swap_size
}

function media_server_installation() {
    echo "Now performing a media server re-installation."
    sleep 1
    update_first

    graphic_drivers
    essential_programs
    appearance_tools

    multimedia_tools

    vidya
    snap_applications
    install_and_configure_plex
    install_fcron
    increase_swap_size
}

function headless_server_installation() {
    update_first
    essential_programs
    programming_tools
    appearance_tools
    install_fcron
    increase_swap_size
}

# Check if the script can be run successfully on the current OS. This requires a Ubuntu
# Distribution set to a specific release version. The Program will exit if the OS is not
# a Ubuntu Distribution.

function verify_ubuntu_distribution() {
    distribution_name=$(lsb_release -i | awk -F ' ' '{print $3;}')
    release_version=$(lsb_release -r | xargs | awk -F ' ' '{print $2; }')

    if [[ "$distribution_name" != "Ubuntu" ]]
    then
        echo_wait "Error: This script will only work on an Ubuntu Distribution. This program will now exit."
        exit 1
    fi


    if [[ "$release_version" != "$INTENDED_UBUNTU_VERSION" ]]
    then
        echo_wait "Warning: This script is intended to be run on Ubuntu ${INTENDED_UBUNTU_VERSION}."
        echo_wait "Since it may not work on your version (${release_version}), programs that depend on a ${INTENDED_UBUNTU_VERSION} release will not be installed."
        IS_VALID_UBUNTU_VERSION=0
    fi

    display_main_menu
}

function swap_caps_lock_and_ctrl() {
    echo_wait "Now Swapping Caps Lock and Control by modifying /etc/default/keyboard..."

    if [[ -f "/etc/default/keyboard" ]];
    then
        # Is there even a XKBOPTIONS line? If not, just append it.
        grep_check=$(grep "XKBOPTIONS" "/etc/default/keyboard")
        if [[ -z "$grep_check" ]];
        then
            sudo echo 'XKBOPTIONS="ctrl:swapcaps"'| sudo tee --append "/etc/default/keyboard"
        else
            # Otherwise, replace an empty XKBOPTIONS line with the ctrl:swapcaps option.
            sudo sed -i 's/XKBOPTIONS=\"\"/XKBOPTIONS=\"ctrl:swapcaps\"/g' /etc/default/keyboard
        fi
    else
        echo "Hmm... /etc/default/keyboard doesn't seem to exist on your system."
        echo "You may either create the file yourself and add XKBOPTIONS=\"ctrl:swapcaps\" to it"
        echo "Or try to run the following alternatives:"
        printf "\tsudo dpkg-reconfigure keyboard-configuration\n"
        printf "\t/usr/bin/setxkbmap -option \"ctrl:swapcaps\"\n"
    fi
}

function display_main_menu() {
    echo "The Current Time is $(date +'%m/%d/%Y %H:%M')"
    print_dashed_line
    echo "Ubuntu Reinstallation (Version $VERSION_NUMBER)"
    print_dashed_line
    echo "Options:"
    echo "a) Default Desktop Installation"
    echo "b) Default Media Server Installation"
    echo "c) Minimal Headless Server Installation"
    echo "q) Quit"
    print_dashed_line

    read -rp "Please enter a option: " -n1 user_input

    # Use regular expression to detect invalid input
    re="^[a-cA-CqQ]"

    while ! [[ $user_input =~ $re ]];
    do
        echo ""
        read -rp "Invalid Input. Please enter a option: " -n1 user_input
    done

    # Lowercase input:
    user_input=$(echo "$user_input" | awk '{print tolower($0)}')
    echo ""

    if [ "$user_input" == "a" ];
    then
        desktop_installation
    elif [ "$user_input" == "b" ];
    then
        IS_DESKTOP=0
        IS_MEDIA_SERVER=1
        media_server_installation
    elif [[ "$user_input" == "c" ]];
    then
        IS_DESKTOP=0
        IS_HEADLESS_SERVER=1
        headless_server_installation
    else
        echo "Exiting..."
        exit
    fi

    swap_caps_lock_and_ctrl
}

# ------------------------------------------------------------------------------
# Now run the script:
# ------------------------------------------------------------------------------
verify_ubuntu_distribution
