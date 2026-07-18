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
			"tpm_crb"
			"tpm_tis"
			"usb_storage"
			"virtio_blk"
			"virtio_gpu"
			"virtio_net"
			"virtio_pci"
			"virtio_scsi"
			"xhci_pci"
		];
		initrd.luks.devices.cryptroot.crypttabExtraOpts = [
			"tpm2-device=auto"
			"tpm2-pcrs=7"
		];
		kernelModules = [
			"virtio_balloon"
			"virtio_console"
			"virtio_gpu"
		];
	};

	security.tpm2 = {
		enable = true;
		pkcs11.enable = true;
		tctiEnvironment.enable = true;
	};

	services.qemuGuest.enable = true;
	services.spice-vdagentd.enable = true;

	environment.systemPackages = [ pkgs.spice-vdagent ];
}
