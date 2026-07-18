{ ... }:
{
	networking.hostName = "pc-vbox";
	system.stateVersion = "26.05";

	boot = {
		initrd.availableKernelModules = [
			"ahci"
			"ata_piix"
			"ehci_pci"
			"nvme"
			"ohci_pci"
			"sd_mod"
			"sr_mod"
			"tpm_tis"
			"tpm_crb"
			"usb_storage"
			"virtio_pci"
			"virtio_scsi"
			"xhci_pci"
		];
		kernelParams = [ "mitigations=auto" ];
	};

	virtualisation.virtualbox.guest.enable = true;
}
