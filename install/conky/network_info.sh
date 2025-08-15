#!/bin/bash

# Get the active network interface
INTERFACE=$(ip route | awk '/default/ {print $5}')

# Get the IP address
IP_ADDRESS=$(ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# Display the information
echo "IP: $IP_ADDRESS"
