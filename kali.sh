#!/bin/bash
#-Metadata----------------------------------------------------#
#  Filename: kali.sh                     (Update: 2018-05-24) #
#-Info--------------------------------------------------------#
#  Custom post-install script for Kali Linux Rolling          #
#-Author(s)---------------------------------------------------#
#  Brutal                                                     #
#-Operating System--------------------------------------------#
#  Designed for: Kali Linux Rolling [x64] (VM - VMware)       #
#     Tested on: Kali Linux 2018.2 x64/x84/full/light/mini/vm #
#-Licence-----------------------------------------------------#
#  MIT License ~ http://opensource.org/licenses/MIT           #
#-Notes-------------------------------------------------------#
#  Run as root straight after a clean install of Kali Rolling #
#                             ---                             #
#  You will need 25GB+ free HDD space before running.         #
#                             ---                             #
#  Command line arguments:                                    #
#    -burp     = Automates configuring Burp Suite (Community) #
#    -dns      = Use OpenDNS and locks permissions            #
#                                                             #
#  e.g. # bash kali.sh -burp                                  #
#-------------------------------------------------------------#
### Globals
# Optional steps
burpFree=false              # Disable configuring Burp Suite (for Burp Pro users...)    [ --burp ]
hardenDNS=false             # Set static & lock DNS name server                         [ --dns ]

# (Optional) Enable debug mode?
#set -x

START_TIME=$(date +%s)
STAGE=0  # what stage are we up to
SKIPPED=0  # count of impossible to hit stages
TOTAL=$( grep '(( STAGE++ ))' $0 | wc -l );(( TOTAL-- ))  # How many things have we got todo

# Read command line arguments
while [[ "${#}" -gt 0 && ."${1}" == .-* ]]; do
  opt="${1}";
  shift;
  case "$(echo ${opt} | tr '[:upper:]' '[:lower:]')" in
    -|-- ) break 2;;

    -dns|--dns )
      hardenDNS=true;;

    -burp|--burp )
      burpFree=true;;

    *) write_output "Unknown option: $x" "error" && exit 1;;
   esac
done

### Functions
write_output(){
	message=$1; shift
	message_type=$1; shift

	# Regular Colors
	Red="\033[1;31m[-]"          # Red Errors/issues
	Green="\033[1;32m[+]"        # Green Sucess
	Yellow="\033[1;33m[i]"       # Yellow Info/Warning
	Blue="\033[1;34m"            # Blue
	Cyan="\033[1;36m[!]"         # Cyan Headings

	# Reset
	Color_Off="\033[0m"       # Text Reset

	case $message_type in
		'error')
			echo -e "${Red} ${message} ${Color_Off}";;
		'warning')
			echo -e "${Yellow} ${message} ${Color_Off}";;
		'header')
			echo -e "${Cyan} ${message} ${Color_Off}";;
		*)
			echo -e "${Green} ${message} ${Color_Off}";;
	esac
}

install_software() {
	description=$1; shift
	count=$1; shift
	total=$1; shift

	write_output "($count/$total) Installing $description"
	apt -y -qq install $@ || write_output "Issue with apt install" "error"
}

git_install_software(){
	description=$1; shift
	url=$1; shift
	opt_folder=$1; shift
	count=$1; shift
	total=$1; shift

	write_output "($count/$total) Cloning $description"
	git clone -q -b master $url /opt/$opt_folder || write_output "Issue with git cloning" "error"
	pushd /opt/$opt_folder >/dev/null
	git pull -q
	popd >/dev/null
}

install_apt_extras(){
	# Install bash completion - all users
	(( STAGE++ )); install_software "bash completion ~ tab complete CLI commands" $STAGE $TOTAL bash-completion
	file=/etc/bash.bashrc; [ -e "${file}" ] && cp -n $file{,.bkup}  #~/.bashrc
	sed -i '/# enable bash completion in/,+7{/enable bash completion/!s/^#//}' "${file}"
	# apply new configs
	source "${file}" || source ~/.zshrc

	# Install exe2hex
	(( STAGE++ )); install_software "exe2hex ~ Inline file transfer" $STAGE $TOTAL exe2hexbat

	# Install MPC
	(( STAGE++ )); install_software "MPC${RESET} ~ Msfvenom Payload Creator" $STAGE $TOTAL msfpc

	# Install wdiff
	(( STAGE++ )); install_software "wdiff ~ Compares two files word by word" $STAGE $TOTAL wdiff wdiff-doc

	# Install virtualenvwrapper
	(( STAGE++ )); install_software "virtualenvwrapper ~ virtual environment wrapper" $STAGE $TOTAL virtualenvwrapper

	# Install sparta
	(( STAGE++ )); install_software "sparta ~ GUI automatic wrapper" $STAGE $TOTAL sparta

	# Install wireshark
	(( STAGE++ )); install_software "Wireshark ~ GUI network protocol analyzer" $STAGE $TOTAL wireshark
	# Hide running as root warning
	mkdir -p ~/.wireshark/
	file=~/.wireshark/recent_common; 
	[ -e "${file}" ] || echo "privs.warn_if_elevated: FALSE" > "${file}"
	# Disable lua warning
	[ -e "/usr/share/wireshark/init.lua" ] && mv -f /usr/share/wireshark/init.lua{,.disabled}

	# Install WINE
	(( STAGE++ )); install_software "WINE ~ run Windows programs on *nix" $STAGE $TOTAL wine winetricks
	# Using x64?
	if [[ "$(uname -m)" == 'x86_64' ]]; then
		dpkg --add-architecture i386
		apt -qq update
		(( STAGE++ )); install_software "WINE (x64)" $STAGE $TOTAL wine32
	else
		(( SKIPPED++ ))
	fi
	# Run WINE for the first time
	[ -e /usr/share/windows-binaries/whoami.exe ] && wine /usr/share/windows-binaries/whoami.exe &>/dev/null
	# Setup default file association for .exe
	file=~/.local/share/applications/mimeapps.list; [ -e "${file}" ] && cp -n $file{,.bkup}
	([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
	echo -e 'application/x-ms-dos-executable=wine.desktop' >> "${file}"

	# Install WPScan
	(( STAGE++ )); install_software "WPScan ~ Wordpress Scanner" $STAGE $TOTAL wpscan

	# Install htop
	(( STAGE++ )); install_software "htop ~ CLI process viewer" $STAGE $TOTAL htop

	# Install p7zip & zip & unzip
	(( STAGE++ )); install_software "zip utilities ~ CLI file extractor" $STAGE $TOTAL p7zip-full zip unzip unrar

	# Install hashid
	(( STAGE++ )); install_software "hashid~ identify hash types" $STAGE $TOTAL hashid

	# Install wifite
	(( STAGE++ )); install_software "wifite ~ automated Wi-Fi tool" $STAGE $TOTAL wifite

	# Install unicornscan
	(( STAGE++ )); install_software "unicornscan ~ fast port scanner" $STAGE $TOTAL unicornscan

	# Install gobuster
	(( STAGE++ )); install_software "gobuster ~ Directory/File/DNS busting tool" $STAGE $TOTAL gobuster

	# Install gcc & multilib
	(( STAGE++ )); install_software "gcc & multilibc ~ compiling libraries" $STAGE $TOTAL gcc
	for package in cc g++ gcc-multilib make automake libc6 libc6-dev libc6-amd64 libc6-dev-amd64 libc6-i386 libc6-dev-i386 libc6-i686 libc6-dev-i686 build-essential dpkg-dev; do
		apt -y -qq install $package 2>/dev/null
	done

	# Install MinGW ~ cross compiling suite
	(( STAGE++ )); install_software "MinGW ~ cross compiling suite" $STAGE $TOTAL mingw-w64 
	for package in binutils-mingw-w64 gcc-mingw-w64 cmake mingw-w64-dev mingw-w64-tools gcc-mingw-w64-i686 gcc-mingw-w64-x86-64 mingw32; do
		apt -y -qq install $package 2>/dev/null
	done

	# Install the backdoor factory
	(( STAGE++ )); install_software "Backdoor Factory ~ bypassing anti-virus" $STAGE $TOTAL backdoor-factory

	# Install responder
	(( STAGE++ )); install_software "Responder ~ rogue server" $STAGE $TOTAL responder

	# Install checksec
	(( STAGE++ )); write_output "(${STAGE}/${TOTAL})Installing checksec ~ check *nix OS for security features"
	mkdir -p /usr/share/checksec/
	file=/usr/share/checksec/checksec.sh
	timeout 300 curl --progress -k -L -f "http://www.trapkit.de/tools/checksec.sh" > "${file}" || write_output "Issue downloading checksec.sh" "error"  #***!!! hardcoded patch
	chmod +x "${file}"

	# Install UACScript
	(( STAGE++ )); install_software "UACScript ~ UAC Bypass for Windows 7" $STAGE $TOTAL windows-binaries
	git_install_software "UACScript ~ UAC Bypass for Windows 7" "https://github.com/Vozzie/uacscript.git" "uacscript" $STAGE $TOTAL

	# Install vulscan script for nmap
	(( STAGE++ )); install_software "vulscan script for nmap ~ vulnerability scanner add-on" $STAGE $TOTAL nmap curl
	mkdir -p /usr/share/nmap/scripts/vulscan/
	timeout 300 curl --progress -k -L -f "http://www.computec.ch/projekte/vulscan/download/nmap_nse_vulscan-2.0.tar.gz" > /tmp/nmap_nse_vulscan.tar.gz \
	  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading file" 1>&2      #***!!! hardcoded version! Need to manually check for updates
	gunzip /tmp/nmap_nse_vulscan.tar.gz
	tar -xf /tmp/nmap_nse_vulscan.tar -C /usr/share/nmap/scripts/
	# Fix permissions (by default its 0777)
	chmod -R 0755 /usr/share/nmap/scripts/; find /usr/share/nmap/scripts/ -type f -exec chmod 0644 {} \;

	# Install veil framework
	(( STAGE++ )); install_software "veil-evasion framework ~ bypassing anti-virus" $STAGE $TOTAL veil-evasion
	mkdir -p /var/lib/veil-evasion/go/bin/
	touch /etc/veil/settings.py
	sed -i 's/TERMINAL_CLEAR=".*"/TERMINAL_CLEAR="false"/' /etc/veil/settings.py
}

root_check(){
	# Check if we're running as root
	if [[ "${EUID}" -ne 0 ]]; then
		write_output "This script must be run as root" "error"
		write_output "Quitting..." "error"
		exit 1
	else
		write_output "Kali Linux post-install script" "header"
		sleep 3s
	fi
}

internet_connectivity_check(){
	# Check Internet access
	(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Checking Internet access"

	# Can we ping google dns
	for i in {1..10}; do ping -c 1 -W ${i} google.com &>/dev/null && break; done

	# if we can't
	if [[ "$?" -ne 0 ]]; then
		write_output "Possible DNS issues(?)" "error"
		_TMP="true"
		_CMD="$(ping -c 1 8.8.8.8 &>/dev/null)"
		if [[ "$?" -ne 0 && "$_TMP" == "true" ]]; then
			_TMP="false"
			write_output "No Internet access" "error"
		fi
		_CMD="$(ping -c 1 www.google.com &>/dev/null)"
		if [[ "$?" -ne 0 && "$_TMP" == "true" ]]; then
			_TMP="false"
			write_output "Possible DNS Issues(?)" "error"
		fi
		if [[ "$_TMP" == "false" ]]; then
  			write_output "You will need to manually fix the issue, before re-running this script" "error"
    		(dmidecode | grep -iq virtual) && write_output "VM Detected" "warning"
    		(dmidecode | grep -iq virtual) && write_output "Try switching network adapter mode (e.g. NAT/Bridged)"
    		exit 1
    	fi
	else
		write_output "Detected Internet access" "warning"
	fi

	# check if we can hit github
	(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Checking GitHub status"
	apt -y -qq install curl
	timeout 300 curl --progress -k -L -f "https://status.github.com/api/status.json" | grep -q "good" || (write_output "GitHub is currently having issues. Lots may fail. See: https://status.github.com/" && exit 1)
}

enable_network_repos(){
	# Enable default network repositories ~ http://docs.kali.org/general-use/kali-linux-sources-list-repositories
	(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Enabling default OS network repositories"
	# Add network repositories
	file=/etc/apt/sources.list; [ -e "${file}" ] && cp -n $file{,.bkup}
	([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
	# Main
	grep -q '^deb .* kali-rolling' "${file}" 2>/dev/null || echo -e "\n\n# Kali Rolling\ndeb http://http.kali.org/kali kali-rolling main contrib non-free" >> "${file}"
	# Source
	grep -q '^deb-src .* kali-rolling' "${file}" 2>/dev/null || echo -e "deb-src http://http.kali.org/kali kali-rolling main contrib non-free" >> "${file}"
	# Disable CD repositories
	sed -i '/kali/ s/^\( \|\t\|\)deb cdrom/#deb cdrom/g' "${file}"
	# incase we were interrupted
	dpkg --configure -a
	# Update
	apt -qq update
	if [[ "$?" -ne 0 ]]; then
		write_output "There was an issue accessing network repositories" "error"
		write_output "Are the remote network repositories currently being sync'd?" "warning"
		write_output "Here is YOUR local network repository information (Geo-IP based):\n" "warning"
		curl -sI http://http.kali.org/README
		exit 1
	fi
}

install_vm_drivers(){
	#Check to see if Kali is in a VM. If so, install "Virtual Machine Addons/Tools" for a "better" virtual experiment
	if (dmidecode | grep -iq vmware); then
		# Install virtual machines tools ~ http://docs.kali.org/general-use/install-vmware-tools-kali-guest
		(( STAGE++ )); install_software "VMware's (open) virtual machine tools" $STAGE $TOTAL open-vm-tools-desktop fuse make
		(( SKIPPED++ ))
	elif (dmidecode | grep -iq virtualbox); then
		# Installing VirtualBox Guest Additions. Note: Need VirtualBox 4.2.xx+ for the host (http://docs.kali.org/general-use/kali-linux-virtual-box-guest)
		(( STAGE++ )); install_software "VirtualBox's guest additions" $STAGE $TOTAL virtualbox-guest-x11
		(( SKIPPED++ ))
	else
		SKIPPED=$((SKIPPED+2))
	fi
}

harden_dns(){
	# Set static & protecting DNS name servers. Note: May cause issues with forced values (e.g. captive portals etc)
	if [[ "${hardenDNS}" != "false" ]]; then
		(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Setting static & protecting DNS name servers"
		file=/etc/resolv.conf; [ -e "${file}" ] && cp -n $file{,.bkup}
		chattr -i "${file}" 2>/dev/null
		# OpenDNS Servers
		# echo -e 'nameserver 208.67.222.222\nnameserver 208.67.220.220' > "${file}"
		# Google DNS Servers
		echo -e 'nameserver 8.8.8.8\nnameserver 8.8.4.4' > "${file}"
		chattr +i "${file}" 2>/dev/null
	else
		write_output "Skipping DNS hardening (missing: '$0 --dns')..." "warning"
		(( SKIPPED++ ))
	fi
}

configure_filebrowser(){
	# Configure file browser Note: need to restart xserver for effect
	(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Configuring file browser (Nautilus/Thunar) ~ GUI file system navigation"
	# Settings
	mkdir -p ~/.config/gtk-2.0/
	file=~/.config/gtk-2.0/gtkfilechooser.ini; [ -e "${file}" ] && cp -n $file{,.bkup}
	([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
	sed -i 's/^.*ShowHidden.*/ShowHidden=true/' "${file}" 2>/dev/null || cat <<-EOF > "${file}"
	[Filechooser Settings]
	LocationMode=path-bar
	ShowHidden=true
	ExpandFolders=false
	ShowSizeColumn=true
	GeometryX=66
	GeometryY=39
	GeometryWidth=780
	GeometryHeight=618
	SortColumn=name
	SortOrder=ascending
	EOF
	dconf write /org/gnome/nautilus/preferences/show-hidden-files true
	# Bookmarks
	file=/root/.gtk-bookmarks; [ -e "${file}" ] && cp -n $file{,.bkup}
	([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
	grep -q '^file:///root/Downloads ' "${file}" 2>/dev/null \
	  || echo 'file:///root/Downloads Downloads' >> "${file}"
	(dmidecode | grep -iq vmware) \
	  && (mkdir -p /mnt/hgfs/ 2>/dev/null; grep -q '^file:///mnt/hgfs ' "${file}" 2>/dev/null \
	    || echo 'file:///mnt/hgfs VMShare' >> "${file}")
	grep -q '^file:///tmp ' "${file}" 2>/dev/null \
	  || echo 'file:///tmp /TMP' >> "${file}"
	grep -q '^file:///usr/share ' "${file}" 2>/dev/null \
	  || echo 'file:///usr/share Kali Tools' >> "${file}"
	grep -q '^file:///opt ' "${file}" 2>/dev/null \
	  || echo 'file:///opt /opt' >> "${file}"
	grep -q '^file:///usr/local/src ' "${file}" 2>/dev/null \
	  || echo 'file:///usr/local/src SRC' >> "${file}"
	grep -q '^file:///var/ftp ' "${file}" 2>/dev/null \
	  || echo 'file:///var/ftp FTP' >> "${file}"
	grep -q '^file:///var/samba ' "${file}" 2>/dev/null \
	  || echo 'file:///var/samba Samba' >> "${file}"
	grep -q '^file:///var/tftp ' "${file}" 2>/dev/null \
	  || echo 'file:///var/tftp TFTP' >> "${file}"
	grep -q '^file:///var/www/html ' "${file}" 2>/dev/null \
	  || echo 'file:///var/www/html WWW' >> "${file}"
	#--- Configure file browser - Thunar (need to re-login for effect)
	mkdir -p ~/.config/Thunar/
	file=~/.config/Thunar/thunarrc; [ -e "${file}" ] && cp -n $file{,.bkup}
	([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
	sed -i 's/LastShowHidden=.*/LastShowHidden=TRUE/' "${file}" 2>/dev/null || echo -e "[Configuration]\nLastShowHidden=TRUE" > "${file}"
}

configure_grub(){
	# Configure GRUB
	(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Configuring GRUB ~ boot manager"
	grubTimeout=5
	(dmidecode | grep -iq virtual) && grubTimeout=1 # Set to much less if we are in a VM
	file=/etc/default/grub; [ -e "${file}" ] && cp -n $file{,.bkup}
	sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT='${grubTimeout}'/' "${file}"                           # Time out (lower if in a virtual machine, else possible dual booting)
	sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="vga=0x0318"/' "${file}"   # TTY resolution
	update-grub
}

network_update(){
	# Update OS from network repositories
	(( STAGE++ ));  write_output "(${STAGE}/${TOTAL}) Updating OS from network repositories"
	write_output "...this may take a while depending on your Internet connection & Kali version/age. Grab some coffee" "warning"
	for FILE in clean autoremove; do apt -y -qq "${FILE}"; done
	export DEBIAN_FRONTEND=noninteractive
	apt -qq update && APT_LISTCHANGES_FRONTEND=none apt -o Dpkg::Options::="--force-confnew" -y dist-upgrade --fix-missing 2>&1 || write_output "Issue with apt install" "error"
	for FILE in clean autoremove; do apt -y -qq "${FILE}"; done
}

configure_gnome(){
	# Configure login screen
	if [[ $(dmidecode | grep -i virtual) ]] && [[ $(which gnome-shell) ]]; then
		(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Configuring login screen" 
		file=/etc/gdm3/daemon.conf; [ -e "${file}" ] && cp -n $file{,.bkup}
		sed -i 's/^.*AutomaticLoginEnable = .*/AutomaticLoginEnable = true/' "${file}"
		sed -i 's/^.*AutomaticLogin = .*/AutomaticLogin = root/' "${file}"
	else
		(( SKIPPED++ ))
	fi

	# Configure GNOME if that is our environment
	if [[ $(which gnome-shell) ]]; then
		##### Configure GNOME 3
		(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Configuring GNOME 3 ~ desktop environment"
		gsettings set org.gnome.shell.extensions.dash-to-dock extend-height true  # Set dock to use the full height
		gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT'  # Set dock to the left
		gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true  # Set dock to be always visible
		gsettings set org.gnome.shell favorite-apps "['gnome-terminal.desktop', 'org.gnome.Nautilus.desktop', 'kali-wireshark.desktop', 'firefox-esr.desktop', 'kali-msfconsole.desktop', 'gedit.desktop']"

		# Gnome Extension - Alternate-tab (So it doesn't group the same windows up)
		GNOME_EXTENSIONS=$(gsettings get org.gnome.shell enabled-extensions | sed 's_^.\(.*\).$_\1_')
		echo "${GNOME_EXTENSIONS}" | grep -q "alternate-tab@gnome-shell-extensions.gcampax.github.com" || gsettings set org.gnome.shell enabled-extensions "[${GNOME_EXTENSIONS}, 'alternate-tab@gnome-shell-extensions.gcampax.github.com']"
		# Gnome Extension - Drive Menu (Show USB devices in tray)
		GNOME_EXTENSIONS=$(gsettings get org.gnome.shell enabled-extensions | sed 's_^.\(.*\).$_\1_')
		echo "${GNOME_EXTENSIONS}" | grep -q "drive-menu@gnome-shell-extensions.gcampax.github.com" || gsettings set org.gnome.shell enabled-extensions "[${GNOME_EXTENSIONS}, 'drive-menu@gnome-shell-extensions.gcampax.github.com']"	

		# workspaces
		gsettings set org.gnome.shell.overrides dynamic-workspaces false  # Static
		gsettings set org.gnome.desktop.wm.preferences num-workspaces 3  # Increase workspaces count to 3
		# top bar
		gsettings set org.gnome.desktop.interface clock-show-date true  # Show date next to time in the top tool bar
		# Keyboard short-cuts
		(dmidecode | grep -iq virtual) && gsettings set org.gnome.mutter overlay-key "Super_R" # Change 'super' key to right side (rather than left key), if in a VM
		# Hide desktop icon
		dconf write /org/gnome/nautilus/desktop/computer-icon-visible false

		# Configure GNOME terminal Note: need to restart xserver for effect
		(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Configuring GNOME terminal ~ CLI interface"
		gconftool-2 -t bool -s /apps/gnome-terminal/profiles/Default/scrollback_unlimited true
		gconftool-2 -t string -s /apps/gnome-terminal/profiles/Default/background_type transparent
		gconftool-2 -t string -s /apps/gnome-terminal/profiles/Default/background_darkness 0.85611499999999996
	else
		SKIPPED=$((SKIPPED+2))
		write_output "Skipping GNOME configuration. Not Detected." "warning"
	fi
}

configure_xfce(){
	# Configure XFCE4
	# TODO: Update quick links and theme info
	if [[ $(which xfce4-about) ]]; then
		(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Configuring XFCE4 ~ desktop environment"
		# Configuring XFCE
		mkdir -p ~/.config/xfce4/panel/launcher-{2,4,5,6,7,8,9}/
		mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml/
		# Keyboard shortcuts
		cat <<-EOF > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml || write_output "Issue with writing file" "error"
		<?xml version="1.0" encoding="UTF-8"?>

		<channel name="xfce4-keyboard-shortcuts" version="1.0">
		  <property name="commands" type="empty">
		    <property name="custom" type="empty">
		      <property name="XF86Display" type="string" value="xfce4-display-settings --minimal"/>
		      <property name="&lt;Alt&gt;F2" type="string" value="xfrun4"/>
		      <property name="&lt;Primary&gt;space" type="string" value="xfce4-appfinder"/>
		      <property name="&lt;Primary&gt;&lt;Alt&gt;t" type="string" value="/usr/bin/exo-open --launch TerminalEmulator"/>
		      <property name="&lt;Primary&gt;&lt;Alt&gt;Delete" type="string" value="xflock4"/>
		      <property name="&lt;Primary&gt;Escape" type="string" value="xfdesktop --menu"/>
		      <property name="&lt;Super&gt;p" type="string" value="xfce4-display-settings --minimal"/>
		      <property name="override" type="bool" value="true"/>
		    </property>
		  </property>
		  <property name="xfwm4" type="empty">
		    <property name="custom" type="empty">
		      <property name="&lt;Alt&gt;&lt;Control&gt;End" type="string" value="move_window_next_workspace_key"/>
		      <property name="&lt;Alt&gt;&lt;Control&gt;Home" type="string" value="move_window_prev_workspace_key"/>
		      <property name="&lt;Alt&gt;&lt;Control&gt;KP_1" type="string" value="move_window_workspace_1_key"/>
		      <property name="&lt;Alt&gt;&lt;Control&gt;KP_2" type="string" value="move_window_workspace_2_key"/>
		      <property name="&lt;Alt&gt;&lt;Control&gt;KP_3" type="string" value="move_window_workspace_3_key"/>
		      <property name="&lt;Alt&gt;&lt;Control&gt;KP_4" type="string" value="move_window_workspace_4_key"/>
		      <property name="&lt;Alt&gt;&lt;Control&gt;KP_5" type="string" value="move_window_workspace_5_key"/>
		      <property name="&lt;Alt&gt;&lt;Control&gt;KP_6" type="string" value="move_window_workspace_6_key"/>
		      <property name="&lt;Alt&gt;&lt;Control&gt;KP_7" type="string" value="move_window_workspace_7_key"/>
		      <property name="&lt;Alt&gt;&lt;Control&gt;KP_8" type="string" value="move_window_workspace_8_key"/>
		      <property name="&lt;Alt&gt;&lt;Control&gt;KP_9" type="string" value="move_window_workspace_9_key"/>
		      <property name="&lt;Alt&gt;&lt;Shift&gt;Tab" type="string" value="cycle_reverse_windows_key"/>
		      <property name="&lt;Alt&gt;Delete" type="string" value="del_workspace_key"/>
		      <property name="&lt;Alt&gt;F10" type="string" value="maximize_window_key"/>
		      <property name="&lt;Alt&gt;F11" type="string" value="fullscreen_key"/>
		      <property name="&lt;Alt&gt;F12" type="string" value="above_key"/>
		      <property name="&lt;Alt&gt;F4" type="string" value="close_window_key"/>
		      <property name="&lt;Alt&gt;F6" type="string" value="stick_window_key"/>
		      <property name="&lt;Alt&gt;F7" type="string" value="move_window_key"/>
		      <property name="&lt;Alt&gt;F8" type="string" value="resize_window_key"/>
		      <property name="&lt;Alt&gt;F9" type="string" value="hide_window_key"/>
		      <property name="&lt;Alt&gt;Insert" type="string" value="add_workspace_key"/>
		      <property name="&lt;Alt&gt;space" type="string" value="popup_menu_key"/>
		      <property name="&lt;Alt&gt;Tab" type="string" value="cycle_windows_key"/>
		      <property name="&lt;Control&gt;&lt;Alt&gt;d" type="string" value="show_desktop_key"/>
		      <property name="&lt;Control&gt;&lt;Alt&gt;Down" type="string" value="down_workspace_key"/>
		      <property name="&lt;Control&gt;&lt;Alt&gt;Left" type="string" value="left_workspace_key"/>
		      <property name="&lt;Control&gt;&lt;Alt&gt;Right" type="string" value="right_workspace_key"/>
		      <property name="&lt;Control&gt;&lt;Alt&gt;Up" type="string" value="up_workspace_key"/>
		      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Left" type="string" value="move_window_left_key"/>
		      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Right" type="string" value="move_window_right_key"/>
		      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Up" type="string" value="move_window_up_key"/>
		      <property name="&lt;Control&gt;F1" type="string" value="workspace_1_key"/>
		      <property name="&lt;Control&gt;F10" type="string" value="workspace_10_key"/>
		      <property name="&lt;Control&gt;F11" type="string" value="workspace_11_key"/>
		      <property name="&lt;Control&gt;F12" type="string" value="workspace_12_key"/>
		      <property name="&lt;Control&gt;F2" type="string" value="workspace_2_key"/>
		      <property name="&lt;Control&gt;F3" type="string" value="workspace_3_key"/>
		      <property name="&lt;Control&gt;F4" type="string" value="workspace_4_key"/>
		      <property name="&lt;Control&gt;F5" type="string" value="workspace_5_key"/>
		      <property name="&lt;Control&gt;F6" type="string" value="workspace_6_key"/>
		      <property name="&lt;Control&gt;F7" type="string" value="workspace_7_key"/>
		      <property name="&lt;Control&gt;F8" type="string" value="workspace_8_key"/>
		      <property name="&lt;Control&gt;F9" type="string" value="workspace_9_key"/>
		      <property name="&lt;Shift&gt;&lt;Alt&gt;Page_Down" type="string" value="lower_window_key"/>
		      <property name="&lt;Shift&gt;&lt;Alt&gt;Page_Up" type="string" value="raise_window_key"/>
		      <property name="&lt;Super&gt;Tab" type="string" value="switch_window_key"/>
		      <property name="Down" type="string" value="down_key"/>
		      <property name="Escape" type="string" value="cancel_key"/>
		      <property name="Left" type="string" value="left_key"/>
		      <property name="Right" type="string" value="right_key"/>
		      <property name="Up" type="string" value="up_key"/>
		      <property name="override" type="bool" value="true"/>
		      <property name="&lt;Super&gt;Left" type="string" value="tile_left_key"/>
		      <property name="&lt;Super&gt;Right" type="string" value="tile_right_key"/>
		      <property name="&lt;Super&gt;Up" type="string" value="maximize_window_key"/>
		    </property>
		  </property>
		  <property name="providers" type="array">
		    <value type="string" value="xfwm4"/>
		    <value type="string" value="commands"/>
		  </property>
		</channel>
		EOF
		# Power Options
		cat <<-EOF > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml || write_output "Issue with writing file" "error"
		<?xml version="1.0" encoding="UTF-8"?>

		<channel name="xfce4-power-manager" version="1.0">
		  <property name="xfce4-power-manager" type="empty">
		    <property name="power-button-action" type="empty"/>
		    <property name="dpms-enabled" type="bool" value="true"/>
		    <property name="blank-on-ac" type="int" value="0"/>
		    <property name="dpms-on-ac-sleep" type="uint" value="0"/>
		    <property name="dpms-on-ac-off" type="uint" value="0"/>
		  </property>
		</channel>
		EOF
		# Greeter settings
		wget -P /usr/share/wallpapers https://github.com/brutalgg/wallpapers/raw/master/login_icon.png
		wget -P /usr/share/wallpapers https://github.com/brutalgg/wallpapers/raw/master/login_wallpaper.jpg
		cat <<-EOF > /etc/lightdm/lightdm-gtk-greeter.conf || write_output "Issue with writing file" "error"
		[greeter]
		theme-name = Blackbird
		background = /usr/share/wallpapers/login_wallpaper.jpg
		user-background = false
		default-user-image = /usr/share/wallpapers/login_icon.png
		EOF
		# Desktop files
		ln -sf /usr/share/applications/exo-terminal-emulator.desktop ~/.config/xfce4/panel/launcher-2/exo-terminal-emulator.desktop
		ln -sf /usr/share/applications/kali-wireshark.desktop        ~/.config/xfce4/panel/launcher-4/kali-wireshark.desktop
		ln -sf /usr/share/applications/firefox-esr.desktop           ~/.config/xfce4/panel/launcher-5/firefox-esr.desktop
		ln -sf /usr/share/applications/kali-burpsuite.desktop        ~/.config/xfce4/panel/launcher-6/kali-burpsuite.desktop
		ln -sf /usr/share/applications/kali-msfconsole.desktop       ~/.config/xfce4/panel/launcher-7/kali-msfconsole.desktop
		ln -sf /usr/share/applications/leafpad.desktop       ~/.config/xfce4/panel/launcher-8/textedit.desktop
		ln -sf /usr/share/applications/xfce4-appfinder.desktop       ~/.config/xfce4/panel/launcher-9/xfce4-appfinder.desktop
		# General Settings
		_TMP=""
		[ "${burpFree}" != "false" ] && _TMP="-t int -s 6"
		xfconf-query -n -a -c xfce4-panel -p /panels -t int -s 0
		xfconf-query --create --channel xfce4-panel --property /panels/panel-0/plugin-ids -t int -s 1   -t int -s 2   -t int -s 3   -t int -s 4   -t int -s 5  ${_TMP}        -t int -s 7   -t int -s 8  -t int -s 9 -t int -s 10  -t int -s 11  -t int -s 13  -t int -s 15  -t int -s 16  -t int -s 17  -t int -s 19  -t int -s 20
		xfconf-query -n -c xfce4-panel -p /panels/panel-0/length -t int -s 100
		xfconf-query -n -c xfce4-panel -p /panels/panel-0/size -t int -s 30
		xfconf-query -n -c xfce4-panel -p /panels/panel-0/position -t string -s "p=6;x=0;y=0"
		xfconf-query -n -c xfce4-panel -p /panels/panel-0/position-locked -t bool -s true
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-1 -t string -s applicationsmenu     # application menu
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-2 -t string -s launcher             # terminal   ID: exo-terminal-emulator
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-3 -t string -s places               # places
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-4 -t string -s launcher             # wireshark  ID: kali-wireshark
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-5 -t string -s launcher             # firefox    ID: firefox-esr
		[ "${burpFree}" != "false" ] && xfconf-query -n -c xfce4-panel -p /plugins/plugin-6 -t string -s launcher  # burpsuite  ID: kali-burpsuite
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-7 -t string -s launcher             # msf        ID: kali-msfconsole
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-8 -t string -s launcher             # leafpad      ID: leafpad.desktop
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-9 -t string -s launcher             # search     ID: xfce4-appfinder
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-10 -t string -s tasklist
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-11 -t string -s separator
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-13 -t string -s mixer   # audio
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-15 -t string -s systray
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-16 -t string -s actions
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-17 -t string -s clock
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-19 -t string -s pager
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-20 -t string -s showdesktop
		# application menu
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-1/show-tooltips -t bool -s true
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-1/show-button-title -t bool -s false
		# terminal
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-2/items -t string -s "exo-terminal-emulator.desktop" -a
		# places
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-3/mount-open-volumes -t bool -s true
		# wireshark
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-4/items -t string -s "kali-wireshark.desktop" -a
		# firefox
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-5/items -t string -s "firefox-esr.desktop" -a
		# burp
		[ "${burpFree}" != "false" ] && xfconf-query -n -c xfce4-panel -p /plugins/plugin-6/items -t string -s "kali-burpsuite.desktop" -a
		# metasploit
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-7/items -t string -s "kali-msfconsole.desktop" -a
		# search
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-9/items -t string -s "xfce4-appfinder.desktop" -a
		# tasklist (& separator - required for padding)
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-10/show-labels -t bool -s true
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-10/show-handle -t bool -s false
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-11/style -t int -s 0
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-11/expand -t bool -s true
		# systray
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-15/show-frame -t bool -s false
		# actions
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-16/appearance -t int -s 1
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-16/items -t string -s "+logout-dialog"  -t string -s "-switch-user"  -t string -s "-separator" -t string -s "-logout"  -t string -s "+lock-screen"  -t string -s "+hibernate"  -t string -s "+suspend"  -t string -s "+restart"  -t string -s "+shutdown"  -a
		# clock
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-17/show-frame -t bool -s false
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-17/mode -t int -s 2
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-17/digital-format -t string -s "%R, %Y-%m-%d"
		# pager / workspace
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-19/miniature-view -t bool -s true
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-19/rows -t int -s 1
		xfconf-query -n -c xfwm4 -p /general/workspace_count -t int -s 3
		# Theme options
		xfconf-query -n -c xsettings -p /Net/ThemeName -s "Blackbird"
		xfconf-query -n -c xsettings -p /Net/IconThemeName -s "Vibrancy-Kali-Full-Dark"
		xfconf-query -n -c xsettings -p /Gtk/MenuImages -t bool -s true
		xfconf-query -n -c xfce4-panel -p /plugins/plugin-1/button-icon -t string -s "kali-menu"
		# Window management
		xfconf-query -n -c xfwm4 -p /general/snap_to_border -t bool -s true
		xfconf-query -n -c xfwm4 -p /general/snap_to_windows -t bool -s true
		xfconf-query -n -c xfwm4 -p /general/wrap_windows -t bool -s false
		xfconf-query -n -c xfwm4 -p /general/wrap_workspaces -t bool -s false
		xfconf-query -n -c xfwm4 -p /general/click_to_focus -t bool -s false
		xfconf-query -n -c xfwm4 -p /general/click_to_focus -t bool -s true
		# Hide icons
		xfconf-query -n -c xfce4-desktop -p /desktop-icons/file-icons/show-filesystem -t bool -s false
		xfconf-query -n -c xfce4-desktop -p /desktop-icons/file-icons/show-home -t bool -s false
		xfconf-query -n -c xfce4-desktop -p /desktop-icons/file-icons/show-trash -t bool -s false
		xfconf-query -n -c xfce4-desktop -p /desktop-icons/file-icons/show-removable -t bool -s false
		# Start and exit values
		xfconf-query -n -c xfce4-session -p /splash/Engine -t string -s ""
		xfconf-query -n -c xfce4-session -p /shutdown/LockScreen -t bool -s true
		xfconf-query -n -c xfce4-session -p /general/SaveOnExit -t bool -s false
		# App Finder
		xfconf-query -n -c xfce4-appfinder -p /last/pane-position -t int -s 248
		xfconf-query -n -c xfce4-appfinder -p /last/window-height -t int -s 742
		xfconf-query -n -c xfce4-appfinder -p /last/window-width -t int -s 648
		# Enable compositing
		xfconf-query -n -c xfwm4 -p /general/use_compositing -t bool -s true
		xfconf-query -n -c xfwm4 -p /general/frame_opacity -t int -s 85
		# Remove "Mail Reader" from menu
		file=/usr/share/applications/exo-mail-reader.desktop   #; [ -e "${file}" ] && cp -n $file{,.bkup}
		sed -i 's/^NotShowIn=*/NotShowIn=XFCE;/; s/^OnlyShowIn=XFCE;/OnlyShowIn=/' "${file}"
		grep -q "NotShowIn=XFCE" "${file}" || echo "NotShowIn=XFCE;" >> "${file}"
		# XFCE for default applications
		mkdir -p ~/.local/share/applications/
		file=~/.local/share/applications/mimeapps.list; [ -e "${file}" ] && cp -n $file{,.bkup}
		[ ! -e "${file}" ] && echo '[Added Associations]' > "${file}"
		([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
		# Firefox
		for VALUE in http https; do
			sed -i 's#^x-scheme-handler/'${VALUE}'=.*#x-scheme-handler/'${VALUE}'=exo-web-browser.desktop#' "${file}"
			grep -q '^x-scheme-handler/'${VALUE}'=' "${file}" 2>/dev/null || echo 'x-scheme-handler/'${VALUE}'=exo-web-browser.desktop' >> "${file}"
		done
		# Thunar
		for VALUE in file trash; do
			sed -i 's#x-scheme-handler/'${VALUE}'=.*#x-scheme-handler/'${VALUE}'=exo-file-manager.desktop#' "${file}"
			grep -q '^x-scheme-handler/'${VALUE}'=' "${file}" 2>/dev/null || echo 'x-scheme-handler/'${VALUE}'=exo-file-manager.desktop' >> "${file}"
		done
		file=~/.config/xfce4/helpers.rc; [ -e "${file}" ] && cp -n $file{,.bkup}
		([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
		sed -i 's#^FileManager=.*#FileManager=Thunar#' "${file}" 2>/dev/null
		grep -q '^FileManager=Thunar' "${file}" 2>/dev/null || echo 'FileManager=Thunar' >> "${file}"
		# Disable user folders in home folder
		file=/etc/xdg/user-dirs.conf; [ -e "${file}" ] && cp -n $file{,.bkup}
		sed -i 's/^XDG_/#XDG_/g; s/^#XDG_DESKTOP/XDG_DESKTOP/g;' "${file}"
		sed -i 's/^enable=.*/enable=False/' "${file}"
		find ~/ -maxdepth 1 -mindepth 1 -type d \
		  \( -name 'Documents' -o -name 'Music' -o -name 'Pictures' -o -name 'Public' -o -name 'Templates' -o -name 'Videos' \) -empty -delete
		apt -y -qq install xdg-user-dirs || write_output "Issue with apt install" "error"
		xdg-user-dirs-update
		# Remove any old sessions
		rm -f ~/.cache/sessions/*
	else
		(( SKIPPED++ ))
	fi
}

configure_wallpapers(){
	# Wallpapers
	(( STAGE++ )); 	git_install_software "Cosmetics ~ Giving it a personal touch" "https://github.com/brutalgg/wallpapers.git" "wallpapers" ${STAGE} ${TOTAL}
	mv /opt/wallpapers/*.png /usr/share/wallpapers
	rm -rf /opt/wallpapers

	# Kali 1 (Wallpaper)
	[ -e "/usr/share/wallpapers/kali_default-1440x900.jpg" ] \
	  && ln -sf /usr/share/wallpapers/kali/contents/images/1440x900.png /usr/share/wallpapers/kali_default-1440x900.jpg
	# Kali 2 (Login)
	[ -e "/usr/share/gnome-shell/theme/KaliLogin.png" ] \
	  && cp -f /usr/share/gnome-shell/theme/KaliLogin.png /usr/share/wallpapers/KaliLogin2.0-login.jpg
	# Kali 2 & Rolling (Wallpaper)
	[ -e "/usr/share/images/desktop-base/kali-wallpaper_1920x1080.png" ] \
	  && ln -sf /usr/share/images/desktop-base/kali-wallpaper_1920x1080.png /usr/share/wallpapers/kali_default2.0-1920x1080.jpg
	# New wallpaper & add to startup (so its random each login)
	mkdir -p /usr/local/bin/
	file=/usr/local/bin/rand-wallpaper; [ -e "${file}" ] && cp -n $file{,.bkup}
	cat <<-EOF > "${file}" || write_output "Issue with writing file" "error"
	#!/bin/bash

	wallpaper="\$(shuf -n1 -e \$(find /usr/share/wallpapers/ -maxdepth 1 -name 'kali_*'))"

	## XFCE - Desktop wallpaper
	/usr/bin/xfconf-query -n -c xfce4-desktop -p /backdrop/screen0/monitor0/image-show -t bool -s true
	/usr/bin/xfconf-query -n -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -t string -s "\${wallpaper}"
	/usr/bin/xfconf-query -n -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -t string -s "\${wallpaper}"

	## GNOME - Desktop wallpaper
	#[[ $(which gnome-shell) ]] \
	#  && dconf write /org/gnome/desktop/background/picture-uri "'file://\${wallpaper}'"

	## Change lock wallpaper (before swipe) - kali 2 & rolling
	/usr/bin/dconf write /org/gnome/desktop/screensaver/picture-uri "'file://\${wallpaper}'"

	## Change login wallpaper (after swipe) - kali 2
	#cp -f "\${wallpaper}" /usr/share/gnome-shell/theme/KaliLogin.png

	/usr/bin/xfdesktop --reload 2>/dev/null &
	EOF
	chmod -f 0500 "${file}"
	# Run now
	bash "${file}"
	# Add to startup
	mkdir -p ~/.config/autostart/
	file=~/.config/autostart/wallpaper.desktop; [ -e "${file}" ] && cp -n $file{,.bkup}
	cat <<-EOF > "${file}" || write_output "Issue with writing file" "error"
	[Desktop Entry]
	Type=Application
	Exec=/usr/local/bin/rand-wallpaper
	Hidden=false
	NoDisplay=false
	X-GNOME-Autostart-enabled=true
	Name=wallpaper
	EOF
}

setup_bash(){
	# Configure bash - all users
	(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Configuring bash ~ CLI shell"
	file=/etc/bash.bashrc; [ -e "${file}" ] && cp -n $file{,.bkup}  #~/.bashrc
	grep -q "cdspell" "${file}" || echo "shopt -sq cdspell" >> "${file}"  # Spell check 'cd' commands
	grep -q "autocd" "${file}" || echo "shopt -s autocd" >> "${file}"  # So you don't have to 'cd' before a folder
	grep -q "checkwinsize" "${file}" || echo "shopt -sq checkwinsize" >> "${file}"  # Wrap lines correctly after resizing
	grep -q "nocaseglob" "${file}" || echo "shopt -sq nocaseglob" >> "${file}"  # Case insensitive pathname expansion
	grep -q "HISTSIZE" "${file}" || echo "HISTSIZE=10000" >> "${file}"  # Bash history (memory scroll back)
	grep -q "HISTFILESIZE" "${file}" || echo "HISTFILESIZE=10000" >> "${file}"  # Bash history (file .bash_history)
	# apply new configs
	source "${file}" || source ~/.zshrc

	# Install bash colour - all users
	(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Installing bash colour ~ colours shell output"
	file=/etc/bash.bashrc; [ -e "${file}" ] && cp -n $file{,.bkup}   #~/.bashrc
	([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
	sed -i 's/.*force_color_prompt=.*/force_color_prompt=yes/' "${file}"
	grep -q '^force_color_prompt' "${file}" 2>/dev/null || echo 'force_color_prompt=yes' >> "${file}"
	sed -i 's#PS1='"'"'.*'"'"'#PS1='"'"'${debian_chroot:+($debian_chroot)}\\[\\033\[01;31m\\]\\u@\\h\\\[\\033\[00m\\]:\\[\\033\[01;34m\\]\\w\\[\\033\[00m\\]\\$ '"'"'#' "${file}"
	grep -q "^export LS_OPTIONS='--color=auto'" "${file}" 2>/dev/null || echo "export LS_OPTIONS='--color=auto'" >> "${file}"
	grep -q '^eval "$(dircolors)"' "${file}" 2>/dev/null || echo 'eval "$(dircolors)"' >> "${file}"
	grep -q "^alias ls='ls $LS_OPTIONS'" "${file}" 2>/dev/null || echo "alias ls='ls $LS_OPTIONS'" >> "${file}"
	grep -q "^alias ll='ls $LS_OPTIONS -l'" "${file}" 2>/dev/null || echo "alias ll='ls $LS_OPTIONS -l'" >> "${file}"
	grep -q "^alias l='ls $LS_OPTIONS -lA'" "${file}" 2>/dev/null || echo "alias l='ls $LS_OPTIONS -lA'" >> "${file}"
	# All other users that are made afterwards
	file=/etc/skel/.bashrc   #; [ -e "${file}" ] && cp -n $file{,.bkup}
	sed -i 's/.*force_color_prompt=.*/force_color_prompt=yes/' "${file}"
	# apply new configs
	source "${file}" || source ~/.zshrc

	# Install grc
	(( STAGE++ )); install_software "grc ~ colours shell output" $STAGE $TOTAL grc
	#--- Setup aliases
	file=~/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
	([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
	grep -q '^## grc diff alias' "${file}" 2>/dev/null \
	  || echo -e "## grc diff alias\nalias diff='$(which grc) $(which diff)'\n" >> "${file}"
	grep -q '^## grc dig alias' "${file}" 2>/dev/null \
	  || echo -e "## grc dig alias\nalias dig='$(which grc) $(which dig)'\n" >> "${file}"
	grep -q '^## grc gcc alias' "${file}" 2>/dev/null \
	  || echo -e "## grc gcc alias\nalias gcc='$(which grc) $(which gcc)'\n" >> "${file}"
	grep -q '^## grc ifconfig alias' "${file}" 2>/dev/null \
	  || echo -e "## grc ifconfig alias\nalias ifconfig='$(which grc) $(which ifconfig)'\n" >> "${file}"
	grep -q '^## grc mount alias' "${file}" 2>/dev/null \
	  || echo -e "## grc mount alias\nalias mount='$(which grc) $(which mount)'\n" >> "${file}"
	grep -q '^## grc netstat alias' "${file}" 2>/dev/null \
	  || echo -e "## grc netstat alias\nalias netstat='$(which grc) $(which netstat)'\n" >> "${file}"
	grep -q '^## grc ping alias' "${file}" 2>/dev/null \
	  || echo -e "## grc ping alias\nalias ping='$(which grc) $(which ping)'\n" >> "${file}"
	grep -q '^## grc ps alias' "${file}" 2>/dev/null \
	  || echo -e "## grc ps alias\nalias ps='$(which grc) $(which ps)'\n" >> "${file}"
	grep -q '^## grc tail alias' "${file}" 2>/dev/null \
	  || echo -e "## grc tail alias\nalias tail='$(which grc) $(which tail)'\n" >> "${file}"
	grep -q '^## grc traceroute alias' "${file}" 2>/dev/null \
	  || echo -e "## grc traceroute alias\nalias traceroute='$(which grc) $(which traceroute)'\n" >> "${file}"
	grep -q '^## grc wdiff alias' "${file}" 2>/dev/null \
	  || echo -e "## grc wdiff alias\nalias wdiff='$(which grc) $(which wdiff)'\n" >> "${file}"
	# apply new aliases
	source "${file}" || source ~/.zshrc
}

setup_alias(){
	# Configure aliases - root user
	(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Configuring aliases ~ CLI shortcuts"
	# Enable defaults - root user
	for FILE in /etc/bash.bashrc ~/.bashrc ~/.bash_aliases; do    #/etc/profile /etc/bashrc /etc/bash_aliases /etc/bash.bash_aliases
		[[ ! -f "${FILE}" ]] && continue
		cp -n $FILE{,.bkup}
		sed -i 's/#alias/alias/g' "${FILE}"
	done
	#--- General system ones
	file=~/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
	([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
	#--- Add in ours (shortcuts)
	grep -q '^## Checksums' "${file}" 2>/dev/null \
	  || echo -e '## Checksums\nalias sha1="openssl sha1"\nalias md5="openssl md5"\n' >> "${file}"
	grep -q '^## List open ports' "${file}" 2>/dev/null \
	  || echo -e '## List open ports\nalias ports="netstat -tulanp"\n' >> "${file}"
	grep -q '^## Get header' "${file}" 2>/dev/null \
	  || echo -e '## Get header\nalias header="curl -I"\n' >> "${file}"
	grep -q '^## Get external IP address' "${file}" 2>/dev/null \
	  || echo -e '## Get external IP address\nalias ipx="curl -s http://ipinfo.io/ip"\n' >> "${file}"
	grep -q '^## DNS - External IP #1' "${file}" 2>/dev/null \
	  || echo -e '## DNS - External IP #1\nalias dns1="dig +short @resolver1.opendns.com myip.opendns.com"\n' >> "${file}"
	grep -q '^## DNS - External IP #2' "${file}" 2>/dev/null \
	  || echo -e '## DNS - External IP #2\nalias dns2="dig +short @208.67.222.222 myip.opendns.com"\n' >> "${file}"
	grep -q '^## DNS - Check' "${file}" 2>/dev/null \
	  || echo -e '### DNS - Check ("#.abc" is Okay)\nalias dns3="dig +short @208.67.220.220 which.opendns.com txt"\n' >> "${file}"
	grep -q '^## Extract file' "${file}" 2>/dev/null || cat <<-EOF >> "${file}" || write_output "Issue with writing file" "error"

	## Extract file, example. "ex package.tar.bz2"
	ex() {
	  if [[ -f \$1 ]]; then
	    case \$1 in
	      *.tar.bz2) tar xjf \$1 ;;
	      *.tar.gz)  tar xzf \$1 ;;
	      *.bz2)     bunzip2 \$1 ;;
	      *.rar)     rar x \$1 ;;
	      *.gz)      gunzip \$1  ;;
	      *.tar)     tar xf \$1  ;;
	      *.tbz2)    tar xjf \$1 ;;
	      *.tgz)     tar xzf \$1 ;;
	      *.zip)     unzip \$1 ;;
	      *.Z)       uncompress \$1 ;;
	      *.7z)      7z x \$1 ;;
	      *)         echo \$1 cannot be extracted ;;
	    esac
	  else
	    echo \$1 is not a valid file
	  fi
	}
	EOF
	# Add in tools
	grep -q '^## nmap' "${file}" 2>/dev/null \
	  || echo -e '## nmap\nalias nmap="nmap --reason --open --stats-every 3m --max-retries 1 --max-scan-delay 20 --defeat-rst-ratelimit"\n' >> "${file}"
	grep -q '^## python http' "${file}" 2>/dev/null \
	  || echo -e '## python http\nalias http="python2 -m SimpleHTTPServer"\n' >> "${file}"
	# Add in folders
	grep -q '^## www' "${file}" 2>/dev/null \
	  || echo -e '## www\nalias wwwroot="cd /var/www/html/"\n#alias www="cd /var/www/html/"\n' >> "${file}"
	grep -q '^## ftp' "${file}" 2>/dev/null \
	  || echo -e '## ftp\nalias ftproot="cd /var/ftp/"\n' >> "${file}"
	grep -q '^## tftp' "${file}" 2>/dev/null \
	  || echo -e '## tftp\nalias tftproot="cd /var/tftp/"\n' >> "${file}"
	grep -q '^## smb' "${file}" 2>/dev/null \
	  || echo -e '## smb\nalias smb="cd /var/samba/"\n#alias smbroot="cd /var/samba/"\n' >> "${file}"
	grep -q '^## wordlist' "${file}" 2>/dev/null \
	  || echo -e '## wordlist\nalias wordlists="cd /usr/share/wordlists/"\n' >> "${file}"
	# Apply new aliases
	source "${file}" || source ~/.zshrc
}

setup_terminator(){
	##### Install (GNOME) Terminator
	(( STAGE++ )); install_software "Terminator ~ multiple terminals in a single window" $STAGE $TOTAL terminator
	# Configure terminator
	mkdir -p ~/.config/terminator/
	file=~/.config/terminator/config; [ -e "${file}" ] && cp -n $file{,.bkup}
	cat <<-EOF > "${file}" || write_output "Issue with writing file" "error"
	[global_config]
	  enabled_plugins = TerminalShot, LaunchpadCodeURLHandler, APTURLHandler, LaunchpadBugURLHandler
	[keybindings]
	[profiles]
	  [[default]]
	    background_darkness = 0.9
	    scroll_on_output = False
	    copy_on_selection = True
	    background_type = transparent
	    scrollback_infinite = True
	    show_titlebar = False
	[layouts]
	  [[default]]
	    [[[child1]]]
	      type = Terminal
	      parent = window0
	    [[[window0]]]
	      type = Window
	      parent = ""
	[plugins]
	EOF
	# Set terminator as XFCE's default
	mkdir -p ~/.config/xfce4/
	file=~/.config/xfce4/helpers.rc; [ -e "${file}" ] && cp -n $file{,.bkup}
	([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
	sed -i 's_^TerminalEmulator=.*_TerminalEmulator=debian-x-terminal-emulator_' "${file}" 2>/dev/null || echo -e 'TerminalEmulator=debian-x-terminal-emulator' >> "${file}"
}

setup_zsh(){
	# Install ZSH & Oh-My-ZSH - root user.   Note:  'Open terminal here', will not work with ZSH.   Make sure to have tmux already installed
	(( STAGE++ )); install_software "ZSH & Oh-My-ZSH ~ unix shell" $STAGE $TOTAL zsh
	# Setup oh-my-zsh
	timeout 300 curl --progress -k -L -f "https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh" | zsh
	# Configure zsh
	file=~/.zshrc; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/zsh/zshrc
	([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
	grep -q 'interactivecomments' "${file}" 2>/dev/null || echo 'setopt interactivecomments' >> "${file}"
	grep -q 'ignoreeof' "${file}" 2>/dev/null || echo 'setopt ignoreeof' >> "${file}"
	grep -q 'correctall' "${file}" 2>/dev/null || echo 'setopt correctall' >> "${file}"
	grep -q 'globdots' "${file}" 2>/dev/null || echo 'setopt globdots' >> "${file}"
	grep -q '.bash_aliases' "${file}" 2>/dev/null || echo 'source $HOME/.bash_aliases' >> "${file}"
	grep -q '/usr/bin/tmux' "${file}" 2>/dev/null || echo '#if ([[ -z "$TMUX" && -n "$SSH_CONNECTION" ]]); then /usr/bin/tmux attach || /usr/bin/tmux new; fi' >> "${file}"   # If not already in tmux and via SSH
	# configure zsh (themes) ~ https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
	sed -i 's/ZSH_THEME=.*/ZSH_THEME="mh"/' "${file}"   # Other themes: mh,jreese,alanpeabody,candy,terminalparty,kardan,nicoulaj,sunaku
	# Configure oh-my-zsh
	sed -i 's/plugins=(.*)/plugins=(git git-extras tmux dirhistory python pip)/' "${file}"
	# Set zsh as default shell (current user)
	chsh -s "$(which zsh)"
}

setup_tmux(){
	# Install tmux - all users
	(( STAGE++ )); install_software "tmux ~ multiplex virtual consoles" $STAGE $TOTAL tmux
	file=~/.tmux.conf; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/tmux.conf
	# configure tmux
	cat <<-EOF > "${file}" || write_output "Issue with writing file" "error"
	#-Settings---------------------------------------------------------------------
	## Make it like screen (use CTRL+a)
	unbind C-b
	set -g prefix C-a

	## Pane switching (SHIFT+ARROWS)
	bind-key -n S-Left select-pane -L
	bind-key -n S-Right select-pane -R
	bind-key -n S-Up select-pane -U
	bind-key -n S-Down select-pane -D

	## Windows switching (ALT+ARROWS)
	bind-key -n M-Left  previous-window
	bind-key -n M-Right next-window

	## Windows re-ording (SHIFT+ALT+ARROWS)
	bind-key -n M-S-Left swap-window -t -1
	bind-key -n M-S-Right swap-window -t +1

	## Activity Monitoring
	setw -g monitor-activity on
	set -g visual-activity on

	## Set defaults
	set -g default-terminal screen-256color
	set -g history-limit 5000

	## Default windows titles
	set -g set-titles on
	set -g set-titles-string '#(whoami)@#H - #I:#W'

	## Last window switch
	bind-key C-a last-window

	## Reload settings (CTRL+a -> r)
	unbind r
	bind r source-file /etc/tmux.conf

	## Load custom sources
	#source ~/.bashrc   #(issues if you use /bin/bash & Debian)
	EOF
	[ -e /bin/zsh ] && echo -e '## Use ZSH as default shell\nset-option -g default-shell /bin/zsh\n' >> "${file}"
	cat <<-EOF >> "${file}"
	## Show tmux messages for longer
	set -g display-time 3000

	## Status bar is redrawn every minute
	set -g status-interval 60

	#-Theme------------------------------------------------------------------------
	## Default colours
	set -g status-bg black
	set -g status-fg white

	## Left hand side
	set -g status-left-length '34'
	set -g status-left '#[fg=green,bold]#(whoami)#[default]@#[fg=yellow,dim]#H #[fg=green,dim][#[fg=yellow]#(cut -d " " -f 1-3 /proc/loadavg)#[fg=green,dim]]'

	## Inactive windows in status bar
	set-window-option -g window-status-format '#[fg=red,dim]#I#[fg=grey,dim]:#[default,dim]#W#[fg=grey,dim]'

	## Current or active window in status bar
	#set-window-option -g window-status-current-format '#[bg=white,fg=red]#I#[bg=white,fg=grey]:#[bg=white,fg=black]#W#[fg=dim]#F'
	set-window-option -g window-status-current-format '#[fg=red,bold](#[fg=white,bold]#I#[fg=red,dim]:#[fg=white,bold]#W#[fg=red,bold])'

	## Right hand side
	set -g status-right '#[fg=green][#[fg=yellow]%Y-%m-%d #[fg=white]%H:%M#[fg=green]]'
	EOF
}

setup_firefox(){
	# Setup firefox
	(( STAGE++ )); install_software "firefox ~ GUI web browser" $STAGE $TOTAL unzip firefox-esr
	# Configure firefox
	timeout 15 firefox >/dev/null 2>&1                # Start and kill. Files needed for first time run
	timeout 5 killall -9 -q -w firefox-esr >/dev/null
	file=$(find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'prefs.js' -print -quit)
	[ -e "${file}" ] && cp -n $file{,.bkup} 
	([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
	sed -i 's/^.network.proxy.socks_remote_dns.*/user_pref("network.proxy.socks_remote_dns", true);' "${file}" 2>/dev/null \
	  || echo 'user_pref("network.proxy.socks_remote_dns", true);' >> "${file}"
	sed -i 's/^.browser.safebrowsing.enabled.*/user_pref("browser.safebrowsing.enabled", false);' "${file}" 2>/dev/null \
	  || echo 'user_pref("browser.safebrowsing.enabled", false);' >> "${file}"
	sed -i 's/^.browser.safebrowsing.malware.enabled.*/user_pref("browser.safebrowsing.malware.enabled", false);' "${file}" 2>/dev/null \
	  || echo 'user_pref("browser.safebrowsing.malware.enabled", false);' >> "${file}"
	sed -i 's/^.browser.safebrowsing.remoteLookups.enabled.*/user_pref("browser.safebrowsing.remoteLookups.enabled", false);' "${file}" 2>/dev/null \
	  || echo 'user_pref("browser.safebrowsing.remoteLookups.enabled", false);' >> "${file}"
	sed -i 's/^.*browser.startup.page.*/user_pref("browser.startup.page", 0);' "${file}" 2>/dev/null \
	  || echo 'user_pref("browser.startup.page", 0);' >> "${file}"
	sed -i 's/^.*privacy.donottrackheader.enabled.*/user_pref("privacy.donottrackheader.enabled", true);' "${file}" 2>/dev/null \
	  || echo 'user_pref("privacy.donottrackheader.enabled", true);' >> "${file}"
	sed -i 's/^.*browser.showQuitWarning.*/user_pref("browser.showQuitWarning", true);' "${file}" 2>/dev/null \
	  || echo 'user_pref("browser.showQuitWarning", true);' >> "${file}"
	sed -i 's/^.*extensions.https_everywhere._observatory.popup_shown.*/user_pref("extensions.https_everywhere._observatory.popup_shown", true);' "${file}" 2>/dev/null \
	  || echo 'user_pref("extensions.https_everywhere._observatory.popup_shown", true);' >> "${file}"
	sed -i 's/^.network.security.ports.banned.override/user_pref("network.security.ports.banned.override", "1-65455");' "${file}" 2>/dev/null \
	  || echo 'user_pref("network.security.ports.banned.override", "1-65455");' >> "${file}"
	# Replace bookmarks (base: http://pentest-bookmarks.googlecode.com)
	file=$(find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'bookmarks.html' -print -quit)
	[ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/firefox-esr/profile/bookmarks.html
	sed -i 's#^    <DL><p>#    <DL><p>\n    <DT><A HREF="http://127.0.0.1/">localhost</A>#' "${file}"                 # Add localhost to bookmark toolbar (before hackery folder)
	sed -i 's#^</DL><p>#    <DT><A HREF="https://127.0.0.1:8834/">Nessus</A>\n</DL><p>#' "${file}"                    # Add Nessus UI bookmark toolbar
	[ "${openVAS}" != "false" ] \
	  && sed -i 's#^</DL><p>#    <DT><A HREF="https://127.0.0.1:9392/">OpenVAS</A>\n</DL><p>#' "${file}"              # Add OpenVAS UI to bookmark toolbar
	sed -i 's#^</DL><p>#    <DT><A HREF="http://127.0.0.1:3000/ui/panel">BeEF</A>\n</DL><p>#' "${file}"               # Add BeEF UI to bookmark toolbar
	sed -i 's#^</DL><p>#    <DT><A HREF="http://127.0.0.1/rips/">RIPS</A>\n</DL><p>#' "${file}"                       # Add RIPs to bookmark toolbar
	sed -i 's#^</DL><p>#    <DT><A HREF="https://paulschou.com/tools/xlate/">XLATE</A>\n</DL><p>#' "${file}"          # Add XLATE to bookmark toolbar
	sed -i 's#^</DL><p>#    <DT><A HREF="https://hackvertor.co.uk/public">HackVertor</A>\n</DL><p>#' "${file}"        # Add HackVertor to bookmark toolbar
	sed -i 's#^</DL><p>#    <DT><A HREF="http://www.irongeek.com/skiddypad.php">SkiddyPad</A>\n</DL><p>#' "${file}"   # Add Skiddypad to bookmark toolbar
	sed -i 's#^</DL><p>#    <DT><A HREF="https://www.exploit-db.com/search/">Exploit-DB</A>\n</DL><p>#' "${file}"     # Add Exploit-DB to bookmark toolbar
	sed -i 's#^</DL><p>#    <DT><A HREF="http://offset-db.com/">Offset-DB</A>\n</DL><p>#' "${file}"                   # Add Offset-DB to bookmark toolbar
	sed -i 's#^</DL><p>#    <DT><A HREF="http://shell-storm.org/shellcode/">Shelcodes</A>\n</DL><p>#' "${file}"       # Add Shelcodes to bookmark toolbar
	sed -i 's#^</DL><p>#    <DT><A HREF="http://ropshell.com/">ROP Shell</A>\n</DL><p>#' "${file}"                    # Add ROP Shell to bookmark toolbar
	sed -i 's#^</DL><p>#    <DT><A HREF="https://ifconfig.io/">ifconfig</A>\n</DL><p>#' "${file}"                     # Add ifconfig.io to bookmark toolbar
	sed -i 's#<HR>#<DT><H3 ADD_DATE="1303667175" LAST_MODIFIED="1303667175" PERSONAL_TOOLBAR_FOLDER="true">Bookmarks Toolbar</H3>\n<DD>Add bookmarks to this folder to see them displayed on the Bookmarks Toolbar#' "${file}"
	# Clear bookmark cache
	find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -mindepth 1 -type f -name "places.sqlite" -delete
	find ~/.mozilla/firefox/*.default*/bookmarkbackups/ -type f -delete
	# Set firefox as XFCE's default
	mkdir -p ~/.config/xfce4/
	file=~/.config/xfce4/helpers.rc; [ -e "${file}" ] && cp -n $file{,.bkup}
	([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
	sed -i 's#^WebBrowser=.*#WebBrowser=firefox#' "${file}" 2>/dev/null || echo -e 'WebBrowser=firefox' >> "${file}"
	(( SKIPPED++ ))
	:<<- EOF  # TODO: Fix firefox plugin installation issues
	# Setup firefox's plugins
	(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Installing firefox's plugins ~ useful addons"
	# Download extensions
	ffpath="$(find ~/.mozilla/firefox/*.default*/ -maxdepth 0 -mindepth 0 -type d -name '*.default*' -print -quit)/extensions"
	[ "${ffpath}" == "/extensions" ] && write_output "Couldn't find Firefox folder" "error"
	mkdir -p "${ffpath}/"
	# Cookies Manager+
	echo -n '[1/2]'; timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/92079/addon-92079-latest.xpi?src=dp-btn-primary" \
	  -o "${ffpath}/{bb6bc1bb-f824-4702-90cd-35e2fb24f25d}.xpi" || write_output "Issue downloading 'Cookies Manager+" "error"
	# FoxyProxy Basic
	echo -n '[2/2]'; timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/15023/addon-15023-latest.xpi?src=dp-btn-primary" \
	  -o "${ffpath}/foxyproxy-basic@eric.h.jung.xpi" || write_output "Issue downloading 'FoxyProxy Basic" "error"
	# Installing extensions
	for FILE in $(find "${ffpath}" -maxdepth 1 -type f -name '*.xpi'); do
		d="$(basename "${FILE}" .xpi)"
		mkdir -p "${ffpath}/${d}/"
		unzip -q -o -d "${ffpath}/${d}/" "${FILE}"
		rm -f "${FILE}"
	done
	# Enable Firefox's addons/plugins/extensions
	timeout 15 firefox >/dev/null 2>&1
	timeout 5 killall -9 -q -w firefox-esr >/dev/null
	sleep 3s
	# Method #1 (Works on older versions)
	file=$(find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'extensions.sqlite' -print -quit)
	if [[ -e "${file}" ]] || [[ -n "${file}" ]]; then
		write_output "Enabled Firefox's extensions (via method #1 - extensions.sqlite)" "warning"
		apt -y -qq install sqlite3 || write_output "Issue with apt install" "error"
		rm -f /tmp/firefox.sql
		touch /tmp/firefox.sql
		echo "UPDATE 'main'.'addon' SET 'active' = 1, 'userDisabled' = 0;" > /tmp/firefox.sql    # Force them all!
		sqlite3 "${file}" < /tmp/firefox.sql      #fuser extensions.sqlite
	fi
	# Method #2 (Newer versions)
	file=$(find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'extensions.json' -print -quit)   #&& [ -e "${file}" ] && cp -n $file{,.bkup}
	if [[ -e "${file}" ]] || [[ -n "${file}" ]]; then
		write_output "Enabled Firefox's extensions (via method #2 - extensions.json)" "warning"
		sed -i 's/"active":false,/"active":true,/g' "${file}"                # Force them all!
		sed -i 's/"userDisabled":true,/"userDisabled":false,/g' "${file}"    # Force them all!
	fi
	# Remove cache
	file=$(find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'prefs.js' -print -quit)   #&& [ -e "${file}" ] && cp -n $file{,.bkup}
	[ -n "${file}" ] && sed -i '/extensions.installCache/d' "${file}"
	# For extensions that just work without restarting
	timeout 15 firefox >/dev/null 2>&1
	timeout 5 killall -9 -q -w firefox-esr >/dev/null
	sleep 3s
	# For (most) extensions, as they need firefox to restart
	timeout 15 firefox >/dev/null 2>&1
	timeout 5 killall -9 -q -w firefox-esr >/dev/null
	sleep 5s
	# Wipe session (due to force close)
	find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'sessionstore.*' -delete
	# Configure foxyproxy
	file=$(find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'foxyproxy.xml' -print -quit)   #&& [ -e "${file}" ] && cp -n $file{,.bkup}
	if [[ -z "${file}" ]]; then
		write_output "Something went wrong with the FoxyProxy firefox extension (did any extensions install?). Skipping..." "error"
	else 
	  echo -ne '<?xml version="1.0" encoding="UTF-8"?>\n<foxyproxy mode="disabled" selectedTabIndex="0" toolbaricon="true" toolsMenu="true" contextMenu="false" advancedMenus="false" previousMode="disabled" resetIconColors="true" useStatusBarPrefix="true" excludePatternsFromCycling="false" excludeDisabledFromCycling="false" ignoreProxyScheme="false" apiDisabled="false" proxyForVersionCheck=""><random includeDirect="false" includeDisabled="false"/><statusbar icon="true" text="false" left="options" middle="cycle" right="contextmenu" width="0"/><toolbar left="options" middle="cycle" right="contextmenu"/><logg enabled="false" maxSize="500" noURLs="false" header="&lt;?xml version=&quot;1.0&quot; encoding=&quot;UTF-8&quot;?&gt;\n&lt;!DOCTYPE html PUBLIC &quot;-//W3C//DTD XHTML 1.0 Strict//EN&quot; &quot;http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd&quot;&gt;\n&lt;html xmlns=&quot;http://www.w3.org/1999/xhtml&quot;&gt;&lt;head&gt;&lt;title&gt;&lt;/title&gt;&lt;link rel=&quot;icon&quot; href=&quot;http://getfoxyproxy.org/favicon.ico&quot;/&gt;&lt;link rel=&quot;shortcut icon&quot; href=&quot;http://getfoxyproxy.org/favicon.ico&quot;/&gt;&lt;link rel=&quot;stylesheet&quot; href=&quot;http://getfoxyproxy.org/styles/log.css&quot; type=&quot;text/css&quot;/&gt;&lt;/head&gt;&lt;body&gt;&lt;table class=&quot;log-table&quot;&gt;&lt;thead&gt;&lt;tr&gt;&lt;td class=&quot;heading&quot;&gt;${timestamp-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${url-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${proxy-name-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${proxy-notes-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-name-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-case-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-type-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-color-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pac-result-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${error-msg-heading}&lt;/td&gt;&lt;/tr&gt;&lt;/thead&gt;&lt;tfoot&gt;&lt;tr&gt;&lt;td/&gt;&lt;/tr&gt;&lt;/tfoot&gt;&lt;tbody&gt;" row="&lt;tr&gt;&lt;td class=&quot;timestamp&quot;&gt;${timestamp}&lt;/td&gt;&lt;td class=&quot;url&quot;&gt;&lt;a href=&quot;${url}&quot;&gt;${url}&lt;/a&gt;&lt;/td&gt;&lt;td class=&quot;proxy-name&quot;&gt;${proxy-name}&lt;/td&gt;&lt;td class=&quot;proxy-notes&quot;&gt;${proxy-notes}&lt;/td&gt;&lt;td class=&quot;pattern-name&quot;&gt;${pattern-name}&lt;/td&gt;&lt;td class=&quot;pattern&quot;&gt;${pattern}&lt;/td&gt;&lt;td class=&quot;pattern-case&quot;&gt;${pattern-case}&lt;/td&gt;&lt;td class=&quot;pattern-type&quot;&gt;${pattern-type}&lt;/td&gt;&lt;td class=&quot;pattern-color&quot;&gt;${pattern-color}&lt;/td&gt;&lt;td class=&quot;pac-result&quot;&gt;${pac-result}&lt;/td&gt;&lt;td class=&quot;error-msg&quot;&gt;${error-msg}&lt;/td&gt;&lt;/tr&gt;" footer="&lt;/tbody&gt;&lt;/table&gt;&lt;/body&gt;&lt;/html&gt;"/><warnings/><autoadd enabled="false" temp="false" reload="true" notify="true" notifyWhenCanceled="true" prompt="true"><match enabled="true" name="Dynamic AutoAdd Pattern" pattern="*://${3}${6}/*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/><match enabled="true" name="" pattern="*You are not authorized to view this page*" isRegEx="false" isBlackList="false" isMultiLine="true" caseSensitive="false" fromSubscription="false"/></autoadd><quickadd enabled="false" temp="false" reload="true" notify="true" notifyWhenCanceled="true" prompt="true"><match enabled="true" name="Dynamic QuickAdd Pattern" pattern="*://${3}${6}/*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/></quickadd><defaultPrefs origPrefetch="null"/><proxies>' > "${file}"
	  echo -ne '<proxy name="localhost:8080" id="1145138293" notes="e.g. Burp, w3af" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="#07753E" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8080" socksversion="5" isSocks="false" username="" password="" domain=""/></proxy>' >> "${file}"
	  echo -ne '<proxy name="localhost:8081 (socket5)" id="212586674" notes="e.g. SSH" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="#917504" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8081" socksversion="5" isSocks="true" username="" password="" domain=""/></proxy>' >> "${file}"
	  echo -ne '<proxy name="No Caching" id="3884644610" notes="" fromSubscription="false" enabled="true" mode="system" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="#990DA6" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="" port="" socksversion="5" isSocks="false" username="" password="" domain=""/></proxy>' >> "${file}"
	  echo -ne '<proxy name="Default" id="3377581719" notes="" fromSubscription="false" enabled="true" mode="direct" selectedTabIndex="0" lastresort="true" animatedIcons="false" includeInCycle="true" color="#0055E5" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="false" disableCache="false" clearCookiesBeforeUse="false" rejectCookies="false"><matches><match enabled="true" name="All" pattern="*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/></matches><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="" port="" socksversion="5" isSocks="false" username="" password=""/></proxy>' >> "${file}"
	  echo -e '</proxies></foxyproxy>' >> "${file}"
	fi
	EOF
}

setup_conky(){
	# Install conky
	(( STAGE++ )); install_software "conky ~ GUI desktop monitor" $STAGE $TOTAL conky
	# Configure conky
	file=~/.conkyrc; [ -e "${file}" ] && cp -n $file{,.bkup}
	if [[ -f "${file}" ]]; then
		write_output "${file} detected. Skipping..." "error"
	else
	  cat <<-EOF > "${file}"
	--# Useful: http://forums.opensuse.org/english/get-technical-help-here/how-faq-forums/unreviewed-how-faq/464737-easy-configuring-conky-conkyconf.html
	# Utils conky config

	background no
	use_xft yes
	xftfont Sans:size=8
	xftalpha 1
	update_interval 1
	total_run_times 0
	own_window yes
	own_window_title conky
	own_window_type normal
	own_window_transparent yes
	own_window_hints undecorated,below,sticky,skip_taskbar,skip_pager
	own_window_argb_visual yes
	own_window_argb_value 128
	double_buffer yes
	minimum_size 100 100
	maximum_width 400
	draw_shades yes
	draw_outline no
	draw_borders no
	draw_graph_borders yes
	default_color white
	default_shade_color black
	default_outline_color white
	alignment top_right
	gap_x 10
	gap_y 0
	no_buffers yes
	uppercase no
	cpu_avg_samples 2
	override_utf8_locale yes
	# lua_load /home/juanjo/conky/draw_bg.lua
	# lua_draw_hook_pre draw_bg
	 
	TEXT
	\${font sans-serif:bold:size=8}\${color eee}SYSTEM \${hr 2}\${font sans-serif:normal:size=8}
	\${color eee}Host\$color: \$nodename  \${alignr}\${color eee}Uptime\$color: \$uptime

	\${font sans-serif:bold:size=8}\${color eee}CPU \${hr 2}\${font sans-serif:normal:size=8}
	CPU0: \${cpu cpu0}% \${cpubar cpu0}
	CPU1: \${cpu cpu1}% \${cpubar cpu1}
	CPU2: \${cpu cpu2}% \${cpubar cpu2}
	CPU3: \${cpu cpu3}% \${cpubar cpu3}

	\${font sans-serif:bold:size=8}\${color eee}MEMORY \${hr 2}
	\${font sans-serif:normal:size=8}RAM \$alignc \$mem / \$memmax \$alignr \$memperc%
	\${font sans-serif:normal:size=8}SWAP \$alignc \$swap / \$swapmax \$alignr \$swapperc%

	\${color eee}LAN eth0 (\${addr eth0}) \${hr 2}\$color
	\${color eee}Down\$color:  \${downspeed eth0} KB/s\${alignr}\${color eee}Up\$color: \${upspeed eth0} KB/s
	\${color eee}Downloaded\$color: \${totaldown eth0} \${alignr}\${color eee}Uploaded\$color: \${totalup eth0}
	\${downspeedgraph eth0 25,120 000000 00ff00} \${alignr}\${upspeedgraph eth0 25,120 000000 ff0000}\$color

	\${font sans-serif:bold:size=8}\${color eee}DISKs \${hr 2}
	\${font sans-serif:normal:size=8}Root \$alignc \${fs_used /} / \${fs_size /} \$alignr\${fs_used_perc /}%
	\${fs_bar /}

	\${color eee}CONNECTIONS \${hr 2}\$color
	\${color eee}Inbound: \$color\${tcp_portmon 1 32767 count}  \${alignc}\${color eee}Outbound: \$color\${tcp_portmon 32768 61000 count}\${alignr}\${color eee}Total: \$color\${tcp_portmon 1 65535 count}
	\${color eee}Inbound \${alignr}Local Service/Port\$color
	\$color \${tcp_portmon 1 32767 rhost 0} \${alignr}\${tcp_portmon 1 32767 lservice 0}
	\$color \${tcp_portmon 1 32767 rhost 1} \${alignr}\${tcp_portmon 1 32767 lservice 1}
	\$color \${tcp_portmon 1 32767 rhost 2} \${alignr}\${tcp_portmon 1 32767 lservice 2}
	\${color eee}Outbound \${alignr}Remote Service/Port\$color
	\$color \${tcp_portmon 32768 61000 rhost 0} \${alignr}\${tcp_portmon 32768 61000 rservice 0}
	\$color \${tcp_portmon 32768 61000 rhost 1} \${alignr}\${tcp_portmon 32768 61000 rservice 1}
	\$color \${tcp_portmon 32768 61000 rhost 2} \${alignr}\${tcp_portmon 32768 61000 rservice 2}
	EOF
	fi
	# Create start script
	mkdir -p /usr/local/bin/
	file=/usr/local/bin/start-conky; [ -e "${file}" ] && cp -n $file{,.bkup}
	cat <<-EOF > "${file}" || write_output "Issue with writing file" "error"
	#!/bin/bash

	[[ -z \${DISPLAY} ]] && export DISPLAY=:0.0

	$(which timeout) 10 $(which killall) -9 -q -w conky
	$(which sleep) 20s
	$(which conky) &
	EOF
	chmod -f 0500 "${file}"
	# Run now
	bash /usr/local/bin/start-conky >/dev/null 2>&1 &
	# Add to startup (each login)
	mkdir -p ~/.config/autostart/
	file=~/.config/autostart/conkyscript.desktop; [ -e "${file}" ] && cp -n $file{,.bkup}
	cat <<-EOF > "${file}" || write_output "Issue with writing file" "error"
	[Desktop Entry]
	Name=conky
	Exec=/usr/local/bin/start-conky
	Hidden=false
	NoDisplay=false
	X-GNOME-Autostart-enabled=true
	Type=Application
	Comment=
	EOF
	# Add keyboard shortcut (CTRL+r) to run the conky refresh script
	file=~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml   #; [ -e "${file}" ] && cp -n $file{,.bkup}
	if [ -e "${file}" ]; then
		grep -q '<property name="&lt;Primary&gt;r" type="string" value="/usr/local/bin/start-conky"/>' "${file}" || sed -i 's#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>\n      <property name="\&lt;Primary\&gt;r" type="string" value="/usr/local/bin/start-conky"/>#' "${file}"
	fi
}

setup_metasploit(){
	# Install metasploit ~ http://docs.kali.org/general-use/starting-metasploit-framework-in-kali
	(( STAGE++ )); install_software "metasploit ~ exploit framework" $STAGE $TOTAL metasploit-framework
	mkdir -p ~/.msf4/modules/{auxiliary,exploits,payloads,post}/

	# Fix any port issues
	file=$(find /etc/postgresql/*/main/ -maxdepth 1 -type f -name postgresql.conf -print -quit);
	[ -e "${file}" ] && cp -n $file{,.bkup}
	sed -i 's/port = .* #/port = 5432 /' "${file}"
	# Fix permissions - 'could not translate host name "localhost", service "5432" to address: Name or service not known'
	chmod 0644 /etc/hosts
	# Start services
	systemctl stop postgresql
	systemctl start postgresql
	msfdb reinit
	sleep 5s
	
	# Aliases time
	file=~/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
	([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
	# Aliases for console
	# Aliases to speed up msfvenom (create static output)
	grep -q "^alias msfvenom-list-all" "${file}" 2>/dev/null \
	  || echo "alias msfvenom-list-all='cat ~/.msf4/msfvenom/all'" >> "${file}"
	grep -q "^alias msfvenom-list-nops" "${file}" 2>/dev/null \
	  || echo "alias msfvenom-list-nops='cat ~/.msf4/msfvenom/nops'" >> "${file}"
	grep -q "^alias msfvenom-list-payloads" "${file}" 2>/dev/null \
	  || echo "alias msfvenom-list-payloads='cat ~/.msf4/msfvenom/payloads'" >> "${file}"
	grep -q "^alias msfvenom-list-encoders" "${file}" 2>/dev/null \
	  || echo "alias msfvenom-list-encoders='cat ~/.msf4/msfvenom/encoders'" >> "${file}"
	grep -q "^alias msfvenom-list-formats" "${file}" 2>/dev/null \
	  || echo "alias msfvenom-list-formats='cat ~/.msf4/msfvenom/formats'" >> "${file}"
	grep -q "^alias msfvenom-list-generate" "${file}" 2>/dev/null \
	  || echo "alias msfvenom-list-generate='_msfvenom-list-generate'" >> "${file}"
	grep -q "^function _msfvenom-list-generate" "${file}" 2>/dev/null || cat <<-EOF >> "${file}" || write_output "Issue with writing file" "error"
	function _msfvenom-list-generate {
	  mkdir -p ~/.msf4/msfvenom/
	  msfvenom --list > ~/.msf4/msfvenom/all
	  msfvenom --list nops > ~/.msf4/msfvenom/nops
	  msfvenom --list payloads > ~/.msf4/msfvenom/payloads
	  msfvenom --list encoders > ~/.msf4/msfvenom/encoders
	  msfvenom --help-formats 2> ~/.msf4/msfvenom/formats
	}
	EOF
	# Apply new aliases
	source "${file}" || source ~/.zshrc
	# Generate (Can't call alias)
	mkdir -p ~/.msf4/msfvenom/
	msfvenom --list > ~/.msf4/msfvenom/all
	msfvenom --list nops > ~/.msf4/msfvenom/nops
	msfvenom --list payloads > ~/.msf4/msfvenom/payloads
	msfvenom --list encoders > ~/.msf4/msfvenom/encoders
	msfvenom --help-formats 2> ~/.msf4/msfvenom/formats
	# First time run with Metasploit
	(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Starting Metasploit for the first time ~ this will take a ~350 seconds (~6 mintues)"
	echo "Started at: $(date)"
	systemctl start postgresql
	msfdb start
	msfconsole -q -x 'version;db_status;sleep 310;exit'
}

setup_gedit(){
	# Install Gedit
	(( STAGE++ )); install_software "Gedit ~ GUI text editor" $STAGE $TOTAL gedit
	# Configure Gedit
	dconf write /org/gnome/gedit/preferences/editor/wrap-last-split-mode "'word'"
	dconf write /org/gnome/gedit/preferences/ui/statusbar-visible true
	dconf write /org/gnome/gedit/preferences/editor/display-line-numbers true
	dconf write /org/gnome/gedit/preferences/editor/highlight-current-line true
	dconf write /org/gnome/gedit/preferences/editor/bracket-matching true
	dconf write /org/gnome/gedit/preferences/editor/insert-spaces true
	dconf write /org/gnome/gedit/preferences/editor/auto-indent true
	for plugin in modelines sort externaltools docinfo filebrowser quickopen time spell; do
		loaded=$( dconf read /org/gnome/gedit/plugins/active-plugins )
		echo ${loaded} | grep -q "'${plugin}'" && continue
		new=$( echo "${loaded} '${plugin}']" | sed "s/'] /', /" )
		dconf write /org/gnome/gedit/plugins/active-plugins "${new}"
	done
}

setup_burp_free(){
	# Install Burp Suite
	if [[ "${burpFree}" != "false" ]]; then
		(( STAGE++ )); install_software "Burp Suite (Community Edition) ~ web application proxy" $STAGE $Total burpsuite
		mkdir -p ~/.java/.userPrefs/burp/
		file=~/.java/.userPrefs/burp/prefs.xml;   #[ -e "${file}" ] && cp -n $file{,.bkup}
		[ -e "${file}" ] || cat <<-EOF > "${file}"
	<?xml version="1.0" encoding="UTF-8" standalone="no"?>
	<!DOCTYPE map SYSTEM "http://java.sun.com/dtd/preferences.dtd" >
	<map MAP_XML_VERSION="1.0">
	  <entry key="eulafree" value="2"/>
	  <entry key="free.suite.feedbackReportingEnabled" value="false"/>
	</map>
	EOF
		# Extract CA
		find /tmp/ -maxdepth 1 -name 'burp*.tmp' -delete
		timeout 120 burpsuite >/dev/null 2>&1 &
		PID=$!
		sleep 15s
		export http_proxy="http://127.0.0.1:8080"
		rm -f /tmp/burp.crt
		while test -d /proc/${PID}; do
	    	sleep 1s
	    	curl --progress -k -L -f "http://burp/cert" -o /tmp/burp.crt 2>/dev/null      # || echo -e ' '${RED}'[!]'${RESET}" Issue downloading burp.crt" 1>&2
	    	[ -f /tmp/burp.crt ] && break
		done
		timeout 5 kill ${PID} 2>/dev/null || echo -e ' '${RED}'[!]'${RESET}" Failed to kill ${RED}burpsuite${RESET}"
		unset http_proxy
		# Installing CA
		if [[ -f /tmp/burp.crt ]]; then
	    	apt -y -qq install libnss3-tools || write_output "Issue with apt install" "error"
	    	folder=$(find ~/.mozilla/firefox/ -maxdepth 1 -type d -name '*.default' -print -quit)
	   		certutil -A -n Burp -t "CT,c,c" -d "${folder}" -i /tmp/burp.crt
	    	timeout 15 firefox >/dev/null 2>&1
	    	timeout 5 killall -9 -q -w firefox-esr >/dev/null
	    	write_output "Installed Burp Suite CA" "warning"
		else
			write_output "Did not install Burp Suite Certificate Authority (CA)" "error"
			write_output "Skipping..." "error"
	  	fi
	  	# Remove old temp files
	  	sleep 2s
	  	find /tmp/ -maxdepth 1 -name 'burp*.tmp' -delete 2>/dev/null
	  	find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'sessionstore.*' -delete
	  	unset http_proxy
	else
		(( SKIPPED++ ))
	fi
}

configure_python(){
	# Configure python console - all users
	(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Configuring python console ~ tab complete & history support"
	export PYTHONSTARTUP=$HOME/.pythonstartup
	file=/etc/bash.bashrc; [ -e "${file}" ] && cp -n $file{,.bkup}   #~/.bashrc
	grep -q PYTHONSTARTUP "${file}" || echo 'export PYTHONSTARTUP=$HOME/.pythonstartup' >> "${file}"
	# Python start up file
	cat <<-EOF > ~/.pythonstartup || write_output "Issue with writing file" "error"
	import readline
	import rlcompleter
	import atexit
	import os

	## Tab completion
	readline.parse_and_bind('tab: complete')

	## History file
	histfile = os.path.join(os.environ['HOME'], '.pythonhistory')
	try:
	    readline.read_history_file(histfile)
	except IOError:
	    pass

	atexit.register(readline.write_history_file, histfile)

	## Quit
	del os, histfile, readline, rlcompleter
	EOF
	# Apply new configs
	source "${file}" || source ~/.zshrc
}

download_wordlists(){
	# https://github.com/fuzzdb-project/fuzzdb
	# Update wordlists
	(( STAGE++ )); install_software "wordlists ~ collection of wordlists" $STAGE $TOTAL wordlists seclists
	# Extract rockyou wordlist
	[ -e /usr/share/wordlists/rockyou.txt.gz ] && gzip -dc < /usr/share/wordlists/rockyou.txt.gz > /usr/share/wordlists/rockyou.txt
	# Add 10,000 Top/Worst/Common Passwords
	mkdir -p /usr/share/wordlists/
	unzip -q -o -d /usr/share/wordlists/ /tmp/10kcommon.zip 2>/dev/null   #***!!! hardcoded version! Need to manually check for updates
	mv -f /usr/share/wordlists/10k{\ most\ ,_most_}common.txt
	# Linking to more - folders
	[ -e /usr/share/dirb/wordlists ] \
	  && ln -sf /usr/share/dirb/wordlists /usr/share/wordlists/dirb
	# Extract sqlmap wordlist
	unzip -o -d /usr/share/sqlmap/txt/ /usr/share/sqlmap/txt/wordlist.zip
	ln -sf /usr/share/sqlmap/txt/wordlist.txt /usr/share/wordlists/sqlmap.txt
}

configure_ssh(){
	# Setup SSH
	(( STAGE++ )); install_software "SSH ~ CLI access" $STAGE $TOTAL openssh-server
	# Wipe current keys
	rm -f /etc/ssh/ssh_host_*
	find ~/.ssh/ -type f ! -name authorized_keys -delete 2>/dev/null
	# Generate new keys
	ssh-keygen -b 4096 -t rsa1 -f /etc/ssh/ssh_host_key -P "" >/dev/null
	ssh-keygen -b 4096 -t rsa -f /etc/ssh/ssh_host_rsa_key -P "" >/dev/null
	ssh-keygen -b 1024 -t dsa -f /etc/ssh/ssh_host_dsa_key -P "" >/dev/null
	ssh-keygen -b 521 -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -P "" >/dev/null
	ssh-keygen -b 4096 -t rsa -f ~/.ssh/id_rsa -P "" >/dev/null
	# Change MOTD
	# TODO: Change MOTD
	# apt -y -qq install cowsay || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
	# echo "Moo" | /usr/games/cowsay > /etc/motd
	# Change SSH settings
	file=/etc/ssh/sshd_config; [ -e "${file}" ] && cp -n $file{,.bkup}
	sed -i 's/^PermitRootLogin .*/PermitRootLogin yes/g' "${file}"      # Accept password login (overwrite Debian 8+'s more secure default option...)
	sed -i 's/^#AuthorizedKeysFile /AuthorizedKeysFile /g' "${file}"    # Allow for key based login

	# Setup alias (handy for 'zsh: correct 'ssh' to '.ssh' [nyae]? n')
	file=~/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
	([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
	grep -q '^## ssh' "${file}" 2>/dev/null || echo -e '## ssh\nalias ssh-start="systemctl restart ssh"\nalias ssh-stop="systemctl stop ssh"\n' >> "${file}"
	# Apply new alias
	source "${file}" || source ~/.zshrc
}

download_extras(){
	# Downloading AccessChk.exe
	(( STAGE++ )); write_output "Downloading AccessChk.exe"
	echo -n '[1/2]'; timeout 300 curl --progress -k -L -f "https://web.archive.org/web/20080530012252/http://live.sysinternals.com/accesschk.exe" > /usr/share/windows-binaries/accesschk_v5.02.exe \
	  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading accesschk_v5.02.exe" 1>&2   #***!!! hardcoded path!
	echo -n '[2/2]'; timeout 300 curl --progress -k -L -f "https://download.sysinternals.com/files/AccessChk.zip" > /usr/share/windows-binaries/AccessChk.zip \
	  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading AccessChk.zip" 1>&2
	unzip -q -o -d /usr/share/windows-binaries/ /usr/share/windows-binaries/AccessChk.zip
	rm -f /usr/share/windows-binaries/{AccessChk.zip,Eula.txt}

	# Downloading PsExec.exe
	(( STAGE++ )); write_output "Downloading PsExec.exe"
	echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Downloading ${GREEN}PsExec.exe${RESET} ~ Pass The Hash 'phun'"
	echo -n '[1/2]'; timeout 300 curl --progress -k -L -f "https://download.sysinternals.com/files/PSTools.zip" > /tmp/pstools.zip \
	  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading pstools.zip" 1>&2
	echo -n '[2/2]'; timeout 300 curl --progress -k -L -f "http://www.coresecurity.com/system/files/pshtoolkit_v1.4.rar" > /tmp/pshtoolkit.rar \
	  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading pshtoolkit.rar" 1>&2  #***!!! hardcoded path!
	unzip -q -o -d /usr/share/windows-binaries/pstools/ /tmp/pstools.zip
	unrar x -y /tmp/pshtoolkit.rar /usr/share/windows-binaries/ >/dev/null

	# Install PyCharm (Community Edition)
	(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Installing PyCharm (Community Edition) ~ Python IDE"
	timeout 300 curl --progress -k -L -f "https://download.jetbrains.com/python/pycharm-community-2017.3.2.tar.gz" > /tmp/pycharms-community.tar.gz || echo -e ' '${RED}'[!]'${RESET}" Issue downloading pycharms-community.tar.gz" 1>&2
	if [ -e /tmp/pycharms-community.tar.gz ]; then
		tar -xf /tmp/pycharms-community.tar.gz -C /tmp/
	    rm -rf /opt/pycharms/
	    mv -f /tmp/pycharm-community-*/ /opt/pycharms
	    mkdir -p /usr/local/bin/
	    ln -sf /opt/pycharms/bin/pycharm.sh /usr/local/bin/pycharms
	fi
}

install_git_extras(){
	# Install python-pty-shells
	(( STAGE++ )); git_install_software "python-pty-shells ~ PTY shells" "https://github.com/infodox/python-pty-shells.git" "/python-pty-shells" $STAGE $TOTAL

	# Install NoSQLMap need to run setup.py 
	(( STAGE++ )); git_install_software "NoSQLMap ~ MongoDB Pentesting Tool" "https://github.com/tcstool/NoSQLMap.git" "NoSQLMap" $STAGE $TOTAL

	# Install EyeWitness
	(( STAGE++ )); git_install_software "EyeWitness ~ Web screen shot and header utility" "https://github.com/ChrisTruncer/EyeWitness.git" "eyewitness" $STAGE $TOTAL

	# Install nishang
	(( STAGE++ )); git_install_software "nishang ~ Powershell Exploitation and Post Exploitation" "https://github.com/samratashok/nishang.git" "nishang" $STAGE $TOTAL
		
	# Install Powersploit
	(( STAGE++ )); git_install_software "Powersploit ~ Powershell Post Exploitation" "https://github.com/PowerShellMafia/PowerSploit.git" "Powersploit" $STAGE $TOTAL
	wget -P /opt/Powersploit https://raw.githubusercontent.com/obscuresec/random/master/StartListener.py
	wget -P /opt/Powersploit https://raw.githubusercontent.com/darkoperator/powershell_scripts/master/ps_encoder.py

	# Install Net-Creds
	(( STAGE++ )); git_install_software "net-creds ~ PCAP Parser" "https://github.com/DanMcInerney/net-creds.git" "net-creds" $STAGE $TOTAL
		
	# Install recon-ng
	(( STAGE++ )); git_install_software "recon-ng ~ Web recon framework" "https://bitbucket.org/LaNMaSteR53/recon-ng.git" "recon-ng" $STAGE $TOTAL

	# Install Empire
	(( STAGE++ )); git_install_software "Empire ~ PowerShell post-exploitation" "https://github.com/PowerShellEmpire/Empire.git" "empire" $STAGE $TOTAL

	# Install CMSmap
	(( STAGE++ )); git_install_software "CMSmap ~ CMS detection" "https://github.com/Dionach/CMSmap.git" "cmsmap" $STAGE $TOTAL
	# Add to path
	mkdir -p /usr/local/bin/
	file=/usr/local/bin/cmsmap-git
	cat <<-EOF > "${file}" || write_output "Issue with writing file" "error"
	#!/bin/bash

	cd /opt/cmsmap/ && python cmsmap.py "\$@"
	EOF
	chmod +x "${file}"

	# Install droopescan
	(( STAGE++ )); git_install_software "DroopeScan ~ Drupal vulnerability scanner" "https://github.com/droope/droopescan.git" "droopescan" $STAGE $TOTAL
	# Add to path
	mkdir -p /usr/local/bin/
	file=/usr/local/bin/droopescan
	cat <<-EOF > "${file}" || write_output "Issue with writing file" "error"
	#!/bin/bash

	cd /opt/droopescan/ && python droopescan "\$@"
	EOF
	chmod +x "${file}"
}

clean_system(){
	# Clean the system
	(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Cleaning the system"
	# Clean package manager
	for FILE in clean autoremove; do apt -y -qq "${FILE}"; done
	apt -y -qq purge $(dpkg -l | tail -n +6 | egrep -v '^(h|i)i' | awk '{print $2}')  # Purged packages
	updatedb
	cd ~/ &>/dev/null
	history -cw 2>/dev/null
	for i in $(cut -d: -f6 /etc/passwd | sort -u); do
		[ -e "${i}" ] && find "${i}" -type f -name '.*_history' -delete
	done
}

install_basics(){
	(( STAGE++ )); install_software "The Basics" $STAGE $TOTAL git

	# Install "kali full" meta packages (default tool selection)
	(( STAGE++ )); install_software "Kali-linux-full" $STAGE $TOTAL kali-linux-full
}

disable_gnome_interupts(){
	# Check if we're using gnome desktop environment
	if [[ $(which gnome-shell) ]]; then
		# RAM check
		if [[ "$(free -m | grep -i Mem | awk '{print $2}')" < 2048 ]]; then
			write_output "You have <= 2GB of RAM and using GNOMAE" "error"
			write_output "You might want to use XFCE instead..." "error"
			sleep 15s
		fi
		# Disable its auto notification package updater
		(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Disabling GNOME's notification package updater service in case it runs during this script"
		timeout 5 killall -w /usr/lib/apt/methods/http >/dev/null 2>&1

		# Disable screensaver
		(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Disabling screensaver"
	  	xset s 0 0
	  	xset s off
	  	gsettings set org.gnome.desktop.session idle-delay 0
	else
		SKIPPED=$((SKIPPED+2))
		write_output "Skipping disabling package updater for GNOME" "warning"
	fi
}

footer(){
	### Done
	# Time taken
	finish_time=$(date +%s)
	write_output "Time (roughly) taken: $(( $(( finish_time - START_TIME )) / 60 )) minutes"
	write_output "Stages skipped: $(( SKIPPED ))"

	# Final Notes
	write_output "Don't forget to:" "warning"
	write_output "+ Check the above output (Did everything install? Any errors? (HINT: What's in RED?)" "error"
	write_output "+ Manually install: Nessus, Nexpose, and/or Metasploit Community" "warning"
	write_output "+ Agree/Accept to: Maltego, OWASP ZAP, w3af, PyCharm, etc" "warning"
	write_output "+ Setup git: git config --global user.name <name>;git config --global user.email <email>" "warning"
	write_output "+ Change default passwords: PostgreSQL/MSF, MySQL, OpenVAS, BeEF XSS, etc" "warning"
	write_output "+ Reboot to update UI$" "warning"
	(dmidecode | grep -iq virtual) && write_output "+ Take a snapshot  (Virtual machine detected)" "warning"

	write_output "Done!" "header"
}

### Main
root_check
# Fix display output for GUI programs (when connecting via SSH)
export DISPLAY=:0.0
export TERM=xterm


disable_gnome_interupts
internet_connectivity_check
enable_network_repos
install_vm_drivers
install_basics
harden_dns
network_update
setup_bash
setup_alias
setup_terminator
setup_zsh
setup_tmux
setup_firefox
setup_conky
setup_metasploit
setup_gedit
setup_burp_free
configure_python
download_wordlists
install_apt_extras
install_git_extras
download_extras
configure_grub
configure_gnome
configure_xfce
configure_filebrowser
configure_wallpapers
# Custom insert for additional tools/code


clean_system
footer
exit 0
