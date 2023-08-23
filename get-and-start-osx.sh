#!/usr/bin/env bash

[ -z "${OSXVERSION}" ] && export "OSXVERSION=big-sur"
[ -z "${DISKSIZE}" ] && export "DISKSIZE=128G"
[ -z "${ALLOCATED_RAM}" ] && export "ALLOCATED_RAM=7192"
[ -z "${CPU_SOCKETS}" ] && export "CPU_SOCKETS=1"
[ -z "${CPU_CORES}" ] && export "CPU_CORES=2"
[ -z "${CPU_THREADS}" ] && export "CPU_THREADS=4"


FILE=BaseSystem.img
if [ ! -e "$FILE" ]; then
	python3 fetch-macOS-v2.py --action download -s $OSXVERSION
	dmg2img -i BaseSystem.dmg BaseSystem.img
	qemu-img create -f qcow2 mac_hdd_ng.img $DISKSIZE
fi 


MY_OPTIONS="+ssse3,+sse4.2,+popcnt,+avx,+aes,+xsave,+xsaveopt,check"

# This script works for Big Sur, Catalina, Mojave, and High Sierra. Tested with
# macOS 10.15.6, macOS 10.14.6, and macOS 10.13.6.

REPO_PATH="."
OVMF_DIR="."


qemu-system-x86_64 -enable-kvm -m "$ALLOCATED_RAM" -cpu Penryn,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,"$MY_OPTIONS" \
  -machine q35 \
  -usb -device usb-kbd -device usb-tablet \
  -smp "$CPU_THREADS",cores="$CPU_CORES",sockets="$CPU_SOCKETS" \
  -device usb-ehci,id=ehci \
  -device nec-usb-xhci,id=xhci \
  -global nec-usb-xhci.msi=off \
  -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" \
  -drive if=pflash,format=raw,readonly=on,file="$REPO_PATH/$OVMF_DIR/OVMF_CODE.fd" \
  -drive if=pflash,format=raw,file="$REPO_PATH/$OVMF_DIR/OVMF_VARS-1920x1080.fd" \
  -smbios type=2 \
  -device ich9-ahci,id=sata \
  -drive id=OpenCoreBoot,if=none,snapshot=on,format=qcow2,file="$REPO_PATH/OpenCore/OpenCore.qcow2" \
  -device ide-hd,bus=sata.2,drive=OpenCoreBoot \
  -device ide-hd,bus=sata.3,drive=InstallMedia \
  -drive id=InstallMedia,if=none,file="$REPO_PATH/BaseSystem.img",format=raw \
  -drive id=MacHDD,if=none,file="$REPO_PATH/mac_hdd_ng.img",format=qcow2 \
  -device ide-hd,bus=sata.4,drive=MacHDD \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 -device vmxnet3,netdev=net0,id=net0,mac=52:54:00:c9:18:27 \
  -monitor stdio \
  -device vmware-svga \
  -display none \
  -vnc 0.0.0.0:1,password=off -k en-us
