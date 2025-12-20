#!/bin/bash

KEY_PATH='/secureboot/priv_keys/db.key'
CRT_PATH='/secureboot/priv_keys/db.crt'
SYSTEMD_BOOT='/boot/efi/EFI/systemd/systemd-bootx64.efi'
GRUB='/boot/efi/EFI/debian/grubx64.efi'

if ! sbverify --cert $CRT_PATH $SYSTEMD_BOOT; then 
  sbsign --key $KEY_PATH --cert $CRT_PATH $SYSTEMD_BOOT --output $SYSTEMD_BOOT
	cp $SYSTEMD_BOOT $GRUB 
fi
