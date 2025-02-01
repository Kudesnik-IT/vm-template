#!/bin/bash

# Function to output messages with indentation
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Warning before starting
log "WARNING: This script will clean the system and prepare it for use as a template."
log "After running the script, the system will need additional configuration to return to normal."
read -p "Are you sure you want to continue? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    log "Operation cancelled by user."
    exit 1
fi

log "We begin preparing the system for the template..."

# --- Step 1: Cleaning the system ---
log "Step 1: Clear temporary files and logs..."
rm -rf /tmp/* /var/tmp/*
truncate -s 0 /var/log/*.log /var/log/syslog /var/log/auth.log
apt clean
apt autoclean
apt autoremove --purge -y
log "Step 1 complete."

# --- Step 2: Resetting MAC addresses of network interfaces ---
log "Step 2: Resetting MAC addresses of network interfaces..."
rm -f /etc/udev/rules.d/70-persistent-net.rules
log "MAC addresses reset."

# --- Step 3: Setting up hostname and network ---
log "Step 3: Resetting hostname..."
hostnamectl set-hostname localhost
echo "127.0.0.1   localhost" | tee /etc/hosts > /dev/null
echo "::1         localhost ip6-localhost ip6-loopback" | tee -a /etc/hosts > /dev/null
log "Hostname and hosts file updated."

# --- Step 4: Removing SSH keys ---
log "Step 4: Removing SSH keys..."
rm -f /etc/ssh/ssh_host_*
log "SSH keys removed."

# --- Step 5: Disabling services and startup ---
log "Step 5: Disabling services..."
systemctl disable --now systemd-resolved 2>/dev/null || true
systemctl disable --now NetworkManager 2>/dev/null || true
log "Services disabled."

# --- Step 6: Clearing command history ---
log "Step 6: Clearing command history..."
history -c
history -c
rm -f ~/.bash_history /root/.bash_history
log "Command history cleared."

# --- Step 7: Defragment disk (optional) ---
#log "Step 7: Defragment disk..."
#dd if=/dev/zero of=/zero.fill bs=1M 2>/dev/null || true
#rm -f /zero.fill
#log "Defragmentation completed."

# --- Completing ---
log "Preparing the system for the template is complete."
log "You can now shut down the system and convert it to a template in Proxmox."