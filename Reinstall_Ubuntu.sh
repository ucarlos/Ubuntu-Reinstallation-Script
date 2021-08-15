#!/bin/bash
# ------------------------------------------------------------------------------
# Created by Ulysses Carlos on 11/21/2020 at 11:49 PM
#
# Reinstall_Ubuntu.sh
# This is essentially a more user friendly version of New_installation.sh
# Which reinstalls all the programs I would want in a Linux Reinstallation.
# It covers normal Desktop and Laptop Installations, along with a minimal build
# if I wanted to. This requires that the installation uses apt.
# ------------------------------------------------------------------------------

version_num="0.05"
dash_line_len=80
current_path=$(pwd)
user_name=$(echo "$USER")
download_path="/home/$user_name/Downloads/"
home_path="/home/$user_name/"

# 0 is false, while 1 is true
is_desktop=1
is_server=0

# Set the gcc_version
GCC_VERSION="11"
CLANG_VERSION="10"
EMACS_VERSION="27"

function echo_wait(){
    echo "$1"
    sleep 1
}

function print_dashed_line(){
    for ((i = 1; i <= dash_line_len; i++));
    do
	printf "-"
    done
    echo ""
    
}

function graphic_drivers(){
    echo_wait "Installing Graphic Drivers."
    sudo ubuntu-drivers autoinstall
}

function essential_programs(){
    echo_wait "Installing some Essential Programs."
    if (( is_server != 1 ));
       then
	    sudo apt install deja-dup duplicity htop mpv git -y
    fi
    
    sudo apt install tmux gedit net-tools -y
    sudo apt install fdupes -y
    sudo apt install neofetch screenfetch -y
    sudo apt install texlive-latex-base texlive-latex-extra -y
    sudo apt install texlive-latex-recommended -y
    sudo apt install ttf-mscorefonts-installer -y
    sudo apt install openssh-server -y
    sudo apt install usb-creator-gtk -y
    sudo apt install checkinstall -y
}    

function appearance_tools(){
    if (( is_desktop == 1 ));
    then
	sudo apt install lightdm gnome-tweaks gnome-shell-extensions -y
	sudo apt install chome-gnome-shell -y
	sudo apt install dconf-editor -y

    fi
    
    sudo apt install fonts-firacode -y

    if (( is_server != 1 ));
    then
	sudo add-apt-repository -u ppa:snwh/ppa -y
	sudo apt install paper-icon-theme arc-theme -y
	sudo apt install variety -y
    fi

}

function brave_browser(){
    echo_wait "Now installing Brave Browser."
    sudo apt install apt-transport-https curl -y
    
    curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -

    echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list

    sudo apt update && sudo apt install brave-browser -y
}

function install_text_editors() {
    # Neovim
    sudo apt install neovim -y
    install_emacs

}     

function install_emacs(){

    
    echo "Would you like me to compile emacs on your system? [y/n] "
    read -r -n1 user_input
    if [[ $user_input == "y" ]];
    then
	echo_wait "I'll just clone the repository in $download_path. It's up to you to install the appropriate libraries."
	cd "$download_path" || (echo "Could not enter $download_path. Exiting." && exit)
	(mkdir "Emacs" && cd "Emacs)") || (echo "Could not change into directory. Exiting." && exit 1)
	git clone https://git.savannah.gnu.org/git/emacs.git
	
    else
	echo "Then would you like me to install emacs${EMACS_VERSION} at all? [y/n] "
	read -r -n1 user_input

	if [[ $user_input == "y" ]];
	   then
	       echo "Alright then, I'll just setup the repository and install Emacs ${EMACS_VERSION}."
	       sudo add-apt-repository ppa:kelleyk/emacs -y
	       sudo apt install "emacs${EMACS_VERSION}" -y
	else
	    echo "Do you plan on installing Emacs on this machine in any way? [y/n] "
	    read -r -n1 user_input


	    if [[ "$user_input" == "y" ]];
	    then
		echo_wait "Alright. If you've already compiled emacs or plan to use a debian file made by checkinstall, I'll set everything up."
		echo_wait "Also, I'll installing some stuff for lsp-mode since you use emacs for C/C++ Development."
		install_emacs_dependencies
		return
	    else
		echo_wait "Moving on..."
		return
	    fi
	fi
    fi

    echo_wait "Next, I'll install some additional packages needed for Emacs."
    install_emacs_dependencies
    
}

function install_emacs_dependencies() {
    sudo apt install libjansson-dev "libgccjit-${GCC_VERSION}-dev" -y
    sudo apt install libclang-dev clangd-"${CLANG_VERSION}" -y
    sudo apt install libwebkit2gtk-4.0-dev -y    
    sudo apt install mailutils -y
    sudo apt install opus-tools -y

}    

function programming_tools(){
    echo_wait "Now installing some Programming libraries and tools."
    # Java
    sudo apt install openjdk-8-jdk openjdk-11-jdk -y
    
    # Text Editors
    install_text_editors

    # Python
    python_tools
    
    # C/C++
    cpp_tools

    # PHP
    php_tools

    # NPM for language servers:
    sudo apt install npm -y
    
    # Rust 
    sudo apt install racket -y
    sudo apt install curl -y

    # Static Analyzer for bash
    sudo apt install shellcheck -y
}

function cpp_tools() {    
    sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
    sudo apt install "g++-${GCC_VERSION}" "gcc-${GCC_VERSION}" -y
    
    sudo apt install valgrind -y
    sudo apt install cppman -y
    sudo apt install libboost-dev -y
    sudo apt install cmake -y

    # For Doxygen:
    sudo apt install doxygen-* -y
    sudo apt install graphviz -y


    # Clone and build googletest.
    mkdir -p "$download_path"
    cd "$download_path"    
    git clone https://github.com/google/googletest.git
    cmake .
    make

    # I would recommend using checkinstall manually to install this,
    # but you can also just do sudo make install at your peril.
    # sudo make install

    # Now return
    cd "$current_path" || (echo "Some error occurred in cpp_tools." && exit 1)
}

function php_tools() {
    sudo apt install php-dev -y
    sudo apt install php-mysql -y

}    

function python_tools() {
    sudo apt install ipython3 python3-pip -y
    sudo apt install python3-venv -y

    # Establish python lsp server
    python3 -m pip install --user python-lsp-server

    # Symlink pylsp to pyls in order for lsp-mode to locate it.
    # You may need to change this in the future.
    ln -s ~/.local/bin/pylsp ~/.local/bin/pyls
    
}

function more_tools(){
    echo_wait "Installing some more tools..."
    sudo apt install kdenlive -y
    sudo apt install audacity -y
    sudo add-apt-repository ppa:otto-kesselgulasch/gimp -y
    sudo apt install gimp -y
    sudo apt install easytag -y

    sudo apt install hexchat filezilla -y
    sudo apt install gnome-disks -y
    sudo apt-get install pavucontrol spek -y  

    if (( is_desktop == 1 ));
    then
	sudo add-apt-repository ppa:obsproject/obs-studio -y
	sudo apt-get install obs-studio -y	
    fi


    echo_wait "Installing Calibre Library..."
    sudo -v && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin    
    
}    

function manual_debians(){
    echo_wait "Now downloading and installing some .deb files that have to be installed manually."
    
    # Create the download path if it exists.
    mkdir -p "$download_path"
    
    cd "$download_path" || (echo "Could not enter $download_path. Exiting." && exit)

    # VNC Client
    wget https://www.realvnc.com/download/file/viewer.files/VNC-Viewer-6.20.529-Linux-x64.deb
    sudo dpkg -i VNC-Viewer-6.20.529-Linux-x64.deb


    # VNC server
    wget https://www.realvnc.com/download/file/vnc.files/VNC-Server-6.7.2-Linux-x64.deb

    # TODO: Install Yaccreader using wget
    
    # Now attempt to install each debian file:
    yes | sudo dpkg -Ri .
    
    cd "$current_path" || (echo "Could not enter $current_path. Exiting." && exit)
}    

function vidya(){
    echo_wait "Now installing Steam and some emulators!"
    if (( is_desktop == 1 ));
    then	
	sudo apt install steam dolphin-emu -y
	
    fi
    
    sudo add-apt-repository ppa:libretro/stable -y
    sudo apt install libretro-* -y
    sudo apt install retroarch -y

    echo "Now, I would like to install wine on your system, but each Ubuntu version requires a different repository. Instead, I'll just enable 32-bit architecture and add the repository key."
    sudo dpkg --add-architecture i386
    cd "$home_path" || (echo "Could not enter $home_path... Exiting." && exit)
    wget -nc https://dl.winehq.org/wine-builds/winehq.key
    sudo apt-key add winehq.key
    cd "$current_path" || (echo "Could not enter $current_path... Exiting." && exit)
}

# Handles installing IDEs through snap.
function snap_ides() {
    echo_wait "Now installing snap programs..."
    sudo snap install clion --classic
    sudo snap install pycharm-community --classic
    sudo snap install code --classic
    sudo snap install android-studio --classic
    sudo snap install intellij-idea-ultimate --classic
    sudo snap install rider --classic


}    

# Handles applications that can run through the command line.
function snap_applications() {
    sudo snap install dotnet-sdk --classic
    sudo snap alias dotnet-sdk.dotnet dotnet
}

function desktop_installation(){
    echo "Desktop Installation"
    graphic_drivers
    essential_programs
    appearance_tools
    programming_tools
    more_tools
    brave_browser
    vidya
    snap_ides
    snap_applications
    manual_debians
}


function laptop_installation(){
    echo "Laptop Installation"
    essential_programs
    appearance_tools
    programming_tools
    more_tools
    brave_browser
    vidya
    snap_ides
    snap_applications
    manual_debians
}

function server_installation() {
    essential_programs
    programming_tools
    appearance_tools
    snap_applications
}    

# Check if the OS is a Debian derived Linux distribution using python's platform module.
# Will exit if the machine fails the check.
function check_debian_distribution() {
    # Use grep to search for Ubuntu or Debian in the output of distro or platform.
    (python3 -m distro | grep -io -e "ubuntu" -e "debian" >/dev/null && print_menu) ||
	(python -m platform | grep -io -e "ubuntu" -e "debian" > /dev/null && print_menu) ||
	(echo "This shell script will only work on a Debian or Ubuntu Distribution." && exit 1)

}

function print_menu(){
    echo "The Current Time is $(date +'%m/%d/%Y %H:%M')"    
    print_dashed_line
    echo "Ubuntu Reinstallation (Version $version_num)"
    print_dashed_line
    echo "Options:"
    echo "a) Default Desktop Installation"
    echo "b) Default Laptop Installation"
    echo "c) Minimal Server Installation"
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
	is_desktop=0
	laptop_installation
    elif [[ "$user_input" == "c" ]];
    then
	is_desktop=0
	is_server=1
	server_installation
    else
	echo "Exiting..."
	exit
    fi
    
    echo_wait "Complete! Now make sure to swap CTRL and CAPSLOCK using GNOME tweaks or use the method below."    
    print_dashed_line
    
    echo '

    Open the following for editing:

    sudo vi /etc/default/keyboard

    And edit XKBOPTIONS="ctrl:swapcaps"

    Then, reconfigure:

    sudo dpkg-reconfigure keyboard-configuration

    or

    /usr/bin/setxkbmap -option "ctrl:swapcaps"'
    print_dashed_line
}


# Now run the script:
check_debian_distribution
