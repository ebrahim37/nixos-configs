{ pkgs, ... }:
{
	networking.hostName = "mba-utm";
	system.stateVersion = "26.05";

	boot = {
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
		kernelModules = [
			"virtio_balloon"
			"virtio_console"
			"virtio_gpu"
		];
	};

	services.qemuGuest.enable = true;
	services.spice-vdagentd.enable = true;

	environment.systemPackages = [ pkgs.spice-vdagent ];
}
