(( STAGE++ )); write_output "(${STAGE}/${TOTAL}) Configuring XFCE4 ~ desktop environment"
		# Configuring XFCE
		mkdir -p ~/.config/xfce4/panel/launcher-{2,4,5,6,7,8,9}/
		mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml/
		# Keyboard shortcuts
		cat <<-EOF > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml || write_output "Issue with writing file" "error"
		EOF
		# Power Options
		cat <<-EOF > ~/.config/xfce4/xfconf/xfce-perchannel-xml/ || write_output "Issue with writing file" "error"
		EOF
		# Greeter settings
		wget -P /usr/share/wallpapers https://github.com/brutalgg/wallpapers/raw/master/login_icon.png
		wget -P /usr/share/wallpapers https://github.com/brutalgg/wallpapers/raw/master/login_wallpaper.jpg
		cat <<-EOF > /etc/lightdm/lightdm-gtk-greeter.conf || write_output "Issue with writing file" "error"
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