{
	appimageTools,
	fetchurl,
	lib,
	makeWrapper,
	stdenv,
}:
let
	pname = "stremio-enhanced";
	version = "1.2.0";

	sources = {
		aarch64-linux = fetchurl {
			url = "https://github.com/REVENGE977/stremio-enhanced/releases/download/v${version}/Stremio.Enhanced-${version}-arm64.AppImage";
			hash = "sha256-ceRVr7qJfFjNWQrJtOV6XLs8IpTjgtQJ1CDCXdVd1oM=";
		};
		x86_64-linux = fetchurl {
			url = "https://github.com/REVENGE977/stremio-enhanced/releases/download/v${version}/Stremio.Enhanced-${version}.AppImage";
			hash = "sha256-a+knxg/rd5Ied4RVK8Gg7xeFElovJab0gqxpjs11fAU=";
		};
	};

	system = stdenv.hostPlatform.system;
	src = sources.${system} or (throw "stremio-enhanced: unsupported system ${system}");
	appimageContents = appimageTools.extract { inherit pname src version; };
in
appimageTools.wrapType2 {
	inherit pname src version;

	nativeBuildInputs = [ makeWrapper ];

	extraInstallCommands = ''
		install -Dm644 ${appimageContents}/stremio-enhanced.desktop \
			$out/share/applications/stremio-enhanced.desktop
		install -Dm644 ${appimageContents}/stremio-enhanced.png \
			$out/share/pixmaps/stremio-enhanced.png
		substituteInPlace $out/share/applications/stremio-enhanced.desktop \
			--replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=stremio-enhanced %U'
		wrapProgram $out/bin/stremio-enhanced \
			--add-flags --no-sandbox \
			--add-flags --no-stremio-server
	'';

	meta = {
		description = "Electron-based Stremio client with plugin and theme support";
		homepage = "https://github.com/REVENGE977/stremio-enhanced";
		license = lib.licenses.mit;
		mainProgram = "stremio-enhanced";
		platforms = [
			"aarch64-linux"
			"x86_64-linux"
		];
		sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
	};
}
