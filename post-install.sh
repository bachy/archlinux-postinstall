#! /
bin/sh

echo 'Arch Linux Postinstall'

echo -n "Should we start? [Y|n] "
read yn
yn=${yn:-y}
if [ "$yn" != "y" ]; then
  echo "aborting script!"
  exit
fi

_cwd="$(pwd)"

echo -n "Create your user? [Y|n]"
read yn
yn=${yn:-y}
if [ "$yn" == "y" ]; then
	echo -n "Enter user name:"
	read user
	useradd -m -g users "$user"
	passwd "$user"
	echo "user $user created"
	echo "$user	ALL=(ALL) ALL" >> /etc/sudoers
	echo "$user added to sudoers"
	su "$user"
fi

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

echo 'ILoveCandy'
sudo sed -i.back 's/.*\[options\].*/&\nILoveCandy/' /etc/pacman.conf

# bash & prompt
echo 'Bash and Prompt'
git clone https://github.com/hojhan/liquidprompt.git -o github /home/$USER/.liquidprompt
cp $_cwd/assets/bash_profile /home/$USER/.bash_profile
cp $_cwd/assets/bashrc /home/$USER/.bashrc
mkdir /home/$USER/.config
cp $_cwd/assets/liquiprompt /home/$USER/.config/
# sudo pacman -S --needed --noconfirm bash-completion
source /home/$USER/.bashrc

touch /home/$USER/.inputrc
echo 'set show-all-if-ambiguous on' >> /home/$USER/.inputrc
echo 'set completion-ignore-case on' >> /home/$USER/.inputrc


# vim
echo 'vim configuration'
sleep 3
cp $_cwp/assets/vim /home/$USER/.vim
cp $_cwd/assets/vimrc /home/$USER/.vimrc
sudo cp $_cwd/assets/vim /root/.vim
sudo cp $_cwd/assets/vimrc /root/.vimrc

echo 'Git Completion'
sleep 3
sudo pacman -S --needed --noconfirm bash-completion wget
sudo mkdir /etc/bash_completion.d
sudo wget -O /etc/bash_completion.d/git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash


# Yaourt
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

# network & Bluetooth
sudo pacman -S --needed --noconfirm networkmanager networkmanager-openvpn rfkill
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

# misc
sudo pacman -S --needed --noconfirm rsync acpi parted imagemagick

# Display Manager
echo -n "install Graphical Display Part 1 : Xorg server (you will have to reboot at the end of part 1)? [Y|n] "
read yn
yn=${yn:-y}
if [ "$yn" == "y" ]; then
  sudo pacman -S --needed --noconfirm bumblebee
  sudo pacman -S --needed --noconfirm mesa
  sudo pacman -S --needed --noconfirm xf86-video-intel
  sudo pacman -S --needed --noconfirm nvidia
  sudo pacman -S --needed --noconfirm xorg-xinit
  sudo gpasswd -a $USER bumblebee
  sudo systemctl enable bumblebeed
  sudo reboot
fi

echo -n "install Graphical Display Part 2 : Kde Plasma 5? [Y|n] "
read yn
yn=${yn:-y}
if [ "$yn" == "y" ]; then
  sudo pacman -S --needed --noconfirm --force plasma-meta
  sudo pacman -S --needed --noconfirm ttf-dejavu ttf-liberationi ttf-droid
fi

echo "install basic packages? [Y|n]"
read yn
yn=${yn:-y}
if [ "$yn" == "y" ]; then
  sudo pacman -S --needed --noconfirm systemd-kcm bluedevil
  sudo pacman -S --needed --noconfirm dolphin dolphin-plugins
  sudo pacman -S --needed --noconfirm kmail korganizer kdeconnect pidgin
  sudo pacman -S --needed --noconfirm chromium terminator gparted
  sudo pacman -S --needed --noconfirm digikam
  if [ "$yaourt" == "y" ]; then
    yaourt -S atom-editor
  fi
fi

# cloud
sudo pacman -S --needed --noconfirm owncloud-client syncthings
echo 'increase inotify watch limit'
sleep 3
sudo cp $_cwd/assets/90-inotify.conf /etc/sysctl.d/

# LAMP
# https://wiki.archlinux.org/index.php/Apache_HTTP_Server
echo -n "Install apache php mysql? [Y|n] "
read yn
yn=${yn:-y}
if [ "$yn" == "y" ]; then
  # install packages
  sudo pacman -S --needed --noconfirm apache php php-apache mariadb phpmyadmin php-mcrypt
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
  # configure mysql
  sudo mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
  mysql_secure_installation
  sudo sed -i.back 's/^log-bin=mysql-bin$/#&/' /etc/mysql/my.cnf
  sudo sed -i.back 's/^max_allowed_packet.*$/max_allowed_packet = 16M/' /etc/mysql/my.cnf
  # configure phpmyadmin
  sudo sed -i.back 's/;extension=mcrypt\.so/extension=mcrypt.so/' /etc/php/php.ini
  sudo sed -i.back 's/;extension=bz2\.so/extension=bz2.so/' /etc/php/php.ini
  sudo sed -i.back 's/;extension=zip\.so/extension=zip.so/' /etc/php/php.ini
  sudo sed -i.back 's/^open_basedir = .*$/&:\/etc\/webapps\//' /etc/php/php.ini
  # todo : add custom basedir
  # todo : instal drush
fi


# GPG
echo 'Setup a gpg encripting'
echo 'see https://wiki.archlinux.org/index.php/GnuPG'
echo -n "create your gpg encrypting key? [Y|n] "
read yn
yn=${yn:-y}
if [ "$yn" == "y" ]; then
  gpg --full-gen-key
fi

# END
echo -n "Reboot? [Y|n] "
read yn
yn=${yn:-y}
if [ "$yn" != "y" ]; then
  echo "please reboot"
  exit
fi

reboot
