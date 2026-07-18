{ pkgs, ... }:
{
	networking.hostName = "pc-vmware";
	system.stateVersion = "26.05";

	boot = {
		initrd = {
			availableKernelModules = [
				"ahci"
				"ata_piix"
				"ehci_pci"
				"nvme"
				"sd_mod"
				"sr_mod"
				"tpm_tis"
				"tpm_crb"
				"usb_storage"
				"vmw_pvscsi"
				"vmxnet3"
				"xhci_pci"
			];
			kernelModules = [ "vmw_pvscsi" ];
		};
		kernelModules = [
			"vmw_balloon"
			"vmw_vmci"
			"vmw_vsock_vmci_transport"
			"vmwgfx"
		];
		kernelParams = [ "mitigations=auto" ];
	};

	virtualisation.vmware.guest.enable = true;

	# keep the VMware virtual GPU on its accelerated Mesa path
	environment.variables.AQ_NO_ATOMIC = "1";
}
