{ ... }:
{
	networking.hostName = "pc-qemu";
	system.stateVersion = "26.05";

	boot = {
		initrd.availableKernelModules = [
			"ahci"
			"ehci_pci"
			"nvme"
			"sd_mod"
			"sr_mod"
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
		kernelParams = [ "mitigations=auto" ];
		loader.efi.canTouchEfiVariables = false;
	};
}
