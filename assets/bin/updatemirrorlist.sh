#! /bin/bash

sudo rm /etc/pacman.d/mirrorlist.backup
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
sudo sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.pacnew
sudo sh -c "rankmirrors -n 30 /etc/pacman.d/mirrorlist.pacnew > /etc/pacman.d/mirrorlist"
