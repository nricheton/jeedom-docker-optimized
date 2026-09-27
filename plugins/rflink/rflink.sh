#!/bin/bash
set -e

echo "Running additional setup for RFLink..."
apt-get install --no-install-recommends -y nodejs avrdude

# Idempotent serialport fix, run at startup (setup.sh) and every 15 minutes
# since plugin updates from the market overwrite the patched files
install -m 755 rflink_fix.sh /usr/local/bin/rflink_fix.sh
echo "*/15 * * * * root /usr/local/bin/rflink_fix.sh" > /etc/cron.d/rflink_fix
chmod 644 /etc/cron.d/rflink_fix
