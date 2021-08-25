#! /usr/bin/env bash

#
# (c)2021 naiad technology
# calamares.sh
#

# config grub
sed -i -e 's/GRUB_TERMINAL="console"/GRUB_TERMINAL="gfxterm"/g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# install packages
zypper refresh
zypper -n in gstreamer-plugins-good gstreamer-plugins-libav gstreamer-plugins-bad gstreamer-plugins-bad-orig-addon libavcodec56 libavcodec57 libavformat56 libavformat57 libavdevice56 libavdevice57
zypper -n up --allow-vendor-change 

# enable trusted boot
tpm=`ls /sys/class/tpm/`

if [ -n "$tpm" ]; then
  zypper -n in trustedgrub2 trustedgrub2-i386-pc
fi
