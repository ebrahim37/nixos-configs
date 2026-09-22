# NixOS Configs

This flake defines a config for 2 hosts:
- `pc-qemu`: `x86_64-linux`, QEMU with WHPX on a Windows 11 PC
- `mba-utm`: `aarch64-linux`, UTM (QEMU) on an M2 Macbook Air

## VM settings

For QEMU on Windows, use UEFI firmware, VirtIO block/network/GPU devices, OpenGL acceleration, and the low-latency SDL display. The guest enables `qemu-guest-agent`; using it from the Windows host requires exposing an `org.qemu.guest_agent.0` virtio-serial channel. The guest agent is optional and does not affect display or input behavior.

For UTM, create an ARM64 Linux VM with the QEMU backend and hardware virtualization enabled. Use UEFI, TPM 2.0, a VirtIO block/SCSI disk, VirtIO networking, a SPICE display, and `virtio-gpu-gl`/OpenGL acceleration.

TPM enrollment binds to PCR 7. Keep the LUKS passphrase recorded somewhere safe; it is deliberately retained as the recovery path. A firmware, Secure Boot policy, or virtual TPM reset can require that passphrase and a new `systemd-cryptenroll` enrollment.

## Install

From a recent NixOS minimal ISO, clone this repository to `~/nixos-configs`, add the age key to `~/.config/sops/age/keys.txt`, then run:

```sh
cd ~/nixos-configs
sudo ./install.sh pc-qemu /dev/vda USERNAME_HERE
# or, for UTM:
sudo ./install.sh mba-utm /dev/vda USERNAME_HERE
```

The username must match `vars.user.username` in `flake.nix`.

After install, you can rebuild the config with `rebuild-nixos` and update flake inputs with `update-nixos`.

## Key bindings

- `Super+E`: Nautilus
- `Super+B`: Firefox
- `Super+Enter`: foot client (using the user foot server)
- `Super+\`: choose a host with Fuzzel and connect over SSH
- `Super+Backspace`: choose a host with Fuzzel and attach to remote Neovim
- `Super+Space`: Noctalia launcher
- `Super+V`: Noctalia clipboard history
- `Super+F`: maximize the focused column
- `Super+M`: maximize the focused window to the screen edges
- `Super+Shift+F`: fullscreen the focused window
- `Super+Shift+P`: Noctalia session panel
- `Super+L`: lock
- `Super+S`: Noctalia control center
- `Super+,`: Noctalia settings
- `Super+Q`: close window
- `Super+Left` / `Super+Right`: focus the column to the left or right
- `Super+Up` / `Super+Down`: focus the window above or below
- `Super+Shift+Left` / `Super+Shift+Right`: move the focused column left or right
- `Super+Shift+Up` / `Super+Shift+Down`: move the focused window up or down
- `Super+mouse wheel`: focus the workspace above or below
- `Alt+Tab`: Noctalia window switcher
- `Super+Tab`: Niri window switcher
- `Super+1` through `Super+9`: select workspace
- `Super+Shift+1` through `Super+Shift+9`: move window to workspace
- `Super+J`: open Stremio Enhanced
- `Print`: full-output screenshot; `Super+Print`: region screenshot
