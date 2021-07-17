#! /usr/bin/env bash

#
# (c)2021 naiad technology
# calamares.sh
#

# congif grub
sed -i -e 's/GRUB_TERMINAL="console"/GRUB_TERMINAL="gfxterm"/g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
