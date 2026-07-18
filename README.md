# NixOS Configs

This flake define a config for two hosts:

- `pc-vmware`: `x86_64-linux`, VMware Workstation Pro on Windows 11, PVSCSI, VMXNET3, SVGA3D, and open-vm-tools.
- `mba-utm`: `aarch64-linux`, UTM's QEMU backend on an M2 Mac, VirtIO devices/GPU, SPICE agent, and QEMU guest agent.

`modules/common.nix` contains system-wide shared options only; user configuration is isolated in `modules/hm-config.nix`.

## VM settings

For VMware, use UEFI firmware, add a TPM 2.0 device, enable 3D acceleration, select the PVSCSI storage controller, and use VMXNET3 networking.

For UTM, create an ARM64 Linux VM with the QEMU backend and hardware virtualization enabled. Use UEFI, TPM 2.0, a VirtIO block/SCSI disk, VirtIO networking, a SPICE display, and `virtio-gpu-gl`/OpenGL acceleration.

TPM enrollment binds to PCR 7. Keep the LUKS passphrase recorded somewhere safe; it is deliberately retained as the recovery path. A firmware, Secure Boot policy, or virtual TPM reset can require that passphrase and a new `systemd-cryptenroll` enrollment.

## Secrets

The installer expects both `secrets.yaml` and `~/.config/sops/age/keys.txt` on the live ISO.

## Install

From a recent NixOS minimal ISO, clone this repository to `~/nixos-configs`, add the age key and encrypted secrets as described above, then run:

```sh
cd ~/nixos-configs
sudo ./install.sh pc-vmware /dev/sda
# or:
sudo ./install.sh mba-utm /dev/vda
```

After login, rebuild the current host with `rebuild-nixos`.

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
