#!/bin/bash
#================
# FILE          : config.sh
#----------------
# PROJECT       : alexandrite linux project
# COPYRIGHT     : (c) 2021 naiad technology
#               :
# AUTHOR        : nexryai
#               :
# BELONGS TO    : Operating System images
#               :
# DESCRIPTION   : configuration script for SUSE based
#               : operating systems
#----------------
#======================================
# Functions...
#--------------------------------------
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [$kiwi_iname]..."

#======================================
# Setup baseproduct link
#--------------------------------------
suseSetupProduct

#======================================
# Activate services
#--------------------------------------
suseInsertService sshd

#======================================
# Setup default target, multi-user
#--------------------------------------
baseSetRunlevel 3

#======================================
# Remove yast if not in use
#--------------------------------------
#suseRemoveYaST
