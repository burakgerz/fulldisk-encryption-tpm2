# Encrypted rootfs disk encryption key bound to TPM2 policy
This setup uses dracut for generating UKI images, systemd-cryptenroll to enroll disk encryption key to TPM2 and systemd-crytsetup in initrd to decrypt and setup rootfs.
An unencrypted filesystem EFI partition (FAT filesystem) is needed, where UKI images can reside.
You need to install systemd-boot, systemd-cryptsetup, dracut, sbsigntool, openssl, efitools

## Easy Setup
If you dont load your own kernel modules, you can use this setup

### Boot flow:
UEFI Firmware -> systemd-boot -> UKI Image

### Key creation
Create secureboot keys, see `create-keys.sh`
Copy generated efi_keys directory to FAT partition

### UKI image generation
You must create a new UKI after Kernel or initrd update
Copy dracut config to `/etc/dracut.d/`

### Add gpt rootfs type guid
For x86 rootfs:
sudo sgdisk --typecode=<partition>:4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709 <block-dev>
e.g. sudo sgdisk --typecode=2:4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709 /dev/nvme0n1 
systemd in initramfs will then automaticaly find the rootfs

### Enrolling key to a diskencryption tpm for rootfs encryption:
`systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 --tpm2-pcrs=15:sha256=0000000000000000000000000000000000000000000000000000000000000000 <rootfs-block-dev>`  
Additionally enroll a recovery password !!!! NEVER WIPE IT !!!!  
see https://systemd.io/TPM2_PCR_MEASUREMENTS/ for more information about TPM meassurements done by firmware and systemd

### Regenerate UKI
`dracut -f`

### Sign and deploy systemd-boot after update
You must sign and deploy systemd-boot after every update
manual sign as first step:  
`sbsign --key <db.key> --cert <db.crt> <path-to-systemd-boot> --output <path-to-systemd-boot>`  
All future signings shall be done automatically, you can hook into `systemd-boot-update.service` with `systemctl edit systemd-boot-update.service`  
Script for signing (sign-systemd-boot.bash) and drop-in (systemd-boot-update-override.conf) can be used

### Deploy .auth files and enable secureboot
Reboot into UEFI Firmware and deploy .auth files from efi_keys on FAT partition - select systemd-boot as first boot entry

## Advanced Setup when loading self-signed kernel modules is needed
Do the same as in Easy Setup, but select shim as first boot entry when in UEFI firmware.
Additionally you need to replace grub with systemd-boot and sign shim and MOK Manager with your db.key

### Boot flow:
UEFI Firmware -> shim -> MOK Manager -> systemd-boot -> UKI Image

### Replace grub
You must copy systemd-boot to grubx64 (since shim only loads grub currently, there is PR in shim to extend this, but dont find it)
--> replace /boot/efi/EFI/debian/grubx64.efi with /boot/efi/EFI/systemd/systemd-bootx64.efi

### Sign shim and MOK Manager manually
`sbsign --key <db.key> --cert <db.crt> <path-to-shim> --output <path-to-shim>`  
`sbsign --key <db.key> --cert <db.crt> <path-to-mok> --output <path-to-mok>`  

### Deploy .auth files and enable secureboot
Reboot into UEFI Firmware and deploy .auth files from efi_keys on FAT partition - select systemd-boot as first boot entry

### Use db key to verify own kernel modules
`mokutil --use-db` to load db keys for kernel module signing
Then reboot, you should see MOK Manager to verify the newely deployed db key

### Signed oot kernel modules
For loading self build, self signed kernel modules:
```
module_path=/lib...  
unxz $module_path  
/usr/src/linux-headers-$(uname -r)/scripts/sign-file sha256 /secureboot/priv_keys/db.key /secureboot/priv_keys/db.crt ${module_path%%.xz}  
xz --check=crc32 --lzma2=dict=512KiB "${module_path%%.xz}"
```
