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

		# don't follow nixpkgs because noctalia has own binary cache
		noctalia.url = "github:noctalia-dev/noctalia/cachix";
	};

	nixConfig = {
		extra-substituters = [ "https://noctalia.cachix.org" ];
		extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
	};

	outputs =
		inputs@{home-manager, infra-template, nixpkgs, self, sops-nix, ...}:
		let
			secretLines = builtins.filter builtins.isString (
				builtins.split "\n" (builtins.readFile ./secrets.yaml)
			);
			getPublicVar = name:
				let
					values = builtins.filter (value: value != null) (
						builtins.map (
							line:
							let match = builtins.match "${name}: (.*)" line;
							in if match == null then null else builtins.head match
						) secretLines
					);
				in
				if builtins.length values == 1 then
					builtins.head values
				else
					throw "Expected exactly one ${name} entry in secrets.yaml";
			publicVars = {
				user_short_name = getPublicVar "user_short_name";
				user_long_name = getPublicVar "user_long_name";
				git_email = getPublicVar "git_email";
			};
			mkHost = { hostName, system }:
			let
				pkgs = nixpkgs.legacyPackages.${system};
				hostFiles = ./files + "/${hostName}";
				homeFiles = pkgs.runCommand "home-files-${hostName}" { } ''
					mkdir -p "$out/.config" "$out/scripts"
					cp -R ${infra-template}/shared/home/.config/nvim "$out/.config/nvim"
					cp -R ${infra-template}/shared/home/scripts/. "$out/scripts/"
					chmod -R u+w "$out"

					rm -f \
						"$out/scripts/croc.jinja" \
						"$out/scripts/scroc.jinja" \
						"$out/scripts/http" \
						"$out/scripts/list-services" \
						"$out/scripts/run-host" \
						"$out/scripts/run-host-root" \
						"$out/scripts/start-services" \
						"$out/scripts/stop-services" \
						"$out/scripts/update-cnc" \
						"$out/scripts/update-services"

					cp -R ${./files/shared}/. "$out/"
					cp -R ${hostFiles}/. "$out/"
					find "$out/scripts" -type f -exec chmod 0755 {} +
				'';
			in
			nixpkgs.lib.nixosSystem {
				inherit system;
				specialArgs = { inherit homeFiles inputs publicVars self; };
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
							extraSpecialArgs = { inherit homeFiles inputs publicVars self; };
							sharedModules = [ inputs.noctalia.homeModules.default ];
							users.${publicVars.user_short_name} = import ./modules/hm-config.nix;
						};
					}
				];
			};
		in
		{
			nixosConfigurations = {
				pc-vbox = mkHost { hostName = "pc-vbox"; system = "x86_64-linux"; };
				mba-utm = mkHost { hostName = "mba-utm"; system = "aarch64-linux"; };
			};
		};
}
