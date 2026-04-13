#!/bin/bash

# ==============================================================================
# EDURoam Configuration Script for Ubuntu (NetworkManager / nmcli)
# University of Cambridge Settings
# ==============================================================================

# --- EDIT THESE TWO VARIABLES ---
USERNAME=""      # e.g., abc123+laptop@cam.ac.uk
PASSWORD=""        # Your 16-character token, NOT your Uni password
# --------------------------------

# Cambridge-specific technical settings (Do not change unless advised by IT)
ANON_IDENTITY="_token-public@cam.ac.uk"
DOMAIN_SUFFIX="token-public.wireless.cam.ac.uk"
CA_CERT_PATH="/etc/ssl/certs/DigiCert_Global_Root_G2.pem"
CONNECTION_NAME="eduroam"

echo "Checking system requirements..."

# 1. Verify nmcli is available
if ! command -v nmcli &> /dev/null; then
    echo "Error: 'nmcli' could not be found. Please ensure NetworkManager is installed."
    exit 1
fi

# 2. Verify the root certificate exists
if [ ! -f "$CA_CERT_PATH" ]; then
    echo "Error: The required root certificate was not found at $CA_CERT_PATH."
    echo "You may need to run: sudo apt update && sudo apt install ca-certificates"
    exit 1
fi

echo "Certificate found. Proceeding with configuration..."

# 3. Clean up any existing 'eduroam' profiles to prevent conflicts
if nmcli connection show | grep -q "^$CONNECTION_NAME\s"; then
    echo "Removing existing '$CONNECTION_NAME' network profile..."
    nmcli connection delete "$CONNECTION_NAME" >/dev/null
fi

# 4. Create the new NetworkManager profile
echo "Building new '$CONNECTION_NAME' network profile..."

nmcli connection add \
  type wifi \
  con-name "$CONNECTION_NAME" \
  ssid "$CONNECTION_NAME" \
  wifi-sec.key-mgmt wpa-eap \
  802-1x.eap peap \
  802-1x.phase2-auth mschapv2 \
  802-1x.anonymous-identity "$ANON_IDENTITY" \
  802-1x.identity "$USERNAME" \
  802-1x.password "$PASSWORD" \
  802-1x.ca-cert "$CA_CERT_PATH" \
  802-1x.domain-suffix-match "$DOMAIN_SUFFIX"

if [ $? -ne 0 ]; then
    echo "Error: Failed to create the network profile."
    exit 1
fi

# 5. Attempt to bring the connection up
echo "Profile created successfully. Attempting to connect to '$CONNECTION_NAME'..."
nmcli connection up "$CONNECTION_NAME"

echo "Done."
