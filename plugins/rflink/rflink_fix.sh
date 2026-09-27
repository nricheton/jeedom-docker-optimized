#!/bin/bash
# Idempotent fix for the RFLink plugin with serialport >= 10 on recent node.
#
# The plugin files live in the /var/www/html volume and are overwritten by
# every plugin update from the Jeedom market, so this runs at container start
# (setup.sh, with --no-restart) and periodically from cron.
# Does nothing, and logs nothing, when everything is already fine.
#
# Usage: rflink_fix.sh [--no-restart]

RESOURCES=/var/www/html/plugins/rflink/resources
RFLINK_JS="$RESOURCES/rflink.js"
RFLINK_PKG="$RESOURCES/package.json"
LOG=/var/www/html/log/rflink_autofix
SERIALPORT_VERSION="13.0.0"

RESTART=true
[ "$1" = "--no-restart" ] && RESTART=false

# Plugin not installed
[ -f "$RFLINK_JS" ] && [ -f "$RFLINK_PKG" ] || exit 0
cd "$RESOURCES" || exit 0

log() {
	echo "$(date -Iseconds) $*" >> "$LOG"
	chown www-data:www-data "$LOG" 2>/dev/null
}

as_www_data() {
	runuser -u www-data -- env HOME=/var/www npm_config_cache=/var/www/.npm "$@"
}

# serialport < 10 API still used by rflink.js
OLD_API_PATTERN='SerialPort\.parsers|new parsers\.Readline|new SerialPort\(gwAddress'

# Declared serialport version (without ^/~), empty if not declared
declared_serialport() {
	node -p "(require('./package.json').dependencies || {}).serialport || ''" 2>/dev/null | sed -E 's/^[^0-9]*//'
}

# Declared version is older than SERIALPORT_VERSION, or 13.0.5 which does not
# exist (was set by an earlier version of this image). Never downgrade.
pkg_needs_fix() {
	local declared
	declared=$(declared_serialport)
	[ -z "$declared" ] && return 1
	[ "$declared" = "13.0.5" ] && return 0
	[ "$declared" = "$SERIALPORT_VERSION" ] && return 1
	[ "$(printf '%s\n' "$SERIALPORT_VERSION" "$declared" | sort -V | head -n1)" = "$declared" ]
}

# @serialport/bindings-cpp pinned at the top level: serialport pulls the
# matching version itself (earlier versions of this image added 12.0.0)
pkg_has_bindings_pin() {
	[ -n "$(node -p "(require('./package.json').dependencies || {})['@serialport/bindings-cpp'] || ''" 2>/dev/null)" ]
}

# serialport installed with the declared version and its native binding loads
# (requiring serialport loads the binding; SerialPort.list() would need udevadm)
deps_ok() {
	local installed
	installed=$(node -p "require('./node_modules/serialport/package.json').version" 2>/dev/null)
	[ -n "$installed" ] && [ "$installed" = "$(declared_serialport)" ] || return 1
	as_www_data node -e "require('serialport')" >/dev/null 2>&1
}

JS_NEEDS_FIX=false
grep -qE "$OLD_API_PATTERN" "$RFLINK_JS" && JS_NEEDS_FIX=true
PKG_NEEDS_FIX=false
pkg_needs_fix && PKG_NEEDS_FIX=true
pkg_has_bindings_pin && PKG_NEEDS_FIX=true

if [ "$JS_NEEDS_FIX" = false ] && [ "$PKG_NEEDS_FIX" = false ] && deps_ok; then
	exit 0
fi

log "RFLink: incompatibility detected (rflink.js=$JS_NEEDS_FIX package.json=$PKG_NEEDS_FIX), fixing"

if [ "$PKG_NEEDS_FIX" = true ]; then
	if pkg_needs_fix; then
		as_www_data npm pkg set "dependencies.serialport=$SERIALPORT_VERSION" >> "$LOG" 2>&1
		log "RFLink: package.json serialport set to $SERIALPORT_VERSION"
	fi
	if pkg_has_bindings_pin; then
		as_www_data npm pkg delete "dependencies.@serialport/bindings-cpp" >> "$LOG" 2>&1
		log "RFLink: package.json @serialport/bindings-cpp pin removed"
	fi
fi

if [ "$JS_NEEDS_FIX" = true ]; then
	sed -i -E \
		-e "s/const SerialPort = require\(['\"]serialport['\"]\);?/const { SerialPort, ReadlineParser } = require('serialport');/" \
		-e "/const parsers = SerialPort\.parsers;?/d" \
		-e "s/new parsers\.Readline\(/new ReadlineParser(/" \
		-e "s/new SerialPort\(gwAddress, *\{/new SerialPort({ path: gwAddress,/" \
		"$RFLINK_JS"
	chown www-data:www-data "$RFLINK_JS"
	if grep -qE "$OLD_API_PATTERN" "$RFLINK_JS"; then
		log "RFLink: rflink.js still uses the old serialport API after patching, unknown plugin version"
	else
		log "RFLink: rflink.js patched for the serialport >= 10 API"
	fi
fi

# Working dependencies only need a sync with the new package.json (drops the
# extraneous top-level bindings-cpp); broken ones are reinstalled from scratch.
# The daemon is restarted only in the latter case or if rflink.js changed.
NEEDS_RESTART=$JS_NEEDS_FIX
DEPS_WERE_OK=false
deps_ok && DEPS_WERE_OK=true
if [ "$DEPS_WERE_OK" = false ] || [ "$PKG_NEEDS_FIX" = true ]; then
	log "RFLink: installing node dependencies"
	# /var/www may be root-owned and root/sudo npm runs leave root-owned files
	# in the cache, which makes npm fail with EACCES as www-data
	mkdir -p /var/www/.npm
	chown -R www-data:www-data /var/www/.npm "$RESOURCES"
	if [ "$DEPS_WERE_OK" = false ]; then
		rm -rf node_modules package-lock.json
		NEEDS_RESTART=true
	fi
	as_www_data npm install --omit=dev --no-fund --no-audit >> "$LOG" 2>&1
	if deps_ok; then
		log "RFLink: node dependencies installed"
	else
		log "RFLink: node dependencies install FAILED"
		exit 1
	fi
fi

[ "$RESTART" = true ] && [ "$NEEDS_RESTART" = true ] || exit 0

# Restart the daemon through Jeedom, only if it is running or in auto mode
runuser -u www-data -- php -r "
require_once '/var/www/html/core/php/core.inc.php';
\$plugin = plugin::byId('rflink');
\$info = \$plugin->deamon_info();
if (\$info['state'] == 'ok' || \$info['auto'] == 1) {
	\$plugin->deamon_start(true);
	echo 'restarted';
}" > /tmp/rflink_fix_restart 2>&1
if grep -q restarted /tmp/rflink_fix_restart; then
	sleep 15
	if pgrep -f 'rflink\.js' >/dev/null; then
		log "RFLink: daemon restarted and still running after 15s"
	else
		log "RFLink: daemon NOT running 15s after restart, see the rflink_node log"
		exit 1
	fi
else
	log "RFLink: daemon not restarted ($(tr '\n' ' ' < /tmp/rflink_fix_restart))"
fi
rm -f /tmp/rflink_fix_restart
