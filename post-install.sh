#! /bin/bash

# COLORS {{{
Bold=$(tput bold)
Underline=$(tput sgr 0 1)
Reset=$(tput sgr0)
# Regular Colors
Red=$(tput setaf 1)
Green=$(tput setaf 2)
Yellow=$(tput setaf 3)
Blue=$(tput setaf 4)
Purple=$(tput setaf 5)
Cyan=$(tput setaf 6)
White=$(tput setaf 7)
# Bold
BRed=${Bold}$(tput setaf 1)
BGreen=${Bold}$(tput setaf 2)
BYellow=${Bold}$(tput setaf 3)
BBlue=${Bold}$(tput setaf 4)
BPurple=${Bold}$(tput setaf 5)
BCyan=${Bold}$(tput setaf 6)
BWhite=${Bold}$(tput setaf 7)

print_line() {
  printf "%$(tput cols)s\n"|tr ' ' '-'
}
print_title() {
  #clear
  print_line
  echo -e "# ${BPurple}$1${Reset}"
  print_line
  echo ""
}
print_question(){
  T_COLS=`tput cols`
  echo -n "${BBlue}$1${Reset}"
}

print_msg(){
  T_COLS=`tput cols`
  echo -e "${BGreen}$1${Reset}"
  sleep 2
}

print_info() {
  #Console width number
  T_COLS=`tput cols`
  echo -e "${Bold}$1${Reset}\n" | fold -sw $(( $T_COLS - 18 )) | sed 's/^/\t    /'
}
print_warning() {
  T_COLS=`tput cols`
  echo -e "${BYellow}$1${Reset}\n" | fold -sw $(( $T_COLS - 1 ))
  sleep 4
}


print_title 'Arch Linux Postinstall'



alpi_user(){
  print_title "User"
  print_question "Create new user? [Y|n]"
  read yn
  yn=${yn:-y}
  if [ "$yn" == "y" ]; then
    print_question "Enter user name:"
    read username
    useradd -m -g users -G wheel,sys -s /bin/bash ${username}
    chfn ${username}
    passwd ${username}
    print_msg "user $username created"
    pacman -S --needed --no-confirm sudo
    echo "$username	ALL=(ALL) ALL" >> /etc/sudoers
    print_msg "$username added to sudoers"
    print_question "switch now to $username? you'll have to restart the script [Y|n]"
    read yn
    yn=${yn:-y}
    if [ "$yn" == "y" ]; then
      su ${username}
    fi
  fi
}

alpi_avahi(){
  print_msg "install avahi"
  sudo pacman -S --needed --noconfirm -q avahi nss-mdns
  print_msg "configure avahi"
  sudo systemctl enable avahi-daemon
  sudo systemctl start avahi-deamon
  sudo sed -i.back 's/hosts: files dns myhostname/hosts: files mdns_minimal [NOTFOUND=return] dns myhostname/' /etc/nsswitch.conf
}

alpi_basics(){
  print_title "basic packages install"
  print_question "install basic pkgs? [Y|n]"
  read yn
  yn=${yn:-y}
  if [ "$yn" == "y" ]; then
    sudo pacman -S --needed --noconfirm -q vim rsync acpi parted imagemagick lynx wget alsa-utils tmux git openssh knockd bluez-utils htop
    print_msg 'securing ssh'
    sudo sed -i.back 's/^#PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
    sudo sed -i.back 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo systemctl enable sshd
    sudo systemctl start sshd

    # increase watch limit
    echo 100000 | sudo tee -a /usr/lib/sysctl.d/50-default.conf

    alpi_avahi
    print_msg "basic packages and configuration installed"
  fi
}

alpi_multilib(){
  # https://wiki.archlinux.org/index.php/Multilib
  print_msg "Enable Multilib repository package"
  sudo sed -i.back 's/^#[multilib]$/[multilib]/' /etc/pacman.conf
  sudo sed -i.back 's/^#Include = \/etc/pacman\.d\/mirrorlist$/Include = /etc/pacman.d/mirrorlist/' /etc/pacman.conf
  sudo pacman -Syy
}

alpi_cosmetics(){
  print_title "apply pacman, bash, vim and git config (needs basic pkgs install)"
  alpi_basics
  _cwd="$(pwd)"
  # vim
  print_msg 'vim configuration'
  sudo pacman -S --needed --noconfirm -q vim-{spell-fr,spell-en,nerdtree,supertab,systemd}
  cp -r $_cwd/assets/vim /home/$USER/.vim
  cp $_cwd/assets/vimrc /home/$USER/.vimrc
  sudo cp -r $_cwd/assets/vim /root/.vim
  sudo cp $_cwd/assets/vimrc /root/.vimrc

  print_msg 'Git Completion'
  sudo pacman -S --needed --noconfirm -q bash-completion
  sudo mkdir /etc/bash_completion.d
  sudo wget -O /etc/bash_completion.d/git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash

  # bash & prompt
  print_msg 'Bash and Prompt (liquidprompt)'
  git clone https://github.com/nojhan/liquidprompt.git -o github /home/$USER/.liquidprompt
  cp $_cwd/assets/bash_profile /home/$USER/.bash_profile
  cp $_cwd/assets/bashrc /home/$USER/.bashrc
  mkdir /home/$USER/.config
  cp $_cwd/assets/config/liquidpromptrc /home/$USER/.config/
  # sudo pacman -S --needed --noconfirm -q bash-completion
  source /home/$USER/.bashrc

  touch /home/$USER/.inputrc
  echo 'set show-all-if-ambiguous on' >> /home/$USER/.inputrc
  echo 'set completion-ignore-case on' >> /home/$USER/.inputrc

  print_msg "I love candy! (pacman)"
  sudo sed -i.back 's/^#Color$/Color/' /etc/pacman.conf
  sudo sed -i.back 's/^#TotalDownload$/TotalDownload\nILoveCandy/' /etc/pacman.conf
  # sudo sed -i.back 's/.*\[options\].*/&\nILoveCandy/' /etc/pacman.conf

  print_msg "Bins"
  cp -r $_cwd/assets/bin /home/$USER/.bin

  #DefaultTimeoutStopSec=30s /etc/systemd/system.conf

  print_msg 'Config and Cosmetics done'
}

# GPG
alpi_gnupg(){
  print_title 'Setup a gpg encripting'
  print_msg 'see https://wiki.archlinux.org/index.php/GnuPG'
  print_question "create your gpg encrypting key? [Y|n] "
  read yn
  yn=${yn:-y}
  if [ "$yn" == "y" ]; then
    gpg --full-gen-key
  fi
  print_msg 'Gnupg done!'
}

alpi_secure(){
  print_title 'Basic securing system'

  print_msg 'remove root autologin'
  sudo sed -i.back 's/--autologin root //' /etc/systemd/system/getty@tty1.service.d/autologin.conf

  print_msg 'remove root login'
  sudo sed -i.back 's/#auth\srequired\spam_wheel.so\suse_uid/auth	required	spam_wheel.so use_uid/' /etc/pam.d/su
  sudo sed -i.back 's/#auth\srequired\spam_wheel.so\suse_uid/auth	required	spam_wheel.so use_uid/' /etc/pam.d/su-l

  print_msg 'restrict log access to root'
  sudo touch /etc/sysctl.d/50-dmesg-restrict.conf
  sudo sh -c "echo 'kernel.dmesg_restrict = 1' >> /etc/sysctl.d/50-dmesg-restrict.conf"
  sudo touch /etc/sysctl.d/50-kptr-restrict.con
  sudo sh -c "echo 'kernel.kptr_restrict = 1' >> /etc/sysctl.d/50-kptr-restrict.conf"

  print_msg 'basics secure done'
}


# Display Manager
alpi_xserver(){
  print_title "install Graphical Display Part 1 : Xorg server"
  print_msg "you will have to reboot at the end of part 1"
  print_question "install xorg server? [Y|n] "
  read yn
  yn=${yn:-y}
  if [ "$yn" == "y" ]; then
    # touch pad
    sudo pacman -S --needed --noconfirm -q xf86-input-libinput
    # integred gpu
    sudo pacman -S --needed --noconfirm -q xf86-video-intel
    # discret gpu
    # sudo pacman -S --needed --noconfirm -q bbswitch bumblebee primus
    # sudo pacman -S --needed --noconfirm -q nvidia nvidia-utils
    # xorg server
    sudo pacman -S --needed --noconfirm -q xorg-{server,xinit,server-utils,server-devel,xrandr,xclock} xterm
    sudo pacman -S --needed --noconfirm -q mesa mesa-{libgl,demos}
    sudo pacman -S --needed --noconfirm -q
    # xinitrc
    touch /home/$USER/.xinitrc
    cat /etc/X11/xinit/xinitrc > /home/$USER/
    print_warning "xorg install complete, reboot and run startx to test xorg"
    print_warning "run part 2 after reboot if you need kde : Desktop manager Plasma5"
    print_warning "press enter to reboot"
    read x
    sudo reboot
  fi
}

alpi_plasma5(){
  print_title "install Graphical Display Part 2 : Desktop Manager Plasma 5"
  print_question "install Kde Plasma 5? [Y|n] "
  read yn
  yn=${yn:-y}
  if [ "$yn" == "y" ]; then
    print_msg "plasma"
    sudo pacman -S --needed --noconfirm -q --force plasma-meta
    print_msg "fonts"
    sudo pacman -S --needed --noconfirm -q ttf-{dejavu,liberation,droid,ubuntu-font-family}
    print_msg "network & Bluetooth"
    sudo pacman -S --needed --noconfirm -q networkmanager-openvpn pulseaudio-alsa rfkill systemd-kcm bluedevil

    print_msg "plasma addons"
    sudo pacman -S --needed --noconfirm -q kdeplasma-addons
    print_msg "file explorer : Dolphin"
    sudo pacman -S --needed --noconfirm -q dolphin dolphin-plugins ark unzip zip
    print_msg 'kleopatra and spectacle'
    sudo pacman -S --needed --noconfirm -q kleopatra spectacle
    print_msg "web browser, terminal emulator, disk tool, password tool"
    sudo pacman -S --needed --noconfirm -q chromium terminator gparted keepassx2

    sudo systemctl enable NetworkManager
    sudo systemctl start NetworkManager
    sudo systemctl enable bluetooth
    sudo systemctl start bluetooth

    # TODO start kde with xinitrc
    # echo 'exec startkde' > /home/$USER/.xinitrc

    print_msg "Plasma 5 install complete!"
    print_msg 'add startkde on ~/.xinitrc then run "startx" to start x server with kde plasma 5'
  fi
}

# Yaourt
alpi_yaourt(){
  print_title "AUR helper : Yaourt"
  print_question "install Yaourt [Y|n] "
  read yaourt
  yaourt=${yaourt:-y}
  if [ "$yaourt" == "y" ]; then
    sudo pacman -S --needed base-devel
    mkdir -p /home/$USER/Developer/Linux/build-repos
    wget -O /home/$USER/Developer/Linux/build-repos/package-query.tar.gz https://aur.archlinux.org/cgit/aur.git/snapshot/package-query.tar.gz
    wget -O /home/$USER/Developer/Linux/build-repos/yaourt.tar.gz https://aur.archlinux.org/cgit/aur.git/snapshot/yaourt.tar.gz
    cd /home/$USER/Developer/Linux/build-repos
    tar -xvf package-query.tar.gz
    tar -xvf yaourt.tar.gz
    cd package-query
    makepkg -sri
    cd ../yaourt
    makepkg -sri
    echo 'ask for editing config file before build'
    echo "EDITFILES=1" >> ~/.yaourtrc
    print_msg "Yaourt install complete!"
  fi
}

alpi_cups(){
  print_title 'CUPS (for printing)'
  print_question "install cups [Y|n] "
  read yn
  yn=${yn:-y}
  if [ "$yn" == "y" ]; then
    sudo pacman -S --needed --noconfirm -q cups cups-filters libcups ghostscript gsfonts
    sudo pacman -S --needed --noconfirm -q gutenprint splix cups-pdf
    sudo pacman -S --needed --noconfirm -q print-manager
    alpi_avahi
    sudo systemctl enable org.cups.cupsd
    sudo systemctl start org.cups.cupsd
    sudo systemctl enable cups-browsed
    sudo systemctl start cups-browsed
    sudo gpasswd -a $USER sys
    print_msg "CUPS install complete!"
  fi
}

# kernel LTS
alpi_kernellts(){
  print_title "Long Term Support Kernel"
  print_question "install kernel-lts)? [Y|n]"
  read yn
  yn=${yn:-y}
  if [ "$yn" == "y" ]; then
    sudo pacman -S linux-lts linux-lts-headers nvidia-lts bbswitch-lts
    # TODO : add entrie for lts kernel on /boot/loader/entries
    print_msg "kernel LTS install complete!"
  fi
}

alpi_mysql(){
    print_msg "installe mysql"
    sudo pacman -S --needed --noconfirm -q mariadb
    print_msg "configure mysql"
    sudo mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    sudo systemctl start mysqld
    mysql_secure_installation
    sudo sed -i.back 's/^log-bin=mysql-bin$/#&/' /etc/mysql/my.cnf
    sudo sed -i.back 's/^max_allowed_packet.*$/max_allowed_packet = 16M/' /etc/mysql/my.cnf
}

# Packages
alpi_defaultpkgs(){
  print_title "Day to day software"
  print_question "install day to day packages? [Y|n]"
  read yn
  yn=${yn:-y}
  if [ "$yn" == "y" ]; then
    _cwd="$(pwd)"
    print_msg 'Pim softwares : mail, calendar, contact, etc'
    sudo pacman -S --needed --noconfirm -q kmail korganizer kaddressbook kdeconnect pidgin pidgin-kwallet
    sudo pacman -S --needed --noconfirm -q spamassassin razor
    sudo sa-update

    print_question "Install regular mysql support for akonadi? [Y|n] "
    read ako
    ako=${ako:-y}
    if [ "$ako" == "y" ]; then
      print_question "Should we install and configure mysql (if not already done)? [y|N] "
      read sql
      sql=${sql:-n}
      if [ "$sql" == "y" ]; then
        alpi_mysql
      fi

      # https://forum.kde.org/viewtopic.php?t=84478#p140762
      print_question "please type your root mysql password :"
      read -s -p Password: pswd
      mysql -u root -p$pswd -e "create database akonadi;"
      mysql -u root -p$pswd -e "create user 'akonadi'@'localhost' identified by 'akonadi';"
      mysql -u root -p$pswd -e "grant all privileges on akonadi.* to 'akonadi'@'localhost';"
      mysql -u root -p$pswd -e "flush privileges;"
      mkdir -p /home/$USER/.config/akonadi
      mv /home/$USER/.config/akonadi/akonadiserverrc /home/$USER/.config/akonadi/akonadiserverrc.back
      cp $_cwd/assets/akonadiserverrc /home/$USER/.config/akonadi/
      print_msg "Akonadi configured to use system wide sql server!"
    fi

    print_msg 'install office softwares'
    sudo pacman -S --needed --noconfirm -q gwenview kimageformats kdegraphics-okular kipi-plugins libreoffice-fresh hunspell-{fr,en}
    print_msg 'install media softwares'
    sudo pacman -S --needed --noconfirm -q digikam darktable vlc lua-socket ktorrent banshee

    print_msg 'install graphic softwares'
    sudo pacman -S --needed --noconfirm -q inkscape gimp scribus fontforge blender

    print_msg 'web dev softwares'
    sudo pacman -S --needed --noconfirm -q firefox filezilla gulp

    print_msg 'install cloud softwares'
    sudo pacman -S --needed --noconfirm -q owncloud-client syncthing syncthing-gtk syncthing-inotify
    print_msg 'increase inotify watch limit'
    sleep 3
    sudo cp $_cwd/assets/90-inotify.conf /etc/sysctl.d/

    if [ -f /usr/bin/yaourt ];
      then
        yaourt -S downgrade
        yaourt -S atom-editor
        yaourt -S pulseaudio-dlna
      else
        print_warning "some packages can't be installed because you don't have yaourt installed"
    fi
  fi
}

# LAMP
alpi_lamp(){
  # https://wiki.archlinux.org/index.php/Apache_HTTP_Server
  _cwd="$(pwd)"
  print_title "Web Server (apache, php, mysql)"
  print_question "Install apache php mysql? [Y|n] "
  read yn
  yn=${yn:-y}
  if [ "$yn" == "y" ]; then
    sudo pacman -S --needed --noconfirm -q apache php php-apache phpmyadmin php-mcrypt php-gd
    print_question "Should we install and configure mysql (if not already done)? [y|N] "
    read sql
    sql=${sql:-n}
    if [ "$sql" == "y" ]; then
      alpi_mysql
    fi
    print_msg "configure apache"
    sudo sed -i.back 's/^LoadModule mpm_event_module modules\/mod_mpm_event\.so$/#&/' /etc/httpd/conf/httpd.conf
    sudo sed -i.back 's/^#LoadModule mpm_prefork_module modules\/mod_mpm_prefork\.so$/LoadModule mpm_prefork_module modules\/mod_mpm_prefork.so/' /etc/httpd/conf/httpd.conf
    sudo sed -i.back 's/^#LoadModule rewrite_module modules\/mod_rewrite\.so$/LoadModule rewrite_module modules\/mod_rewrite.so/' /etc/httpd/conf/httpd.conf

    print-msg "configure vhosts folder"
    sudo mkdir /etc/httpd/conf/vhosts
    sudo sed -i.back 's/^#Include conf\/extra\/httpd-vhosts\.conf$/&\nInclude conf\/vhosts\/*.conf/' /etc/httpd/conf/httpd.conf

    print_msg "Install Sites folder"
    mkdir /home/$USER/Sites
    sudo cp $_cwd/assets/vhosts/dev.conf /etc/httpd/conf/vhosts/
    cp $_cwd/assets/index.html /home/$USER/Sites/
    sudo cp $_cwd/assets/index.html /srv/http/
    sudo sed -i "s/USER/$USER/g" /etc/httpd/conf/vhosts/dev.conf
    sudo dev -i 's/# End of file/127.0.0.1 dev\n\n&/' /etc/hosts

    print_msg "configure apache for php"
    sudo sed -i.back 's/^LoadModule dir_module modules\/mod_dir\.so$/&\nLoadModule php7_module modules\/libphp7.so/' /etc/httpd/conf/httpd.conf
    sudo sh -c "echo 'Include conf/extra/php7_module.conf' >> /etc/httpd/conf/httpd.conf"

    print_msg "configure php"
    sudo sed -i.back 's/^memory_limit.*$/memory_limit = 512M/' /etc/php/php.ini
    sudo sed -i.back 's/^error_reporting.*$/error_reporting = E_ALL \& ~E_NOTICE/' /etc/php/php.ini
    sudo sed -i.back 's/;extension=gd\.so/extension=gd.so/' /etc/php/php.ini
    print_question "Should we configure custom basedir folder for php? [Y|n] "
    read bd
    sql=${bd:-y}
    if [ "$bd" == "y" ]; then
      print_question "Please enter the basedir path"
      read basedir
      sudo sed -i.back "s/^open_basedir = .*$/&:${basedir}/" /etc/php/php.ini
    fi

    print_msg "configure php for mysql"
    sudo sed -i.back 's/;extension=pdo_mysql\.so/extension=pdo_mysql.so/' /etc/php/php.ini

    print_msg "configure phpmyadmin"
    sudo sed -i.back 's/;extension=mysqli\.so/extension=mysqli.so/' /etc/php/php.ini
    sudo sed -i.back 's/;extension=mcrypt\.so/extension=mcrypt.so/' /etc/php/php.ini
    sudo sed -i.back 's/;extension=bz2\.so/extension=bz2.so/' /etc/php/php.ini
    sudo sed -i.back 's/;extension=zip\.so/extension=zip.so/' /etc/php/php.ini
    sudo sed -i.back 's/^open_basedir = .*$/&:\/etc\/webapps\//' /etc/php/php.ini

    # TODO : instal drush
  fi
}

alpi_bumblebee(){
  # https://wiki.archlinux.org/index.php/Bumblebee
  print_title "Bumblebee"
  print_question "Install Bumblebee? [Y|n] "
  read yn
  yn=${yn:-y}
  if [ "$yn" == "y" ]; then
    sudo pacman -S --needed --no-confirm bumblebee nvidia
    sudo gpasswd -a $USER bumblebee
    sudo systemctl enable bumblebeed
    sudo systemctl start bumblebeed
    sudo pacman -S --needed --no-confirm mesa-demos
    print_msg "run optirun glxgears -info to test your install"
    print_msg "Install primus bridge for better performances"
    sudo pacman -S --needed --no-confirm primus lib32-primus
    sudo sed -i.back 's/^Bridge=auto$/Bridge=primus/' /etc/bumblebee/bumblebee.conf
    print_msg "Install bbswitch to turn on and off discret card automatically (only for laptops)"
    sudo pacman -S --needed --no-confirm bbswitch
  fi
}

alpi_steam(){
  # https://wiki.archlinux.org/index.php/Steam
  print_title "Steam"
  print_question "Install steam? [Y|n] "
  read yn
  yn=${yn:-y}
  if [ "$yn" == "y" ]; then
    alpi_bumblebee
    alpi_multilib
    sudo pacman -S --needed --no-confirm lib32-virtualgl lib32-mesa-libgl lib32-nvidia-utils lib32-alsa-plugins ttf-liberation lib32-curl
    sudo pacman -S --needed --no-confirm steam
  fi
}


# END
alpi_end(){
  print_question "Reboot now? [Y|n] "
  read yn
  yn=${yn:-y}
  if [ "$yn" != "y" ]; then
    print_warning "depending on what you've done you may need to reboot"
    exit
  fi
  print_msg "Rebooting in 5sec"
  sleep 3
  reboot
}

alpi_menu(){
  while true
  do
    print_question "choose an action (preferably in proposed order)"
    echo
    action_list=("create user" "install basics" "cosmetics" "create gnupgp key" "secure the system" "install Xorg Server" "install Plasma 5 (kde)" "yaourt" "multilib" "cups (printers)" "switch to LTS kernel" "install default packages" "install lamp" "install bumblebee" "install steam" "end");
    select action in "${action_list[@]}"; do
      case "$REPLY" in
        1)
          alpi_user
          ;;
        2)
          alpi_basics
          ;;
        3)
          alpi_cosmetics
          ;;
        4)
          alpi_gnupg
          ;;
        5)
          alpi_secure
          ;;
        6)
          alpi_xserver
          ;;
        7)
          alpi_plasma5
          ;;
        8)
          alpi_yaourt
          ;;
        9)
          alpi_multilib
          ;;
        10)
          alpi_cups
          ;;
        11)
          alpi_kernellts
          ;;
        12)
          alpi_defaultpkgs
          ;;
        13)
          alpi_lamp
          ;;
        14)
          alpi_bumblebee
          ;;
        15)
          alpi_steam
          ;;
        16)
          alpi_end
          ;;
        *)
          print_warning "dommage, essaye encore"
          ;;
      esac
      [[ -n $OPT ]] && break
    done
  done
}

alpi_menu
