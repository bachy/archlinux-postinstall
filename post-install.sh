#! /bin/bash

echo 'Arch Linux Postinstall'

_cwd="$(pwd)"

alpi_user(){
  echo -n "Create your user? [Y|n]"
  read yn
  yn=${yn:-y}
  if [ "$yn" == "y" ]; then
    echo -n "Enter user name:"
    read username
    useradd -m -g users -G wheel -s /bin/bash ${username}
    chfn ${username}
    passwd ${username}
    echo "user $username created"
    echo "$username	ALL=(ALL) ALL" >> /etc/sudoers
    echo "$username added to sudoers"
    su ${username}
  fi
}

# misc
alpi_basics(){
  sudo pacman -S --needed --noconfirm vim rsync acpi parted imagemagick lynx alsa-utils tmux git
}

alpi_cosmetics(){
  # vim
  echo 'vim configuration'
  sudo pacman -S --needed --noconfirm vim-{spell-fr,spell-en,nerdtree,supertab,systemd}
  cp $_cwp/assets/vim /home/$USER/.vim
  cp $_cwd/assets/vimrc /home/$USER/.vimrc
  sudo cp $_cwd/assets/vim /root/.vim
  sudo cp $_cwd/assets/vimrc /root/.vimrc

  echo 'Git Completion'
  sudo pacman -S --needed --noconfirm bash-completion wget
  sudo mkdir /etc/bash_completion.d
  sudo wget -O /etc/bash_completion.d/git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash

  # bash & prompt
  echo 'Bash and Prompt'
  git clone https://github.com/hojhan/liquidprompt.git -o github /home/$USER/.liquidprompt
  cp $_cwd/assets/bash_profile /home/$USER/.bash_profile
  cp $_cwd/assets/bashrc /home/$USER/.bashrc
  mkdir /home/$USER/.config
  cp $_cwd/assets/config/liquipromptrc /home/$USER/.config/
  # sudo pacman -S --needed --noconfirm bash-completion
  source /home/$USER/.bashrc

  touch /home/$USER/.inputrc
  echo 'set show-all-if-ambiguous on' >> /home/$USER/.inputrc
  echo 'set completion-ignore-case on' >> /home/$USER/.inputrc

  echo 'ILoveCandy'
  sudo sed -i.back 's/.*\[options\].*/&\nILoveCandy/' /etc/pacman.conf
  sudo sed -i.back 's/^#Color$/Color/' /etc/pacman.conf
}

# GPG
alpi_gnupg(){
  echo 'Setup a gpg encripting'
  echo 'see https://wiki.archlinux.org/index.php/GnuPG'
  echo -n "create your gpg encrypting key? [Y|n] "
  read yn
  yn=${yn:-y}
  if [ "$yn" == "y" ]; then
    gpg --full-gen-key
  fi
}

alpi_secure(){
  # remove root autologin
  sudo sed -i.back 's/--autologin root //' /etc/systemd/system/getty@tty1.service.d/autologin.conf
  # remove root login
  sudo sed -i.back 's/#auth\srequired\spam_wheel.so\suse_uid/auth	required	spam_wheel.so use_uid/' /etc/pam.d/su
  sudo sed -i.back 's/#auth\srequired\spam_wheel.so\suse_uid/auth	required	spam_wheel.so use_uid/' /etc/pam.d/su-l

  # security
  sudo touch /etc/sysctl.d/50-dmesg-restrict.conf
  sudo sh -c "echo 'kernel.dmesg_restrict = 1' >> /etc/sysctl.d/50-dmesg-restrict.conf"
  sudo touch /etc/sysctl.d/50-kptr-restrict.con
  sudo sh -c "echo 'kernel.kptr_restrict = 1' >> /etc/sysctl.d/50-kptr-restrict.conf"
}


# Display Manager
alpi_xserver(){
  echo -n "install Graphical Display Part 1 : Xorg server (you will have to reboot at the end of part 1)? [Y|n] "
  read yn
  yn=${yn:-y}
  if [ "$yn" == "y" ]; then
    # touch pad
    sudo pacman -S --needed --noconfirm xf86-input-libinput
    # integred gpu
    sudo pacman -S --needed --noconfirm xf86-input-libinput xf86-video-intel
    # discret gpu
    sudo pacman -S --needed --noconfirm bbswitch bumblebee primus
    sudo pacman -S --needed --noconfirm nvidia nvidia-utils
    # xorg server
    sudo pacman -S --needed --noconfirm xorg-xinit xorg-server-devel
    sudo pacman -S --needed --noconfirm mesa mesa-demos
    sudo gpasswd -a $USER bumblebee
    sudo systemctl enable bumblebeed
    sudo reboot
  fi
}

alpi_plasma5(){
  echo -n "install Graphical Display Part 2 : Kde Plasma 5? [Y|n] "
  read yn
  yn=${yn:-y}
  if [ "$yn" == "y" ]; then
    sudo pacman -S --needed --noconfirm --force plasma-meta
    sudo pacman -S --needed --noconfirm ttf-{dejavu,liberation,droid,ubuntu-font-family}
    # network & Bluetooth
    sudo pacman -S --needed --noconfirm networkmanager-openvpn pulseaudio-alsa rfkill
    sudo systemctl enable NetworkManager
    sudo systemctl start NetworkManager
    sudo systemctl enable bluetooth
    sudo systemctl start bluetooth
    touch /home/$USER/.xinitrc
    echo 'exec startkde' > /home/$USER/.xinitrc
  fi
}

# Yaourt
alpi_yaourt(){
  echo -n "install Yaourt [Y|n] "
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
  fi
}


# kernel LTS
alpi_kernellts(){
  echo -n "Switch linux kernel to long term support version (more stable)? [Y|n] "
  read yn
  yn=${yn:-y}
  if [ "$yn" == "y" ]; then
    sudo pacman -S linux-lts linux-lts-headers nvidia-lts
    sudo grub-mkconfig -o /boot/grub/grub.cfg
  fi
}

alpi_mysql(){
    sudo pacman -S --needed --noconfirm mariadb
    # configure mysql
    sudo mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    mysql_secure_installation
    sudo sed -i.back 's/^log-bin=mysql-bin$/#&/' /etc/mysql/my.cnf
    sudo sed -i.back 's/^max_allowed_packet.*$/max_allowed_packet = 16M/' /etc/mysql/my.cnf
}

# Packages
alpi_defaultpkgs(){
  # TODO : install and configure mariadb before that
  echo "install basic packages? [Y|n]"
  read yn
  yn=${yn:-y}
  if [ "$yn" == "y" ]; then
    sudo pacman -S --needed --noconfirm systemd-kcm bluedevil
    sudo pacman -S --needed --noconfirm dolphin dolphin-plugins
    echo 'install pim softwares'
    sudo pacman -S --needed --noconfirm kmail korganizer kaddressbook kdeconnect pidgin
    sudo pacman -S --needed --noconfirm spamassassin razor
    sudo sa-update

    echo -n "Install regular mysql support for akonadi? [Y|n] "
    read ako
    ako=${ako:-y}
    if [ "$ako" == "y" ]; then

      echo -n "Should we install and configure mysql (if not already done)? [y|N] "
      read sql
      sql=${sql:-n}
      if [ "$sql" == "y" ]; then
        alpi_mysql
      fi

      # https://forum.kde.org/viewtopic.php?t=84478#p140762
      echo "please type your root mysql pass-word :"
      read -s -p Password: pswd
      mysql -u root -p$pswd -e "create database akonadi;"
      mysql -u root -p$pswd -e "create user 'akonadi'@'localhost' identified by 'akonadi';"
      mysql -u root -p$pswd -e "grant all privileges on akonadi.* to 'akonadi'@'localhost';"
      mysql -u root -p$pswd -e "flush privileges;"
      # TODO : BUG create first the .config/akonadi folder
      mv /home/$USER/.config/akonadi/akonadiserverrc /home/$USER/.config/akonadi/akonadiserverrc.back
      cp $_cwd/assets/akonadiserverrc /home/$USER/.config/akonadi/
    fi

    sudo pacman -S --needed --noconfirm chromium terminator gparted keepass
    echo 'install office softwares'
    sudo pacman -S --needed --noconfirm gwenview kimageformats kdegraphics-okular kipi-plugins libreoffice-fresh hunspell-{fr,en}
    echo 'install media softwares'
    sudo pacman -S --needed --noconfirm digikam darktable vlc lua-socket ktorrent banshee
    echo 'install graphic softwares'
    sudo pacman -S --needed --noconfirm inkscape gimp scribus fontforge blender
    #echo 'install some more fonts'
    #sudo pacman -S ttf-{,}
    echo 'install cloud softwares'
    sudo pacman -S --needed --noconfirm owncloud-client syncthing syncthing-gtk syncthing-inotify
    echo 'increase inotify watch limit'
    sleep 3
    sudo cp $_cwd/assets/90-inotify.conf /etc/sysctl.d/

    if [ "$yaourt" == "y" ]; then
      yaourt -S downgrade
      yaourt -S atom-editor
    fi
  fi
}

# LAMP
alpi_lamp(){
  # https://wiki.archlinux.org/index.php/Apache_HTTP_Server
  echo -n "Install apache php mysql? [Y|n] "
  read yn
  yn=${yn:-y}
  if [ "$yn" == "y" ]; then
    # install packages
    sudo pacman -S --needed --noconfirm apache php php-apache phpmyadmin php-mcrypt
    echo -n "Should we install and configure mysql (if not already done)? [y|N] "
    read sql
    sql=${sql:-n}
    if [ "$sql" == "y" ]; then
      alpi_mysql
    fi
    # configure apache
    sudo sed -i.back 's/^LoadModule mpm_event_module modules\/mod_mpm_event\.so$/#&/' /etc/httpd/conf/httpd.conf
    sudo sed -i.back 's/^#LoadModule mpm_prefork_module modules\/mod_mpm_prefork\.so$/LoadModule mpm_prefork_module modules\/mod_mpm_prefork.so/' /etc/httpd/conf/httpd.conf
    sudo sed -i.back 's/^#LoadModule rewrite_module modules\/mod_rewrite\.so$/LoadModule rewrite_module modules\/mod_rewrite.so/' /etc/httpd/conf/httpd.conf
    # configure vhosts folder
    sudo mkdir /etc/httpd/conf/vhosts
    sudo sed -i.back 's/^#Include conf\/extra\/httpd-vhosts\.conf$/&\nInclude conf\/vhosts\/*.conf/' /etc/httpd/conf/httpd.conf
    # configure apache for php
    sudo sed -i.back 's/^LoadModule dir_module modules\/mod_dir\.so$/&\nLoadModule php5_module modules\/libphp5.so/' /etc/httpd/conf/httpd.conf
    sudo sh -c "echo 'Include conf/extra/php5_module.conf' >> /etc/httpd/conf/httpd.conf"
    # configure php
    sudo sed -i.back 's/^memory_limit.*$/memory_limit = 512M/' /etc/php/php.ini
    sudo sed -i.back 's/^error_reporting.*$/error_reporting = E_ALL \& ~E_NOTICE/' /etc/php/php.ini
    sudo sed -i.back 's/;extension=gd\.so/extension=gd.so/' /etc/php/php.ini
    # configure php for mysql
    sudo sed -i.back 's/;extension=pdo_mysql\.so/extension=pdo_mysql.so/' /etc/php/php.ini

    # configure phpmyadmin
    sudo sed -i.back 's/;extension=mcrypt\.so/extension=mcrypt.so/' /etc/php/php.ini
    sudo sed -i.back 's/;extension=bz2\.so/extension=bz2.so/' /etc/php/php.ini
    sudo sed -i.back 's/;extension=zip\.so/extension=zip.so/' /etc/php/php.ini
    sudo sed -i.back 's/^open_basedir = .*$/&:\/etc\/webapps\//' /etc/php/php.ini

    echo -n "Should we configure custom basedir folder? [Y|n] "
    read bd
    sql=${bd:-y}
    if [ "$bd" == "y" ]; then
      echo -n "Please enter the basedir path"
      read basedir
      sudo sed -i.back "s/^open_basedir = .*$/&:${basedir}/" /etc/php/php.ini
    fi
    # TODO : instal drush
  fi
}

# END
alpi_end(){
  echo -n "Reboot? [Y|n] "
  read yn
  yn=${yn:-y}
  if [ "$yn" != "y" ]; then
    echo "depending on what you've done you may need to reboot"
    exit
  fi

  reboot
}


while true
do
  echo -e "choosse action (preferably in order)\n"
  action_list=("create user" "install basics" "cosmetics" "create gnupgp key" "secure the system" "install Xorg Server" "install Plasma 5 (kde)" "yaourt" "switch to LTS kernel" "install default packages" "install lamp" "end");
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
        alpi_kernellts
        ;;
      10)
        alpi_defaultpkgs
        ;;
      11)
        alpi_lamp
        ;;
      12)
        alpi_end
        ;;
    esac
    [[ -n $OPT ]] && break
  done
done
