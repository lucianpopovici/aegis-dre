#!/bin/bash

# Usage: ./check_ddp.sh <pci_address> (e.g., 0000:01:00.0)
PCI_ADDR=$1

if [ -z "$PCI_ADDR" ]; then
    echo "Usage: $0 <pci_address>"
    echo "Example: $0 0000:01:00.0"
    exit 1
fi

echo "--- Checking DDP Profile for $PCI_ADDR ---"

# 1. Check via Devlink (The modern standard)
if command -v devlink &> /dev/null; then
    echo "[1/2] Searching via devlink resource..."
    # Looks for 'sctp' or other loaded profiles in the resource list
    DDP_STATUS=$(devlink resource show pci/$PCI_ADDR 2>/dev/null | grep -i "ddp")
    
    if [ -n "$DDP_STATUS" ]; then
        echo "Found DDP Resource: $DDP_STATUS"
    else
        echo "No DDP profile explicitly listed in devlink resources."
    fi
else
    echo "devlink command not found. Skipping."
fi

# 2. Check via Ethtool (Driver-level info)
echo -e "\n[2/2] Checking ethtool private flags..."
ETHTOOL_OUT=$(ethtool --show-priv-flags $(lspci -s $PCI_ADDR | awk '{print $1}') 2>/dev/null)

if echo "$ETHTOOL_OUT" | grep -q "disable-rss"; then
    echo "Note: RSS is configurable, indicating DDP-aware firmware is present."
fi

# 3. Check i40e DebugFS (The most reliable for X710)
# This requires root and for the i40e debugfs to be mounted
if [ -d "/sys/kernel/debug/i40e" ]; then
    echo -e "\n[Bonus] Checking i40e debugfs for loaded profiles..."
    # Find the folder corresponding to the PCI address
    DEBUG_DIR=$(find /sys/kernel/debug/i40e/ -name "$PCI_ADDR" -type d)
    if [ -n "$DEBUG_DIR" ] && [ -f "$DEBUG_DIR/ddp_loaded" ]; then
        cat "$DEBUG_DIR/ddp_loaded"
    else
        echo "DebugFS entry for DDP not found. Ensure i40e debugfs is enabled."
    fi
fi

echo -e "\n--- End of Check ---"
