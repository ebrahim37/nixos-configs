#!/usr/bin/env bash
set -Eeuo pipefail

[[ $# -eq 2 ]] || { echo "Usage: sudo $0 <hostname> </dev/disk>" >&2; exit 2; }

HOST_NAME=$1
INSTALL_DISK=$2
REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
AGE_KEY_SOURCE=${SUDO_USER:+/home/$SUDO_USER}/.config/sops/age/keys.txt

case "$INSTALL_DISK" in
  *[0-9])
    EFI_PARTITION="${INSTALL_DISK}p1"
    ROOT_PARTITION="${INSTALL_DISK}p2"
    ;;
  *)
    EFI_PARTITION="${INSTALL_DISK}1"
    ROOT_PARTITION="${INSTALL_DISK}2"
    ;;
esac

mounted=false
opened=false
cleanup() {
  if $mounted; then
    umount -R /mnt 2>/dev/null || true
  fi
  if $opened; then
    cryptsetup close cryptroot 2>/dev/null || true
  fi
}
trap cleanup ERR INT TERM

echo "Partitioning $INSTALL_DISK..."
wipefs --all --force "$INSTALL_DISK"
sgdisk --zap-all "$INSTALL_DISK"
sgdisk \
  --new=1:1MiB:+512MiB --typecode=1:ef00 --change-name=1:EFI \
  --new=2:0:0 --typecode=2:8309 --change-name=2:nixos-luks \
  "$INSTALL_DISK"
partprobe "$INSTALL_DISK"
udevadm settle

echo "Creating the EFI filesystem..."
mkfs.fat -F 32 -n BOOT "$EFI_PARTITION"

echo "Creating LUKS2. Choose a strong recovery passphrase and keep it safe."
cryptsetup luksFormat --type luks2 --verify-passphrase "$ROOT_PARTITION"
cryptsetup open "$ROOT_PARTITION" cryptroot
opened=true

mkfs.ext4 -F -L nixos /dev/mapper/cryptroot
mount /dev/disk/by-label/nixos /mnt
mounted=true
mkdir -p /mnt/boot
mount /dev/disk/by-label/BOOT /mnt/boot

# sops-nix needs the key during nixos-install activation
install -D -m 0600 "$AGE_KEY_SOURCE" /mnt/var/lib/sops-nix/key.txt

echo "Installing $HOST_NAME from $REPO_ROOT..."
nixos-install --flake "$REPO_ROOT#$HOST_NAME" --no-root-passwd

install -d -m 0755 -o 1000 -g 100 /mnt/home/ebrahim/.config
install -d -m 0700 -o 1000 -g 100 /mnt/home/ebrahim/.config/sops
install -d -m 0700 -o 1000 -g 100 /mnt/home/ebrahim/.config/sops/age
install -m 0600 -o 1000 -g 100 "$AGE_KEY_SOURCE" /mnt/home/ebrahim/.config/sops/age/keys.txt

echo "Set the local login password for ebrahim."
nixos-enter --root /mnt -c 'passwd ebrahim'

install -d -m 0755 -o 1000 -g 100 /mnt/home/ebrahim/nixos-configs
cp -a "$REPO_ROOT/." /mnt/home/ebrahim/nixos-configs/
chown -R 1000:100 /mnt/home/ebrahim/nixos-configs

echo "Enrolling the virtual TPM for automatic LUKS unlock (PCR 7)."
echo "Enter the LUKS recovery passphrase when prompted."
systemd-cryptenroll \
  --tpm2-device=auto \
  --tpm2-pcrs=7 \
  "$ROOT_PARTITION"

sync
umount -R /mnt
mounted=false
cryptsetup close cryptroot
opened=false
trap - ERR INT TERM

echo "Installation complete. Remove the ISO and reboot."
echo "Keep the LUKS recovery passphrase: it remains usable if TPM unlock fails."
