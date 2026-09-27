#!/bin/bash
# Debian bullseye is no longer supported by Debian (LTS ended in August 2026).
# On bullseye based images only (jeedom/jeedom:*-bullseye):
#   - disable bullseye-security: its index still lists packages which have been
#     removed from the pool (404), breaking apt-get upgrade/install
#   - add Freexian Extended LTS (ELTS) repository for security updates
#     (can be disabled with DEBIAN_ELTS=false)
#   - move Debian repositories removed from the mirrors to archive.debian.org
#     (or disable them) so that apt-get update does not break the build.
# Does nothing on any other Debian release.

. /etc/os-release

if [ "$VERSION_CODENAME" != "bullseye" ]; then
    echo "Debian $VERSION_CODENAME: nothing to do."
    exit 0
fi

SOURCES_FILES="/etc/apt/sources.list $(ls /etc/apt/sources.list.d/*.list 2>/dev/null)"

echo "Debian bullseye: disabling bullseye-security repository..."
for SOURCES in $SOURCES_FILES; do
    [ -f "$SOURCES" ] && sed -i -E 's/^(deb(-src)? .*\.debian\.org\/.* bullseye-security .*)$/# \1/' "$SOURCES"
done

if [ "$DEBIAN_ELTS" = "false" ]; then
    echo "Debian bullseye: ELTS disabled, no more security updates."
else
    echo "Debian bullseye: enabling Freexian Extended LTS repository..."
    # Checksum published on https://www.freexian.com/lts/extended/docs/how-to-use-extended-lts/
    ELTS_KEY_SHA256="a0b22152fdf1942f49cc1559ec4598bae8d8954da9ed38662d15b97a60909db8"
    ELTS_KEY=/etc/apt/trusted.gpg.d/freexian-archive-extended-lts.gpg
    curl -fsSL https://deb.freexian.com/extended-lts/archive-key.gpg -o "$ELTS_KEY" || exit 1
    if ! echo "$ELTS_KEY_SHA256  $ELTS_KEY" | sha256sum -c -; then
        echo "Error: unexpected Freexian ELTS key checksum."
        rm -f "$ELTS_KEY"
        exit 1
    fi
    echo "deb https://deb.freexian.com/extended-lts bullseye main contrib non-free" \
        > /etc/apt/sources.list.d/extended-lts.list
fi

# Debian repositories which have been removed from the mirrors (HTTP 404):
# use archive.debian.org when available, otherwise disable them.
# Network errors are ignored so that a temporary failure never changes sources.
for SOURCES in $SOURCES_FILES; do
    [ -f "$SOURCES" ] || continue
    grep -E '^deb(-src)? ' "$SOURCES" | grep -F '.debian.org/' | while read -r LINE; do
        FIELDS=$(echo "$LINE" | sed -E 's/^deb(-src)? (\[[^]]*\] )?//')
        URI=$(echo "$FIELDS" | awk '{print $1}')
        SUITE=$(echo "$FIELDS" | awk '{print $2}')
        [ "$(curl -s -o /dev/null -w '%{http_code}' "$URI/dists/$SUITE/Release")" = "404" ] || continue

        ARCHIVE_URI=$(echo "$URI" | sed -E 's#^https?://[^/]+/#http://archive.debian.org/#')
        if [ "$(curl -s -o /dev/null -w '%{http_code}' "$ARCHIVE_URI/dists/$SUITE/Release")" = "200" ]; then
            echo "$SUITE: $URI -> $ARCHIVE_URI"
            NEW_LINE=${LINE/$URI/$ARCHIVE_URI}
        else
            echo "$SUITE: $URI no longer available, disabled"
            NEW_LINE="# $LINE"
        fi
        OLD=$(printf '%s' "$LINE" | sed -e 's/[]\/$*.^|[]/\\&/g')
        NEW=$(printf '%s' "$NEW_LINE" | sed -e 's/[\/&|]/\\&/g')
        sed -i "s|^$OLD\$|$NEW|" "$SOURCES"
    done
done

# Release files on archive.debian.org are expired
if grep -qs 'archive.debian.org' $SOURCES_FILES; then
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99archive-debian
fi
