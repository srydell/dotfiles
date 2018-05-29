#!/usr/bin/env bash

# Determine the interface
nmcli d

# Make sure the wifi radio is on (this is the default)
nmcli r wifi on

# Check available wifi connections
nmcli d wifi list

# nmcli d wifi connect $wifi password $password
