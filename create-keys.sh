#!/bin/bash -ex
OUT_DIR='/secureboot/priv_keys'
OUT_EFI_DIR='/secureboot/efi_keys'

if [ "$#" -ne 1 ]; then
	echo "Please specify your name for certs"
  exit 1
fi
CN="$1"


mkdir $OUT_DIR -p
mkdir $OUT_EFI_DIR -p
if [ ! -e "$OUT_DIR/GUID.txt" ]; then
    GUID=$(uuidgen)
    echo $GUID > $OUT_DIR/GUID.txt
else
    echo "Please remove '"$OUT_DIR"GUID.txt' to regenerate certs"
    echo "This will overwrite your private keys!"
    exit 1
fi

for cert in PK KEK db dbx; do
    # SSL certs
    openssl req -new -x509 -newkey rsa:2048 -subj "/CN=$CN $cert/" -keyout \
        $OUT_DIR/$cert.key -out $OUT_DIR/$cert.crt -days 3650 -nodes -sha256

    # EFI signature list certs
    # .esl certs can be concatenated if we want to support multiple signers
    cert-to-efi-sig-list -g $GUID $OUT_DIR/$cert.crt $OUT_EFI_DIR/$cert.esl
done
# Empty PK to reset secure boot
rm -f $OUT_EFI_DIR/noPK.esl
touch $OUT_EFI_DIR/noPK.esl

sign-efi-sig-list -c $OUT_DIR/PK.crt -k $OUT_DIR/PK.key PK $OUT_EFI_DIR/noPK.esl $OUT_EFI_DIR/noPK.auth
sign-efi-sig-list -c $OUT_DIR/PK.crt -k $OUT_DIR/PK.key PK $OUT_EFI_DIR/PK.esl $OUT_EFI_DIR/PK.auth
sign-efi-sig-list -c $OUT_DIR/PK.crt -k $OUT_DIR/PK.key KEK $OUT_EFI_DIR/KEK.esl $OUT_EFI_DIR/KEK.auth
sign-efi-sig-list -c $OUT_DIR/KEK.crt -k $OUT_DIR/KEK.key db $OUT_EFI_DIR/db.esl $OUT_EFI_DIR/db.auth
sign-efi-sig-list -c $OUT_DIR/KEK.crt -k $OUT_DIR/KEK.key dbx $OUT_EFI_DIR/dbx.esl $OUT_EFI_DIR/dbx.auth
chmod 0600 $OUT_DIR/*.key
