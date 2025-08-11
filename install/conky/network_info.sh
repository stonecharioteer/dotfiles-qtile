#!/bin/bash

# Get the active network interface
INTERFACE=$(ip route | awk '/default/ {print $5}')

# Get the IP address
IP_ADDRESS=$(ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# Run speedtest and save output to a file
speedtest-cli --simple > /tmp/speedtest.log

# Get download and upload speeds from the file
DOWNLOAD=$(cat /tmp/speedtest.log | awk '/Download/ {print $2, $3}')
UPLOAD=$(cat /tmp/speedtest.log | awk '/Upload/ {print $2, $3}')

# Display the information
echo "IP: $IP_ADDRESS"
echo "Download: $DOWNLOAD"
echo "Upload: $UPLOAD"
