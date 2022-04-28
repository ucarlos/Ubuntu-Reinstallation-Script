#!/bin/bash
# ------------------------------------------------------------------------------
# Created by Ulysses Carlos on 07/04/2021 at 12:30 PM
#
# Reinstall_Pi4.sh
#
# This is a new bash script in order to handle reinstalling all necessary
# programs for the Raspberry Pi. This includes Setting up Kodi, Development
# Environment, and what have you.
# ------------------------------------------------------------------------------

VERSION="2022-03-20"
dash_line_len=80
current_path=$(pwd)
user=$(echo "$USER")


download_path="/home/$user/Downloads/"
temp_download_path="/tmp/Downloads"

home_path="/home/$user/"

function echo_wait() {
    echo "$1"
    sleep 1
}

function print_dash_lines() {
    for ((i = 1; i <= dash_line_len; i++));
    do
	printf "-"
    done
    echo ""
}


function programming_tools() {
    echo_wait "Now installing some Programming libraries and tools."
    sudo apt install openjdk-8-jdk openjdk-11-jdk -y
    sudo apt install neovim -y
    sudo apt install ipython3 python3-pip -y
    sudo apt install valgrind -y
    sudo apt install libboost-dev -y
    sudo apt install racket -y
    sudo apt install curl -y
    sudo apt install cmake -y
    sudo apt install doxygen-* -y
    sudo apt install graphviz -y
    sudo apt install shellcheck -y

    install_fcron
    install_emacs_debian

}

function essential_programs() {
    echo_wait "Now install some essential programs."
    sudo apt install -y deja-dup duplicity git
    sudo apt install -y neofetch screenfetch
    sudo apt install htop mpv -y
    sudo apt install tmux gedit net-tools -y
    sudo apt install neofetch screenfetch -y
    sudo apt install texlive-latex-base texlive-latex-extra -y
    sudo apt install texlive-latex-recommended -y
    sudo apt install ttf-mscorefonts-installer -y
    sudo apt install openssh-server -y        
    sudo apt install gnome-disks -y
    sudo apt install pavucontrol spek -y    
    sudo apt install -y dkms
    sudo apt install -y bleachbit
    sudo apt install -y transmission
    sudo apt install -y qbittorrent
    sudo apt install -y checkinstall
    sudo apt install -y texinfo libncurses-dev
    sudo apt install p7zip-full unrar -y

}

function install_fcon() {
    echo_wait "Installing fcron. This will take a while..."
    mkdir -p "$temp_download_path"   
    cd "$temp_download_path"
    
    echo_wait "Installing Fcron Dependencies."
    sudo apt install git autoconf docbook docbook-xsl docbook-utils manpages-dev -y

    # Download the tarball and extract it.
    wget "http://fcron.free.fr/archives/fcron-3.3.0.src.tar.gz"
    tar -xvf "fcron-3.3.0.src.tar.gz"

    # Now install the damn thing.
    cd "fcron-3.3.0" && ./configure && make && sudo make install

    # Now return to previous directory:
    cd "$current_path"       
}     

function install_emacs_debian() {
    mkdir -p "$temp_download_path" && cd "$temp_download_path"
    download_link="https://drive.google.com/uc?id=1SksczkGyCqkxMQQjhq5GyFY48D2jSTI_&export=download"
    file_name="emacs29_29.0.5-1_native-comp_armhf.deb"
    
    "$home_path/.local/bin/gdown" "$download_link"

    
    if [[ ! -f "$file_name" ]]
    then
        echo "Cannot download Emacs Debian. Aborting."
        return
    else
        sudo dpkg -i "$temp_download_path/$file_name"
        sudo apt install --fix-broken
        echo "Complete!"
    fi
}


function entertainment() {
    echo_wait "Now installing Kodi, Steamlink, and Retropie (If not installed yet)"
    sudo apt install kodi-* steamlink -y
    

    cd "$home_path"
    if [[ ! -d "RetroPie-Setup" ]];
    then
	echo_wait "Downloading Retropie. You need to set it up yourself."
	git clone --depth=1 https://github.com/RetroPie/RetroPie-Setup.git
	(cd "RetroPie-Setup" && chmod +x "retropie_setup.sh" && ./retropie_setup.sh) || (echo "Could not dive into RetroPie-Setup. You're on your own.")	
    fi

}

function install_xfce() {
    #Download and install Paper icon theme:
    # wget 'https://launchpadlibrarian.net/468844787/paper-icon-theme_1.5.728-202003121505~daily~ubuntu18.04.1_all.deb'
    # sudo dpkg -i paper-*.deb
    # sudo apt install -f
    sudo apt install -y arc-theme plank
    sudo apt install xfce4 xfce4-terminal -y
    sudo apt-get install xfce4-whiskermenu-plugin -y
    # echo "Now please change into xfce4."
    # sudo update-alternatives --config x-session-manager


}



function install_lxde() {
    # Install the default DE for Raspberry Pi.
    sudo apt install raspberrypi-ui-mods
    sudo apt install arandr -y
    sudo apt install fonts-firacode -y
    sudo apt install -y gnome-screensaver
   
}



appearance() {
    install_lxde
    # install_xfce
    
}

install_debians() {
    # Install all debians in the deb folder:
    if [[ -f "./deb" ]];
    then
	echo "deb folder found. Installing any debians found."
	sudo dpkg --recursive -i "deb"
    fi    
}

print_menu(){
    echo "The Current Time is $(date +'%m/%d/%Y %H:%M')"    
    print_dash_lines
    echo "Raspberry Pi 4 Reinstallation (Version $version_num)"
    print_dash_lines
    
}

installation() {
    print_menu
    essential_programs
    programming_tools
    entertainment
    # appearance    
}

# Run the script.
installation
