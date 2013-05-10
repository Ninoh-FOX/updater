#!/bin/bash
set -e
umask 0022

# Start with a fresh output dir.
rm -rf output
mkdir output

# Get kernel metadata.
if [ -e "vmlinuz.bin" ] ; then
	KERNEL=`realpath vmlinuz.bin`
fi

# Get rootfs metadata.
if [ -e "rootfs.squashfs" ] ; then
	ROOTFS=`realpath rootfs.squashfs`
fi

if [ "$KERNEL" -a "$ROOTFS" ] ; then
	if [ `date -r "$KERNEL" +%s` -gt `date -r "$ROOTFS" +%s` ] ; then
		DATE=`date -r "$KERNEL" +%F`
	else
		DATE=`date -r "$ROOTFS" +%F`
	fi
elif [ "$KERNEL" ] ; then
	DATE=`date -r "$KERNEL" +%F`
elif [ "$ROOTFS" ] ; then
	DATE=`date -r "$ROOTFS" +%F`
else
	echo "ERROR: No kernel or rootfs found."
	exit 1
fi

# Report metadata.
echo
echo "=========================="
echo
echo "Kernel:            $KERNEL"
echo "Root file system:  $ROOTFS"
echo "  build date:      $DATE"
echo
echo "=========================="
echo

# Write metadata.
cat > output/default.gcw0.desktop <<EOF
[Desktop Entry]
Name=OS Update
Version=$DATE
Comment=OpenDingux Update $DATE
Exec=update.sh
Icon=opendingux
Terminal=true
Type=Application
StartupNotify=true
Categories=applications;
EOF
# TODO: Reinstate this:
# X-OD-Manual=CHANGELOG

# Copy kernel and rootfs to output dir.
# We want to support symlinks for the kernel and rootfs images and if no
# copy is made, specifying the symlink will include the symlink in the OPK
# and specifying the real path might use a different name than the update
# script expects.
if [ -e "$KERNEL" ] ; then
	cp -a $KERNEL output/vmlinuz.bin
	KERNEL="output/vmlinuz.bin"
	chmod a-x "$KERNEL"
fi

if [ -e "$ROOTFS" ] ; then
	cp -a $ROOTFS output/rootfs.squashfs
	ROOTFS="output/rootfs.squashfs"
fi

# Create OPK.
OPK_FILE=output/gcw0-update-$DATE.opk
mksquashfs \
	output/default.gcw0.desktop \
	src/opendingux.png \
	src/update.sh \
	$KERNEL \
	$ROOTFS \
	$OPK_FILE \
	-no-progress -noappend -comp gzip -all-root

echo
echo "=========================="
echo
echo "Updater OPK:       $OPK_FILE"
echo
