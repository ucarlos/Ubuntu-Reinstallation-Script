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

VERSION_NUMBER="2023-12-01"
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

CLANG_VERSION="18"
DOT_NET_VERSION="8.0"
GCC_VERSION="14"

INTENDED_UBUNTU_VERSION="24.04"
JAVA_VERSION_LIST=('8' '11' '21')
LOCAL_EMACS_FILENAME="emacs30_30.0.5-1_amd64-2023-09-26.deb"
PLEX_USERNAME="plex"
PLEX_VERSION_NUMBER="1.32.8.7639-fb6452ebf"
POSTGRES_VERSION="16"
VNC_VERSION="7.5.1"



# ------------------------------------------------------------------------------
# Essential Helper Functions
# ------------------------------------------------------------------------------

function echo_wait() {
    echo "$1"
    sleep 1

}

function print_dashed_line() {
    for ((i = 1; i <= DASH_LINE_LENGTH; i++));
    do
        printf "-"
    done
    echo ""
    
}

function cd_or_exit() {
    cd "$1" || (echo "Error: Could not change directory to $1. Aborting." && exit 1)
}


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
    sudo ubuntu-drivers autoinstall
}


# ------------------------------------------------------------------------------
# Essential Functions
# ------------------------------------------------------------------------------
function essential_programs() {
    echo_wait "Installing some Essential Programs."
    if (( IS_HEADLESS_SERVER != 1 ));
       then
           sudo apt install deja-dup duplicity mpv -y
           sudo apt install gnome-disk-utility -y
           sudo apt install hexchat filezilla -y
           sudo apt install qbittorrent -y
           sudo apt install usb-creator-gtk -y
           sudo apt install libreoffice -y
           sudo apt install thunderbird -y
           sudo apt install baobab eog gnome-system-monitor evince -y
    fi
    
    sudo apt install htop btop git -y
    sudo apt install tmux gedit net-tools -y
    sudo apt install fdupes -y
    sudo apt install neofetch screenfetch -y
    sudo apt install texlive-latex-base texlive-latex-extra -y
    sudo apt install texlive-latex-recommended -y
    sudo apt install ttf-mscorefonts-installer -y
    sudo apt install openssh-server -y
    sudo apt install flatpak -y
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    sudo apt install curl -y
    sudo apt install checkinstall -y

    sudo apt install bleachbit -y
    sudo apt install cryptsetup -y
    sudo apt install p7zip-full unrar -y
    sudo apt install nmap -y

    sudo apt install webp-pixbuf-loader -y
    sudo apt install keepassxc -y
    sudo apt install espeak -y
    sudo apt install speedtest-cli -y


    if (( IS_DESKTOP == 1 ));
    then        
        setup_kvm
    fi


    echo_wait "Installing Calibre Library..."
    sudo -v && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin

    install_yacreader
    
}    

function setup_kvm() {
    # First, install the requirements:

    sudo apt install qemu-system qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst virt-manager -y
    
    # Next, set up any additional permissions here:
    sudo systemctl enable libvirtd
    
}

function appearance_tools() {
    if (( IS_DESKTOP == 1 ));
    then
        sudo apt install dconf-editor -y

    fi
    
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

function install_emacs_dependencies() {

    # https://github.com/ucarlos/Ubuntu-Reinstallation-Script.git
    
    sudo apt install libjansson-dev "libgccjit-${GCC_VERSION}-dev" -y
    sudo apt install libclang-dev clangd-"${CLANG_VERSION}" -y


    sudo apt install libwebkit2gtk-4.1-dev libwebkit2gtk-6.0-dev -y
    sudo apt install libjpeg-dev libtiff-dev libncurses-dev texinfo libxpm-dev libwebp-dev -y
    sudo apt install libmagickcore-dev libmagick++-dev -y
    sudo apt install mailutils -y
    sudo apt install opus-tools -y

}


function install_emacs_debian() {
    cd_or_exit "$CURRENT_PATH"
   
    if [[ ! -d "$CURRENT_PATH/debians" ]]
    then
        echo "Error: The ${CURRENT_PATH}/debians directory does not exist."
        return 0
    fi

    if [[ ! -f "$CURRENT_PATH/debians/$LOCAL_EMACS_FILENAME" ]]
    then
        echo "Error: ${CURRENT_PATH}/debians does not contain a $LOCAL_EMACS_FILENAME to install emacs."
        return 0
    fi


    sudo dpkg -i "$CURRENT_PATH/debians/$LOCAL_EMACS_FILENAME"
    
    installation_result=$(sudo apt install --fix-broken)
    
    if (( installation_result != 0 ))
    then
        echo "Error: Some issue occurred while installing the emacs debian."
        echo "You may need to investigate this on your own."
    else
        echo "Complete!"
    fi
      
    # Now return
    cd_or_exit "$CURRENT_PATH"
}



function install_emacs() {
    echo_wait "First installing Dependencies."
    install_emacs_dependencies


    read -r -n2 -p "Do you want me to install emacs through a personal debian file? [y/n] " user_input
    if [[ $user_input =~ [yY] ]]
    then
        install_emacs_debian
    else
        read -r -n2 -p "How about installing the default emacs for your distribution? [y/n] " user_input
        
        if [[ $user_input =~ [yY] ]]
        then
            echo "Alright then, It shouldn't take long."
            sudo apt install emacs -y
        else
            echo "Alright, you're on your own then."
        fi
            
    fi
    # Now return back to CURRENT_PATH just in case:
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
    sudo snap install node
}

function install_googletest() {
    sudo apt install googletest -y
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

    install_googletest
}

function install_php() {
    # For now, we'll just install the default version of PHP -- Which is 8.3
    sudo apt install php -y
    
}


function install_csharp() {
    # First, cd to ~/:
    cd "$TEMP_DOWNLOAD_PATH" || (echo "Some error occurred in csharp_tools." && exit 1)
  
    # Install the packing signing key.
    wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb

    # Now install the SDK:
    sudo apt update
    sudo apt install apt-transport-https -y
    sudo apt install "dotnet-sdk-${DOT_NET_VERSION}" -y


    cd_or_exit "$CURRENT_PATH"
    # cd "$HOME_PATH"

}

function install_python() {
    sudo apt install python3-pip -y
    sudo apt install python3-venv python-is-python3 -y

    # Establish python lsp server
    python3 -m pip install --user python-lsp-server[all]

    # Symlink pylsp to pyls in order for lsp-mode to locate it.
    # You may need to change this in the future.
    ln -s ~/.local/bin/pylsp ~/.local/bin/pyls

    # Install some pip packages:

    python3 -m pip install gdown
    python3 -m pip install jupyterlab
    python3 -m pip install notebook
    python3 -m pip install ipython
    python3 -m pip install numpy
    python3 -m pip install ipdb
    python3 -m pip install tldr

}

function install_rust() {
    sudo apt install rust-all -y

}


function install_sql() {

    sudo apt install mariadb-server -y
    # THIS NEEDS TO BE UPDATED
    sudo apt install "postgresql-${POSTGRES_VERSION}" -y

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
    fi


    sudo apt-get install pavucontrol -y
    
}

function install_yacreader() {
    if (( IS_VALID_UBUNTU_VERSION == 1 ))
    then
        echo_wait "Installing Yacreader..."
        sudo flatpak install YACReader -y
    fi
}

function install_manual_debian_files() {
    echo_wait "Now downloading and installing some .deb files that have to be installed manually."
    
    # Create the download path if it exists.
    mkdir -p "$TEMP_DOWNLOAD_PATH"
    
    cd "$TEMP_DOWNLOAD_PATH" || (echo "Could not enter $TEMP_DOWNLOAD_PATH. Exiting." && exit)

    if (( IS_DESKTOP == 1 ));
    then
        # Discord
        wget -O "discord-recent-version.deb" "https://discord.com/api/download?platform=linux&format=deb"

        if (( IS_VALID_UBUNTU_VERSION == 1 ))
        then
            # Strawberry            
            sudo flatpak install flathub org.strawberrymusicplayer.strawberry -y
        fi

        # Minecraft
        wget "https://launcher.mojang.com/download/Minecraft.deb"
        
    fi

    # --------------------------------------
    # VNC Server and Client:
    # --------------------------------------
    
    # VNC Client
    # Grab the newest debian: (Warning: If the site is messed up, you're fucked...)

    # curl --silent https://www.realvnc.com/en/connect/download/viewer/ | grep "DEB x64" | grep -Eo -e "data-file=\"[^\>]*" | awk -F "=" '{print $2;}
    vnc_link=$(curl --silent https://www.realvnc.com/en/connect/download/viewer/ | grep "DEB x64" | grep -Eo -e "data-file=\"[^\>]*" | awk -F "=" '{print $2;}' | sed "s/\"/\'/g")
    if [[ -z "$vnc_link" ]]
    then
        vnc_link="https://downloads.realvnc.com/download/file/viewer.files/VNC-Viewer-${VNC_VERSION}-Linux-x64.deb"
    fi

    wget "$vnc_link"


    # Now grab the latest VNC Server debian:
    # curl --silent "https://www.realvnc.com/en/connect/download/vnc/" | grep "DEB x64" | grep -Eo -e "data-file=\"[^\>]*" | awk -F "=" '{print $2;}'
    vnc_link=$(curl --silent "https://www.realvnc.com/en/connect/download/vnc/" | grep "DEB x64" | grep -Eo -e "data-file=\"[^\>]*" | awk -F "=" '{print $2;}' | sed "s/\"/\'/g")
    if [[ -z "$vnc_link" ]]
    then
        vnc_link="https://downloads.realvnc.com/download/file/vnc.files/VNC-Server-${VNC_VERSION}-Linux-x64.deb"
    fi
    
    
    # --------------------------------------    
    # ProtonVPN
    # --------------------------------------
    
    wget "https://repo2.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.3-3_all.deb"

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
        sudo apt install steam-installer -y        
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
    if (( IS_DESKTOP == 1 ));
    then
        sudo snap install bitwarden
        sudo snap install spotify
        sudo snap install plex-desktop

    elif (( IS_MEDIA_SERVER == 1 ));
    then
        sudo snap install plex-htpc
    else
        echo "No Snap Applications for you!"
    fi

}


# ------------------------------------------------------------------------------
# Media Server Only Functions
# ------------------------------------------------------------------------------

function install_and_configure_plex() {
    echo_wait "Now installing Plex."
    cd_or_exit "$TEMP_DOWNLOAD_PATH"

    wget "https://downloads.plex.tv/plex-media-server-new/${PLEX_VERSION_NUMBER}/debian/plexmediaserver_${PLEX_VERSION_NUMBER}_amd64.deb"

    if [[ ! -f "plexmediaserver_${PLEX_VERSION_NUMBER}_amd64.deb" ]]
    then
        echo "Error: Could not download plexmediaserver_${PLEX_VERSION_NUMBER}_amd64.deb. Aborting."
        return        
    fi

    sudo dpkg -i "plexmediaserver_${PLEX_VERSION_NUMBER}_amd64.deb"
    
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
    wget "http://fcron.free.fr/archives/fcron-3.3.1.src.tar.gz"
    tar -xvf "fcron-3.3.1.src.tar.gz"

    # Now install the damn thing
    cd "fcron-3.3.1" && ./configure && make && sudo make install

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
    echo "Desktop Installation"
    update_first
    
    graphic_drivers
    essential_programs
    brave_browser
    
    appearance_tools    
    programming_tools
    multimedia_tools
   
    vidya
    #snap_ides
    #snap_applications
    
    install_manual_debian_files
    install_fcron
    increase_swap_size
}


function media_server_installation() {
    echo "Media Server Installation"
    update_first
    
    graphic_drivers
    essential_programs
    appearance_tools
    
    multimedia_tools
    programming_tools

    vidya    
    brave_browser    
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
    release_version=$(lsb_release -i | xargs | awk -F ' ' '{print $2; }')

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
            sudo echo 'XKBOPTIONS="ctrl:swapcaps"'| tee --append "/etc/default/keyboard"
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
