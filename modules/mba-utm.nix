{ pkgs, ... }:
{
	networking.hostName = "mba-utm";
	system.stateVersion = "26.05";

	boot = {
		loader.efi.canTouchEfiVariables = false;
		initrd.availableKernelModules = [
			"ahci"
			"nvme"
			"sd_mod"
			"sr_mod"
			"tpm_crb"
			"tpm_tis"
			"usb_storage"
			"usbhid"
			"xhci_pci"
			"virtio_blk"
			"virtio_gpu"
			"virtio_input"
			"virtio_net"
			"virtio_pci"
			"virtio_rng"
			"virtio_scsi"
		];
		initrd.luks.devices.cryptroot.crypttabExtraOpts = [
			"tpm2-device=auto"
			"tpm2-pcrs=7"
		];
		kernelModules = [
			"snd_virtio"
			"virtio_balloon"
			"virtio_console"
			"virtio_gpu"
			"virtio_input"
			"virtio_rng"
		];
	};

	security.tpm2 = {
		enable = true;
		pkcs11.enable = true;
		tctiEnvironment.enable = true;
	};

	services.qemuGuest.enable = true;
	services.spice-vdagentd.enable = true;
	services.fstrim.enable = true;

	environment.systemPackages = with pkgs; [
		clang-tools
		spice-vdagent
	];
}
