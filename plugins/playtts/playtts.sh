#!/bin/bash
set -e

echo "Running additional setup for PlayTTS..."

# Pico TTS (libttspico-utils) is in the non-free component on recent Debian
# releases, which is not enabled in the base image: enable it if needed.
if [ -z "$(apt-cache policy libttspico-utils 2>/dev/null | grep 'Candidate:' | grep -v '(none)')" ]; then
    echo "Enabling Debian non-free component for Pico TTS..."
    # deb822 format (bookworm and later)
    for SOURCES in /etc/apt/sources.list.d/*.sources; do
        if [ -f "$SOURCES" ]; then sed -i -E '/^URIs: .*debian\.org\/debian\/?$/,/^Components:/ { /non-free( |$)/! s/^(Components: .*)$/\1 non-free/ }' "$SOURCES"; fi
    done
    # One-line format
    for SOURCES in /etc/apt/sources.list /etc/apt/sources.list.d/*.list; do
        if [ -f "$SOURCES" ]; then sed -i -E '/non-free( |$)/! s#^(deb .*debian\.org/debian/? [a-z-]+ .*main.*)$#\1 non-free#' "$SOURCES"; fi
    done
    apt-get update
fi

apt-get install --no-install-recommends -y libsox-fmt-mp3 sox libttspico-utils mplayer mpg123 lsb-release software-properties-common
cd /tmp
git clone https://github.com/lunarok/jeedom_playtts.git
cd jeedom_playtts && git checkout master && cd resources
sed -i 's/sudo usermod -a -G audio `whoami`/sudo usermod -a -G audio www-data/' ./install.sh
chmod u+x ./install.sh
./install.sh
