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
		# Don't follow nixpkgs because Noctalia has its own binary cache.
		noctalia.url = "github:noctalia-dev/noctalia/cachix";
	};

	nixConfig = {
		extra-substituters = [ "https://noctalia.cachix.org" ];
		extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
	};

	outputs =
		inputs@{ home-manager, infra-template, nixpkgs, self, sops-nix, ... }:
		let
			secretLines = builtins.filter builtins.isString (
				builtins.split "\n" (builtins.readFile ./secrets.yaml)
			);
			getPublicVar =
				name:
				let
					values = builtins.concatMap (
						line:
						let
							match = builtins.match "${name}: (.*)" line;
						in
						if match == null then [ ] else match
					) secretLines;
				in
				if builtins.length values == 1 then
					builtins.head values
				else
					throw "Expected exactly one ${name} entry in secrets.yaml";
			publicVars = builtins.mapAttrs (name: _: getPublicVar name) {
				user_short_name = null;
				user_long_name = null;
				git_email = null;
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
						inherit homeFiles inputs publicVars self;
					};
				in
				nixpkgs.lib.nixosSystem {
					inherit specialArgs system;
					modules = [
						sops-nix.nixosModules.sops
						home-manager.nixosModules.home-manager
						./modules/common.nix
						(./modules + "/${hostName}.nix")
						{
							home-manager = {
								useGlobalPkgs = true;
								useUserPackages = true;
								backupFileExtension = "hm-backup";
								extraSpecialArgs = specialArgs;
								sharedModules = [ inputs.noctalia.homeModules.default ];
								users.${publicVars.user_short_name} = import ./modules/hm-config.nix;
							};
						}
					];
				};
		in
		{
			nixosConfigurations = builtins.mapAttrs mkHost {
				pc-qemu = "x86_64-linux";
				mba-utm = "aarch64-linux";
			};
		};
}
