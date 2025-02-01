#!/bin/bash

# Function to output messages with indentation
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Warning before starting
log "\e[WARNING\e[0m: This script will clean the system and prepare it for use as a template."
log "After running the script, the system will need additional configuration to return to normal."
read -p "Are you sure you want to continue? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    log "Operation cancelled by user."
    exit 1
fi

log "We begin preparing the system for the template..."

# --- Step 1: Cleaning the system ---
log "Step 1: Clear temporary files and logs..."
sudo rm -rf /tmp/* /var/tmp/*
sudo truncate -s 0 /var/log/*.log /var/log/syslog /var/log/auth.log
sudo apt clean
sudo apt autoclean
sudo apt autoremove --purge -y
log "Step 1 complete."

# --- Step 2: Reset Unique Identifiers ---
log "Step 2: Reset filesystem UUIDs..."
for partition in $(lsblk -ln -o NAME | grep -E "^sd"); do
    sudo tune2fs -U random /dev/$partition 2>/dev/null || true
done
log "Filesystem UUIDs reset."

# --- Step 3: Resetting MAC addresses of network interfaces ---
log "Step 3: Resetting MAC addresses of network interfaces..."
sudo rm -f /etc/udev/rules.d/70-persistent-net.rules
log "MAC addresses reset."

# --- Step 4: Setting up hostname and network ---
log "Step 4: Resetting hostname..."
sudo hostnamectl set-hostname localhost
echo "127.0.0.1   localhost" | sudo tee /etc/hosts > /dev/null
echo "::1         localhost ip6-localhost ip6-loopback" | sudo tee -a /etc/hosts > /dev/null
log "Hostname and hosts file updated."

# --- Step 5: Removing SSH keys ---
log "Step 5: Removing SSH keys..."
sudo rm -f /etc/ssh/ssh_host_*
log "SSH keys removed."

# --- Step 6: Disabling services and startup ---
log "Step 6: Disabling services..."
sudo systemctl disable --now systemd-resolved 2>/dev/null || true
sudo systemctl disable --now NetworkManager 2>/dev/null || true
log "Services disabled."

# --- Step 7: Clearing command history ---
log "Step 7: Clearing command history..."
history -c
sudo history -c
sudo rm -f ~/.bash_history /root/.bash_history
log "Command history cleared."

# --- Step 8: Defragment disk (optional) ---
#log "Step 8: Defragment disk..."
#sudo dd if=/dev/zero of=/zero.fill bs=1M 2>/dev/null || true
#sudo rm -f /zero.fill
#log "Defragmentation completed."

# --- Completing ---
log "Preparing the system for the template is complete."
log "You can now shut down the system and convert it to a template in Proxmox."