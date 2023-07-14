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
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Global Variables
# ------------------------------------------------------------------------------

VERSION_NUMBER="2023-07-01"
DASH_LINE_LENGTH=80
CURRENT_PATH=$(pwd)
USERNAME="$USER"
TEMP_DOWNLOAD_PATH="/tmp/Downloads"
HOME_PATH="/home/$USERNAME/"

# 0 is false, while 1 is true
IS_DESKTOP=1
IS_MEDIA_SERVER=0
IS_HEADLESS_SERVER=0

GCC_VERSION="13"
CLANG_VERSION="15"
PHP_VERSION="8.1"
NODE_VERSION="20"
JAVA_VERSION_LIST=('8' '11' '18')
POSTGRES_VERSION="14"
DOT_NET_VERSION="6.0"
VNC_VERSION="7.5.1"
PLEX_VERISON="1.32.4.7195-7c8f9d3b6"
PLEX_USERNAME="plex"


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
    fi
    
    sudo apt install htop btop git -y
    sudo apt install tmux gedit net-tools -y
    sudo apt install fdupes -y
    sudo apt install neofetch screenfetch -y
    sudo apt install texlive-latex-base texlive-latex-extra -y
    sudo apt install texlive-latex-recommended -y
    sudo apt install ttf-mscorefonts-installer -y
    sudo apt install openssh-server -y
    sudo apt install usb-creator-gtk -y
    sudo apt install curl -y
    sudo apt install checkinstall -y
    sudo apt install qbittorrent -y
    sudo apt install bleachbit -y
    sudo apt install cryptsetup -y
    sudo apt install p7zip-full unrar -y
    sudo apt install nmap -y
    sudo apt install libreoffice -y
    sudo apt install thunderbird -y
    sudo apt install baobab eog gnome-system-monitor evince -y
    sudo apt install webp-pixbuf-loader -y
    sudo apt install espeak -y
    sudo apt install speedtest-cli -y
    sudo apt install gnucash -y


    if (( IS_DESKTOP == 1 ));
    then        
        setup_kvm
    fi


    echo_wait "Installing Calibre Library..."
    sudo -v && wget -nv -o- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin

    install_yacreader
    
}    

function setup_kvm() {
    # First, install the requirements:
    sudo apt install qemu qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst virt-manager -y
    
    # Next, set up any additional permissions here:
    sudo systemctl enable libvirtd
    
}

function appearance_tools() {
    if (( IS_DESKTOP == 1 ));
    then
	sudo apt install lightdm gnome-tweaks gnome-shell-extensions -y
	sudo apt install chrome-gnome-shell -y
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


function install_emacs_debian() {
    mkdir -p "$TEMP_DOWNLOAD_PATH"
    cd_or_exit "$TEMP_DOWNLOAD_PATH"

    download_link="https://drive.google.com/uc?export=download&id=1y7puzujXcqpueSkZxiDrMXAX4-8EC6IO"
    file_name="emacs30_30.0.5-1_native-comp_2023-04-11_amd64.deb"

    
    if (( IS_MEDIA_SERVER == 1 ));
    then
        # Install Python just in case
        python_tools
    fi
    
    "$HOME_PATH/.local/bin/gdown" "$download_link"

    
    if [[ ! -f "$file_name" ]]
    then
        echo "Cannot download Emacs Debian. Aborting."
        return
    else
        sudo dpkg -i "$TEMP_DOWNLOAD_PATH/$file_name"
        sudo apt install --fix-broken
        echo "Complete!"
    fi

    # Now return
    cd_or_exit "$CURRENT_PATH"
}

function install_emacs_dependencies() {
    sudo apt install libjansson-dev "libgccjit-${GCC_VERSION}-dev" -y
    sudo apt install libclang-dev clangd-"${CLANG_VERSION}" -y
    sudo apt install libwebkit2gtk-4.0-dev -y
    sudo apt install libjpeg-dev libtiff-dev libncurses-dev texinfo libxpm-dev libwebp-dev -y
    sudo apt install libmagickcore-dev libmagick++-dev -y
    sudo apt install mailutils -y
    sudo apt install opus-tools -y

}

function compile_emacs_from_source() {
    mkdir -p "$TEMP_DOWNLOAD_PATH"

    cd_or_exit "$TEMP_DOWNLOAD_PATH"
    # cd "$TEMP_DOWNLOAD_PATH"

    mkdir -p "$TEMP_DOWNLOAD_PATH/EMACS"
    cd_or_exit "$TEMP_DOWNLOAD_PATH/EMACS"

    git clone https://git.savannah.gnu.org/git/emacs.git
    
    mkdir -p "build" && cd_or_exit "build"
    
    # Call autogen:
    ../emacs/autogen.sh

    # Now call configure here:
    ../emacs/configure --with-mailutils --with-json --with-native-compilation --with-x --with-xwidgets --with-imagemagick


    # Now make it
    (make -j4 && sudo make install) || (echo "Could not make emacs. Aborting.")

    # Now return to the original path
    cd_or_exit "$CURRENT_PATH"
    # cd "$CURRENT_PATH"
   
}

function install_emacs() {
    echo "First installing Dependencies."
    install_emacs_dependencies


    read -r -n2 -p "Do you want me to install emacs through a personal debian file? [y/n]" user_input
    if [[ $user_input =~ [yY] ]]
    then
        install_emacs_debian
    else
        read -r -n2 -p "How about installing the default emacs for your distribution? [y/n]" user_input
        
        if [[ $user_input =~ [yY] ]]
        then
            echo "Alright then, It shouldn't take long."
            sudo apt install emacs -y
        else
            read -r -n2 -p "How about compiling it from source? [y/n] " user_input

            if [[ $user_input =~ [yY] ]]
            then
                compile_emacs_from_source
            else
                echo "Alright, you're on your own then."
            fi
            
        fi
    fi

    # Now return back to CURRENT_PATH just in case:
    cd_or_exit "$CURRENT_PATH"
}

    

function golang-tools() {
    sudo add-apt-repository ppa:longsleep/golang-backports -y
    sudo apt update
    sudo apt install golang-go -y
           
}

function java_tools() {
    for i in "${JAVA_VERSION_LIST[@]}"
    do
	sudo apt install "openjdk-${i}-jdk" -y
    done

}

function javascript_tools() {
    # For more information, go to
    # https://github.com/nodesource/distributions/blob/master/README.md
    mkdir -p "$TEMP_DOWNLOAD_PATH"
    cd_or_exit "$TEMP_DOWNLOAD_PATH"
       
    curl -sL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" -o nodesource_setup.sh
    chmod +x ./nodesource_setup.sh
    sudo ./nodesource_setup.sh
    
    sudo apt install nodejs -y

    cd_or_exit "$CURRENT_PATH"

}

function install_googletest() {
    
    mkdir -p "$TEMP_DOWNLOAD_PATH"
    cd_or_exit "$TEMP_DOWNLOAD_PATH"
    # cd "$TEMP_DOWNLOAD_PATH"
    
    # Clone and build googletest.
    git clone https://github.com/google/googletest.git
    cmake .
    make

    # I would recommend using checkinstall manually to install this,
    # but you can also just do sudo make install at your peril.
    sudo make install

    # Now return
    cd_or_exit "$CURRENT_PATH"
}    

function cpp_tools {    
    sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
    sudo apt install "g++-${GCC_VERSION}" "gcc-${GCC_VERSION}" -y

    # In order to allow clangd to work, you have to add the most recent corresponding
    # libstdc++ version. Otherwise, you'll get strange errors like
    # iostream header not found or whatever randomly.
    # NOTE: If this start happening out of nowhere, check if the latest libstdc++ has been installed.
    sudo apt install "libstdc++-${GCC_VERSION}-dev" -y
    sudo apt install "clang-${CLANG_VERSION}" -y
    sudo apt install valgrind -y
    sudo apt install cppman -y

    cppman --cache-all &
    
    sudo apt install libboost-all-dev -y
    sudo apt install cmake -y
    sudo apt install libspdlog-dev -y

    # For Doxygen:
    sudo apt install doxygen-* -y
    sudo apt install graphviz -y

    install_googletest
}

function php_tools() {
    # Repo for PHP:
    sudo apt install software-properties-common -y
    sudo add-apt-repository ppa:ondrej/php -y

    # If using apache, do this:
    # sudo apt update
    # sudo apt install php8.0 libapache2-mod-php8.0
    # For more information, go to https://linuxize.com/post/how-to-install-php-8-on-ubuntu-20-04/
    
    sudo apt install "php${PHP_VERSION}-dev" -y
    sudo apt install "php${PHP_VERSION}-*" -y

}


function csharp_tools() {
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


    cd_or_exit "$HOME_PATH"
    # cd "$HOME_PATH"

}

function python_tools() {
    sudo apt install python3-pip -y
    sudo apt install python3-venv -y

    # Establish python lsp server
    python3 -m pip install --user python-lsp-server

    # Symlink pylsp to pyls in order for lsp-mode to locate it.
    # You may need to change this in the future.
    ln -s ~/.local/bin/pylsp ~/.local/bin/pyls

    # Install some pip packages:

    python3 -m pip install gdown
    python3 -m pip install jupyterlab
    python3 -m pip install ipython
    python3 -m pip install numpy
    python3 -m pip install ipdb
    python3 -m pip install tldr

}

function sql_tools() {

    sudo apt install mariadb-server -y
    sudo apt install "postgresql-${POSTGRES_VERSION}" -y
    sudo apt install pgadmin3 -y

    # Now install mysql workbench:
    sudo snap install mysql-workbench-community
}



function programming_tools() {
    echo_wait "Now installing some Programming libraries and tools."
    # C/C++
    cpp_tools

    # C#
    csharp_tools

    # Golang
    golang-tools
    
    # Java
    java_tools

    # JavaScript
    javascript_tools
      
    # PHP
    php_tools

    # Python
    python_tools
       
    # Racket
    sudo apt install racket -y

    # Static Analyzer for bash
    sudo apt install shellcheck -y

    # SQL
    sql_tools

    
    # Text Editors
    install_text_editors


    # Just to make sure, return back to your current path:
    cd_or_exit "$CURRENT_PATH"
}

# ------------------------------------------------------------------------------
# Additional Tools
# ------------------------------------------------------------------------------

function audiovisual_tools() {
    echo_wait "Installing some more tools..."
    
    if (( IS_DESKTOP == 1 ));
    then
        sudo apt install kdenlive -y
        sudo apt install audacity -y
        sudo add-apt-repository ppa:otto-kesselgulasch/gimp -y
        sudo apt install gimp -y
        sudo apt install easytag -y
	sudo add-apt-repository ppa:obsproject/obs-studio -y
	sudo apt-get install obs-studio -y	
    fi


    sudo apt-get install pavucontrol -y
    
}

function install_yacreader() {
    echo 'deb http://download.opensuse.org/repositories/home:/selmf/xUbuntu_22.04/ /' | sudo tee /etc/apt/sources.list.d/home:selmf.list
    curl -fsSL https://download.opensuse.org/repositories/home:selmf/xUbuntu_22.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_selmf.gpg > /dev/null
    sudo apt update
    sudo apt install yacreader -y
}

function manual_debians() {
    echo_wait "Now downloading and installing some .deb files that have to be installed manually."
    
    # Create the download path if it exists.
    mkdir -p "$TEMP_DOWNLOAD_PATH"
    
    cd "$TEMP_DOWNLOAD_PATH" || (echo "Could not enter $TEMP_DOWNLOAD_PATH. Exiting." && exit)

    if (( IS_DESKTOP == 1 ));
    then
        # Discord
        wget -O "discord-recent-version.deb" "https://discord.com/api/download?platform=linux&format=deb"

        # Strawberry
        wget "https://files.strawberrymusicplayer.org/strawberry_1.0.5-jammy_amd64.deb"

        # Minecraft
        wget "https://launcher.mojang.com/download/Minecraft.deb"

        # TeamViewer:
        wget "https://download.teamviewer.com/download/linux/teamviewer_amd64.deb"
        
    fi

    # --------------------------------------
    # VNC Server and Client:
    # --------------------------------------
    
    # VNC Client
    # Grab the newest debian: (Warning: If the site is messed up, you're fucked...)

    # curl --silent https://www.realvnc.com/en/connect/download/viewer/ | grep "DEB x64" | grep -Eo -e "data-file=\"[^\>]*" | awk -F "=" '{print $2;}
    vnc_link=$(curl --silent https://www.realvnc.com/en/connect/download/viewer/ | grep "DEB x64" | grep -Eo -e "data-file=\"[^\>]*" | awk -F "=" '{print $2;}')
    if [[ -z "$vnc_link" ]]
    then
        vnc_link="https://downloads.realvnc.com/download/file/viewer.files/VNC-Viewer-${VNC_VERSION}-Linux-x64.deb"
    fi

    wget "$vnc_link"


    # Now grab the latest VNC Server debian:
    # curl --silent "https://www.realvnc.com/en/connect/download/vnc/" | grep "DEB x64" | grep -Eo -e "data-file=\"[^\>]*" | awk -F "=" '{print $2;}'
    vnc_link=$(curl --silent "https://www.realvnc.com/en/connect/download/vnc/" | grep "DEB x64" | grep -Eo -e "data-file=\"[^\>]*" | awk -F "=" '{print $2;}')
    if [[ -z "$vnc_link" ]]
    then
        vnc_link="https://downloads.realvnc.com/download/file/vnc.files/VNC-Server-${VNC_VERSION}-Linux-x64.deb"
    fi
    
    
    # --------------------------------------    
    # ProtonVPN
    # --------------------------------------
    
    wget "https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.3-2_all.deb"

    checksum_result=$(echo "c68a0b8dad58ab75080eed7cb989e5634fc88fca051703139c025352a6ee19ad  protonvpn-stable-release_1.0.3-2_all.deb" | sha256sum --check -)
    if [[ "$checksum_result" != "protonvpn-stable-release_1.0.3-2_all.deb: OK" ]];
    then
        echo "Checksum for ProtonVPN Debian doesn't check out; Deleting file."
        rm -v "protonvpn-stable-release_1.0.3-2_all.deb"
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
	sudo apt install steam-installer dolphin-emu -y        
        sudo add-apt-repository ppa:pcsx2-team/pcsx2-daily -y
        sudo apt update
        sudo apt install pcsx2-unstable -y
	
    fi

    if (( IS_DESKTOP == 1 ));
       then
           sudo add-apt-repository ppa:libretro/stable -y
           sudo apt install libretro-* -y
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

    wget "https://downloads.plex.tv/plex-media-server-new/${PLEX_VERISON}/debian/plexmediaserver_${PLEX_VERISON}_amd64.deb"

    if [[ ! -f "plexmediaserver_${PLEX_VERISON}_amd64.deb" ]]
    then
        echo "Error: Could not download plexmediaserver_${PLEX_VERISON}_amd64.deb. Aborting."
        return        
    fi

    sudo dpkg -i "plexmediaserver_${PLEX_VERISON}_amd64.deb"
    
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

    echo "Now adding /swapfile to /etc/fstab"
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab 
    
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
    appearance_tools
    programming_tools
    audiovisual_tools
    brave_browser
    vidya
    snap_ides
    snap_applications
    manual_debians
    install_fcron
    increase_swap_size
}


function media_server_installation() {
    echo "Media Server Installation"
    update_first
    
    graphic_drivers
    essential_programs
    appearance_tools
    audiovisual_tools
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

# Check if the OS is a Ubuntu derived Linux distribution using python's platform module.
# Will exit if the machine fails the check.
function check_ubuntu_distribution() {
    # Use grep to search for Ubuntu or Debian in the output of distro or platform.
    (python3 -m distro | grep -io -e "ubuntu"  >/dev/null && print_menu) ||
	(python -m platform | grep -io -e "ubuntu" > /dev/null && print_menu) ||
	(echo "This shell script will only work on a Ubuntu Distribution." && exit 1)

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

function print_menu() {
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
check_ubuntu_distribution
