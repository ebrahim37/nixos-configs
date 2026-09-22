{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		infra-template = {
			url = "github:ebrahim37/infra-template";
			flake = false;
		};
		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		sops-nix = {
			url = "github:Mic92/sops-nix";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		# don't follow nixpkgs because Noctalia has its own binary cache
		noctalia.url = "github:noctalia-dev/noctalia/cachix";
	};

	nixConfig = {
		extra-substituters = [ "https://noctalia.cachix.org" ];
		extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
	};

	outputs =
		inputs@{ home-manager, infra-template, nixpkgs, sops-nix, ... }:
		let
			vars.user = {
				username = "ebrahim";
				name = "Ebrahim";
				gitEmail = "53321702+ebrahim37@users.noreply.github.com";
				sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICADuTaD1i54A/489uTWBSbh3RIo92DPVh8MZ2cGRGF3";
			};
			mkHost =
				hostName: system:
				let
					homeFiles = nixpkgs.legacyPackages.${system}.runCommand "home-files" { } ''
						mkdir -p "$out/.config" "$out/scripts"
						cp -R ${infra-template}/cnc-shared/home/.config/nvim "$out/.config/nvim"
						cp -R ${infra-template}/cnc-shared/scripts/common/. "$out/scripts/"
						chmod -R u+w "$out"

						cp -R ${./files}/. "$out/"
						find "$out/scripts" -type f -exec chmod 0755 {} +
					'';
					specialArgs = {
						inherit homeFiles inputs vars;
					};
				in
				nixpkgs.lib.nixosSystem {
					inherit specialArgs system;
					modules = [
						sops-nix.nixosModules.sops
						home-manager.nixosModules.home-manager
						./modules/common.nix
						./modules/desktop.nix
						(./hosts + "/${hostName}.nix")
						{
							home-manager = {
								useGlobalPkgs = true;
								useUserPackages = true;
								backupFileExtension = "hm-backup";
								extraSpecialArgs = specialArgs;
								sharedModules = [ inputs.noctalia.homeModules.default ];
								users.${vars.user.username} = import ./modules/home-manager.nix;
							};
						}
					];
				};
		in
		{
			nixosConfigurations = {
				pc-qemu = mkHost "pc-qemu" "x86_64-linux";
				mba-utm = mkHost "mba-utm" "aarch64-linux";
			};
			packages = {
				x86_64-linux.stremio-enhanced =
					nixpkgs.legacyPackages.x86_64-linux.callPackage ./packages/stremio-enhanced.nix { };
				aarch64-linux.stremio-enhanced =
					nixpkgs.legacyPackages.aarch64-linux.callPackage ./packages/stremio-enhanced.nix { };
			};
		};
}
