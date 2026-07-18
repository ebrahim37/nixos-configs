# NixOS Configs

This flake defines a config for two hosts:

- `pc-vbox`: `x86_64-linux`, Oracle VirtualBox on Windows 11 with VirtualBox Guest Additions.
- `mba-utm`: `aarch64-linux`, UTM's QEMU backend on an M2 Mac, VirtIO devices/GPU, SPICE agent, and QEMU guest agent.

`modules/common.nix` contains system-wide shared options only; user configuration is isolated in `modules/hm-config.nix`.

## VM settings

For VirtualBox, use UEFI firmware, add a TPM 2.0 device, use a SATA disk, select the VMSVGA graphics controller with 128 MB video memory, and enable 3D acceleration. The Linux guest will use VirtualBox Guest Additions from NixOS.

For UTM, create an ARM64 Linux VM with the QEMU backend and hardware virtualization enabled. Use UEFI, TPM 2.0, a VirtIO block/SCSI disk, VirtIO networking, a SPICE display, and `virtio-gpu-gl`/OpenGL acceleration.

TPM enrollment binds to PCR 7. Keep the LUKS passphrase recorded somewhere safe; it is deliberately retained as the recovery path. A firmware, Secure Boot policy, or virtual TPM reset can require that passphrase and a new `systemd-cryptenroll` enrollment.

## Secrets

The installer expects both `secrets.yaml` and `~/.config/sops/age/keys.txt` on the live ISO.

Secret values in `secrets.yaml` are prefixed with `enc_priv_` and these are automatically encrypted by `sops`.

## Install

From a recent NixOS minimal ISO, clone this repository to `~/nixos-configs`, add the age key and encrypted secrets as described above, then run:

```sh
cd ~/nixos-configs
sudo ./install.sh pc-vbox /dev/sda USERNAME_HERE
# or:
sudo ./install.sh mba-utm /dev/vda USERNAME_HERE
```

The third argument must match `user_short_name` in `secrets.yaml`.

After install, you can rebuild the current host with `rebuild-nixos`.

## Key bindings

- `Super+E`: Nautilus
- `Super+B`: Firefox
- `Super+Enter`: foot client (using the user foot server)
- `Super+Space`: Noctalia launcher
- `Super+V`: Noctalia clipboard history
- `Super+F`: fullscreen
- `Super+L`: lock
- `Super+S`: Noctalia control center
- `Super+,`: Noctalia settings
- `Super+Q`: close window
- `Super+1` through `Super+9`: select workspace
- `Super+Shift+1` through `Super+Shift+9`: move window to workspace
- `Print`: full-output screenshot; `Super+Print`: region screenshot
