# NixOS Configs

This flake defines a config for 2 hosts:
- `pc-qemu`: `x86_64-linux`, QEMU with WHPX on a Windows 11 PC
- `mba-utm`: `aarch64-linux`, UTM (QEMU) on an M2 Macbook Air

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

## Windows QEMU Setup

<details>
<summary>Windows host files and commands</summary>

### Files

Keep the VM disk, launch scripts, QEMU build, and TAP driver files together:

```text
qemu/
├── openvpn-tap/
│   ├── addtap.bat
│   ├── deltapall.bat
│   ├── (copied later) devcon.exe
│   ├── (copied later) OemVista.inf
│   ├── (copied later) tap0901.cat
│   └── (copied later) tap0901.sys
├── qemu-virgl-whpx-20260718/
├── iso.bat
├── NixOS.raw
└── run.bat
```

`qemu-virgl-whpx-20260718/` is the extracted build output from [Tsuki-Bakery/qemu-virgl-whpx](https://github.com/Tsuki-Bakery/qemu-virgl-whpx).

### Create the raw disk

```bat
qemu-virgl-whpx-20260718\qemu-img.exe create -f raw NixOS.raw 128G
```

Change `128G` to desired virtual disk size. I use raw for slightly better disk latency and throughput, qcow2 is also available.

### Install the TAP adapter and configure the bridge

Download [`dist.win10.zip`](https://github.com/OpenVPN/tap-windows6/releases/download/9.27.0/dist.win10.zip) from the OpenVPN TAP-Windows 9.27.0 release. Copy `devcon.exe`, `OemVista.inf`, `tap0901.cat`, and `tap0901.sys` into `openvpn-tap/`, then add these scripts:

`openvpn-tap/addtap.bat`:
```bat
rem https://github.com/ggreer/mpostr/blob/ab9df3a795bea220dae9c7f49ce3e5462be6e5f1/vendor/openvpn_install_source-2.0.9-gui-1.0.3/openvpn/bin/addtap.bat
rem Add a new TAP-Win32 virtual ethernet adapter
devcon.exe install OemVista.inf tap0901
pause
```
`openvpn-tap/deltapall.bat`:
```bat
rem https://github.com/ggreer/mpostr/blob/ab9df3a795bea220dae9c7f49ce3e5462be6e5f1/vendor/openvpn_install_source-2.0.9-gui-1.0.3/openvpn/bin/deltapall.bat
echo WARNING: this script will delete ALL TAP-Win32 virtual adapters (use the device manager to delete adapters one at a time)
pause
devcon.exe remove tap0901
pause
```

Run `addtap.bat` as Administrator from `openvpn-tap/`, then create the Windows
network bridge:

1. Press `Win+R`, run `ncpa.cpl`, and identify both the physical network
   adapter used by Windows and the newly installed TAP adapter
   (default name is `Local Area Connection`, screenshots below call it `TAP`).
3. Hold `Ctrl`, select the physical adapter and `Local Area Connection`,
   right-click either selection, and choose **Bridge Connections**.

![Selecting the physical and TAP adapters and choosing Bridge Connections](data:image/webp;base64,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)

4. Approve the administrator prompt and wait for **Network Bridge** to appear.
   Both selected adapters should show **Enabled, Bridged**.

![The physical and TAP adapters connected through Network Bridge](data:image/webp;base64,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)

Images from Hoi Wong's
[Qemu for Windows Host Quirks](https://wonghoi.humgar.com/blog/2021/05/03/qemu-for-windows-host-quirks/)
article.

### Install NixOS

Download a recent NixOS minimal ISO into `qemu/`, update the filename in
`iso.bat`, and run it. After the VM boots, follow the [Install](#install) instructions.

`iso.bat`:

```bat
@echo off
setlocal

set "VM_DIR=%~dp0"
set "QEMU_DIR=%VM_DIR%qemu-virgl-whpx-20260718"
set "QEMU_EXE=%QEMU_DIR%\qemu-system-x86_64w.exe"
set "OVMF=%QEMU_DIR%\share\edk2\x64\OVMF.4m.fd"

start "" "%QEMU_EXE%" ^
        -M q35 ^
        -m 16G ^
        -smp 16 ^
        -accel whpx,kernel-irqchip=off ^
        -netdev user,id=anet0 ^
        -device virtio-net-pci,netdev=anet0 ^
        -device intel-hda ^
        -device hda-duplex ^
        -usb ^
        -device usb-tablet ^
        -device virtio-vga-gl ^
        -display sdl,gl=on ^
        -drive file="%VM_DIR%NixOS.raw",if=virtio,format=raw ^
        -cdrom "%VM_DIR%nixos-minimal-26.05.4937.8eeec934ae0d-x86_64-linux.iso" ^
        -boot order=d,menu=on ^
        -bios "%OVMF%"
```

TAP driver is not needed for `iso.bat`, as it uses QEMU user networking.

### Run the installed VM

`run.bat`:

```bat
@echo off
setlocal

set "VM_DIR=%~dp0"
set "QEMU_DIR=%VM_DIR%qemu-virgl-whpx-20260718"
set "QEMU_EXE=%QEMU_DIR%\qemu-system-x86_64w.exe"
set "OVMF=%QEMU_DIR%\share\edk2\x64\OVMF.4m.fd"
set "TAP_NAME=Local Area Connection"

start "" "%QEMU_EXE%" ^
        -M q35 ^
        -accel whpx ^
        -m 16G ^
        -smp sockets=1,cores=6,threads=2 ^
        -cpu qemu64,-svm,+topoext,+aes,+sse4.1,+sse4.2,+ssse3,+popcnt,+cx16,+movbe,+pclmulqdq,+rdrand,+rdtscp ^
        -bios "%OVMF%" ^
        -drive file="%VM_DIR%NixOS.raw",if=none,id=osdisk,format=raw ^
        -audiodev dsound,id=audio_out,latency=30000,out.buffer-length=50000,out.frequency=48000,out.channels=2,out.format=s16 ^
        -audiodev sdl,id=audio_mic,in.fixed-settings=off ^
        -device intel-hda,id=hda_out ^
        -device hda-output,bus=hda_out.0,audiodev=audio_out ^
        -device intel-hda,id=hda_in ^
        -device hda-micro,bus=hda_in.0,audiodev=audio_mic ^
        -device virtio-blk-pci,drive=osdisk,bootindex=1 ^
        -netdev tap,id=anet0,ifname="%TAP_NAME%",script=no,downscript=no ^
        -device virtio-net-pci,netdev=anet0 ^
        -device qemu-xhci ^
        -device usb-tablet ^
        -device virtio-vga-gl ^
        -display sdl,full-screen=on,gl=on ^
        -serial none

rem if not doing bridged networking with openvpn tap driver use:
rem -netdev user,id=anet0 ^
```

This boots the raw disk with WHPX acceleration, VirGL graphics, separate
speaker and microphone devices, and the bridged TAP network.

</details>

## UTM Setup

<details>
<summary>UTM application and NixOS VM settings</summary>

### UTM app settings

Before creating the VM:

1. Open **UTM > Settings > Input**.
2. Enable **Invert Scrolling**.

### Create the VM

1. Click **Create a New Virtual Machine**.
2. Select **Virtualize**, then **Linux**.
3. Enable **Hardware OpenGL Acceleration**.
4. Select the NixOS ARM64 ISO as the boot image.
5. Set storage to **128 GiB**.
6. Set the VM name to **NixOS** and finish the wizard.

### Edit the VM settings

Before starting the VM, open its settings and apply:

- **QEMU**
  - Enable **RNG Device**.
  - Enable **Balloon Device**.
  - Disable **Reset UEFI Variables**.
- **Input**
  - Enable **Share USB Devices from Host**.
- **Sharing**
  - Set **Directory Share Mode** to **None**.
- **Sound**
  - Set **Emulated Audio Card** to **virtio-sound-pci**.
- **Display**
  - Enable **Retina Mode**.
  - Disable **Resize Automatically**.

</details>
