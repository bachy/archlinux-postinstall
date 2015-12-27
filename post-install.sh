#! /bin/sh


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

# vim
echo 'vim configuration'
sleep 3
cp $_cwp/assets/vim /home/$USER/.vim
cp $_cwd/assets/vimrc /home/$USER/.vimrc
sudo cp $_cwd/assets/vim /root/.vim
sudo cp $_cwd/assets/vimrc /root/.vimrc

echo 'Misc'
sleep 3
touch /home/$USER/.inputrc
echo 'set show-all-if-ambiguous on' >> /home/$USER/.inputrc
echo 'set completion-ignore-case on' >> /home/$USER/.inputrc

echo 'Git Completion'
sleep 3
sudo pacman -S --needed --noconfirm bash-completion wget
sudo mkdir /etc/bash_completion.d
sudo wget -O /etc/bash_completion.d/git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash

echo 'increase inotify watch limit'
sleep 3
sudo cp $_cwd/assets/90-inotify.conf /etc/sysctl.d/

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

# Display Manager
echo -n "install Graphical Display Part 1 : Xorg server? [Y|n] "
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
  sudo pacman -S --needed --noconfirm ttf-dejavu ttf-liberationi
  sudo systemctl enable NetworkManager
  sudo systemctl start NetworkManager
fi

echo "install basic packages? [Y|n]"
read yn
yn=${yn:-y}
if [ "$yn" == "y" ]; then
  sudo pacman -S --needed --noconfirm systemd-kcm bluedevil rfkill
  sudo pacman -S --needed --noconfirm dolphin dolphin-plugins
  sudo pacman -S --needed --noconfirm kmail korganizer kdeconnect
  sudo pacman -S --needed --noconfirm chromium terminator
  if [ "$yaourt" == "y" ]; then
    yaourt -S atom-editor
  fi
fi

echo 'Setup a gpg encripting'
echo 'see https://wiki.archlinux.org/index.php/GnuPG'
echo -n "create your gpg encrypting key? [Y|n] "
read yn
yn=${yn:-y}
if [ "$yn" == "y" ]; then
  gpg --full-gen-key
fi
















echo -n "Reboot? [Y|n] "
read yn
yn=${yn:-y}
if [ "$yn" != "y" ]; then
  echo "please reboot"
  exit
fi

reboot
