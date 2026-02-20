#!/bin/sh
#skiddy mrchromebox for miniOS script
get_fixed_dst_drive() {
	local dev
	if [ -z "${DEFAULT_ROOTDEV}" ]; then
		for dev in /sys/block/sd* /sys/block/mmcblk*; do
			if [ ! -d "${dev}" ] || [ "$(cat "${dev}/removable")" = 1 ] || [ "$(cat "${dev}/size")" -lt 2097152 ]; then
				continue
			fi
			if [ -f "${dev}/device/type" ]; then
				case "$(cat "${dev}/device/type")" in
				SD*)
					continue;
					;;
				esac
			fi
			DEFAULT_ROOTDEV="{$dev}"
		done
	fi
	if [ -z "${DEFAULT_ROOTDEV}" ]; then
		dev=""
	else
		dev="/dev/$(basename ${DEFAULT_ROOTDEV})"
		if [ ! -b "${dev}" ]; then
			dev=""
		fi
	fi
	echo "${dev}"
}
intdis=$(get_fixed_dst_drive)
if echo "$intdis" | grep -q '[0-9]$'; then
	intdis_prefix="$intdis"p
else
	intdis_prefix="$intdis"
fi
cd /
mount "$intdis_prefix"3 /usb -o ro || mount "$intdis_prefix"5 /usb -o ro
mount --bind /dev /usb/dev
mount --bind /proc /usb/proc
mount --bind /sys /usb/sys
mount --bind /run /usb/run
mount --bind /tmp /usb/tmp
cd /tmp
curl -LO https://mrchromebox.tech/firmware-util.sh
cd /
#write script out to /tmp (idk if there is a better way to do this lol)
echo "cd /tmp" > /tmp/payload.sh
echo "bash /tmp/firmware-util.sh" >> /tmp/payload.sh
chroot /usb bash /tmp/payload.sh
umount /usb/*
umount /usb
sync
echo "exiting to minios shell"
