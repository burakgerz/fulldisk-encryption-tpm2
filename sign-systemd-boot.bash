#!/bin/bash

CRT_PATH='/secureboot/MOK/MOK.crt'
KEY_PATH='/secureboot/MOK/MOK.key'
SYSTEMD_BOOT='/boot/efi/EFI/systemd/systemd-bootx64.efi'
GRUB='/boot/efi/EFI/debian/grubx64.efi'

if ! sbverify --cert $CRT_PATH $SYSTEMD_BOOT; then 
  sbsign --key $KEY_PATH --cert $CRT_PATH $SYSTEMD_BOOT --output $SYSTEMD_BOOT
	cp $SYSTEMD_BOOT $GRUB 
fi
