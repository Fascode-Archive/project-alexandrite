#! /usr/bin/env bash

#    Alexandrite OS
#    Copyright (C) 2021 naiad technology
#
#
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.



# Functions...
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

# Greeting...
echo "Configure image: [${kiwi_iname}]..."

# Setup baseproduct link
suseSetupProduct

# Activate services
suseInsertService sshd

# Setup default target, multi-user
baseSetRunlevel 3

# Remove yast if not in use
#suseRemoveYaST

# enable services
ln -fs /usr/lib/systemd/system/NetworkManager.service /etc/systemd/system/network.service
systemctl enable NetworkManager

ln -fs /usr/lib/systemd/system/graphical.target /etc/systemd/system/default.target

# set nopassword login for live user
groupadd nopasswdlogin
usermod -aG nopasswdlogin live

# fix sudoers file permission
chmod 440 /etc/sudoers

# setting audit group
groupadd -r audit
usermod -aG audit live

# mask systemd-udev-settle
systemctl mask systemd-udev-settle

# GRUB setting
#sed -i -e 's/GRUB_TERMINAL="console"/GRUB_TERMINAL="gfxterm"/g' /etc/default/grub
#grub2-mkconfig -o /boot/grub2/grub.cfg

# update dconf
dconf update
