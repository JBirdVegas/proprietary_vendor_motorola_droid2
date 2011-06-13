#!/system/bin/sh
# 
# loadpreinstalls.sh - installs apps / does other kewl stuff
# 
# Copyright (C) 2010 Jared Rummler (JRummy16)
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 

LIBERTY_DIR=/data/liberty/app
CONTROL_FILE=/data/liberty/init.d.conf
HELPERS=/system/etc/script.helpers
INSTALL_FROM_SD=/mnt/sdcard/liberty/install_apps

. $CONTROL_FILE
. $HELPERS

# Set install location
pm setInstallLocation $APP_INSTALL_LOCATION
echo "Set install location to "$(pm getInstallLocation | sed -e 's|^..||' -e 's|.$||')"" | tee -a $LOG_FILE

# Install apps
installApps -r $LIBERTY_DIR

# Unzip files
unzipFilesInDir /system/etc/animations
unzipFilesInDir /system/etc/icons

# Setup hacked adb
if test -e /system/bin/adbd; then
	sysrw
	echo "Set new adbd" | tee -a $LOG_FILE
	busybox mount -orw,remount / 
	mv /sbin/adbd /sbin/adbd.old 
	busybox cp /system/bin/adbd /sbin/adbd 
	busybox mount -oro,remount / 
	if test ! -z "$(ps | grep adbd)"; then
		busybox kill $(ps | grep adbd) 
	fi
fi

# Wait for sdcard to mount & install apps on sd
waitForSD
installApps $INSTALL_FROM_SD

# remove old toolbox installed by themes:
toolbox=`ls system/app | grep -i libertytoolbox`
if test -n "$toolbox"; then
	busybox mount -o remount,rw /system
	busybox rm -f /system/app/$toolbox
fi

# Check for automatic updates
getAutomaticUpdates
