{
	autoPatchelfHook,
	cmake,
	copyDesktopItems,
	fetchFromGitHub,
	fontconfig,
	glib,
	glib-networking,
	gradle_9,
	gsettings-desktop-schemas,
	gst_all_1,
	gtk3,
	hicolor-icon-theme,
	jdk17,
	lib,
	libglvnd,
	libx11,
	libxcomposite,
	libxext,
	libxinerama,
	libxrandr,
	makeDesktopItem,
	makeWrapper,
	mpv-unwrapped,
	pkg-config,
	stdenv,
	webkitgtk_4_1,
	wrapGAppsHook3,
}:
let
	runtimeLibraries = [
		fontconfig
		glib
		glib-networking
		gsettings-desktop-schemas
		gst_all_1.gst-libav
		gst_all_1.gst-plugins-bad
		gst_all_1.gst-plugins-base
		gst_all_1.gst-plugins-good
		gst_all_1.gst-plugins-ugly
		gst_all_1.gstreamer
		gtk3
		hicolor-icon-theme
		libglvnd
		libx11
		libxcomposite
		libxext
		libxinerama
		libxrandr
		mpv-unwrapped
		stdenv.cc.cc.lib
		webkitgtk_4_1
	];
in
stdenv.mkDerivation (finalAttrs: {
	pname = "nuvio";
	version = "0.1.22-alpha";

	src = fetchFromGitHub {
		owner = "NuvioMedia";
		repo = "NuvioDesktop";
		tag = finalAttrs.version;
		hash = "sha256-y5zaGULPdXJw+wskvS0c8q1HFpEvhzm4gFiEv/rawXk=";
	};

	postPatch = ''
		# AIOStreams resolves TorBox streams remotely, so this build does not
		# expose Nuvio's bundled, x86-only local P2P implementation.
		rm -rf composeApp/src/desktopMain/torrserver
		substituteInPlace composeApp/src/desktopMain/kotlin/com/nuvio/app/core/build/AppFeaturePolicy.desktop.kt \
			--replace-fail 'actual val p2pEnabled: Boolean = true' 'actual val p2pEnabled: Boolean = false' \
			--replace-fail 'actual val inAppUpdaterEnabled: Boolean = true' 'actual val inAppUpdaterEnabled: Boolean = false'
		substituteInPlace gradle.properties \
			--replace-fail 'kotlin.daemon.jvmargs=-Xmx8192M' 'kotlin.daemon.jvmargs=-Xmx4096M' \
			--replace-fail 'org.gradle.jvmargs=-Xmx12288M' 'org.gradle.jvmargs=-Xmx4096M'

		# Record the Compose ARM64 runtime while generating the dependency cache,
		# even when the updater itself runs on x86_64.
		if [ "''${IN_GRADLE_UPDATE_DEPS:-}" = 1 ]; then
			substituteInPlace composeApp/build.gradle.kts \
				--replace-fail 'implementation(compose.desktop.currentOs)' $'implementation(compose.desktop.currentOs)\n                implementation(compose.desktop.linux_arm64)'
		fi

		printf '%s\n' \
			'NUVIO_SUPABASE_URL=https://api.nuvio.tv' \
			'NUVIO_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzgxNTIxMzQ2LCJleHAiOjE5MzkyMDEzNDZ9.tmQaj682pwzehpqlgCDMnySOqiUvpgRbrE43T4VJpDI' \
			'NUVIO_SUPABASE_FALLBACK_URL=https://api-two.nuvioapp.space' \
			> local.properties
	'';

	# CMake is only used by the vendored native-player build script.
	dontUseCmakeConfigure = true;
	# The JPackage launcher must not be renamed: its filename determines which
	# adjacent .cfg file and launcher library it loads.
	dontWrapGApps = true;

	gradleBuildTask = ":composeApp:createReleaseDistributable";
	gradleUpdateTask = finalAttrs.gradleBuildTask;

	mitmCache = gradle_9.fetchDeps {
		inherit (finalAttrs) pname;
		pkg = finalAttrs.finalPackage;
		data = ./nuvio-deps.json;
		silent = false;
		useBwrap = false;
	};

	env.JAVA_HOME = "${jdk17}/lib/openjdk";
	gradleFlags = [ "-Dorg.gradle.java.home=${jdk17}/lib/openjdk" ];

	nativeBuildInputs = [
		autoPatchelfHook
		cmake
		copyDesktopItems
		gradle_9
		jdk17
		makeWrapper
		pkg-config
		wrapGAppsHook3
	];

	buildInputs = runtimeLibraries;

	desktopItems = [
		(makeDesktopItem {
			name = "nuvio";
			desktopName = "Nuvio";
			comment = "Browse and play media from user-installed sources";
			exec = "Nuvio %u";
			icon = "nuvio";
			categories = [ "AudioVideo" ];
			mimeTypes = [
				"x-scheme-handler/nuvio"
				"x-scheme-handler/stremio"
			];
			startupNotify = true;
		})
	];

	installPhase = ''
		runHook preInstall

		# Skiko 0.144.6 rejects every VirGL renderer and falls back to CPU
		# rendering even when the guest has a working accelerated GL context.
		# Keep the class-file constant the same length while disabling only that
		# blacklist entry; all other Skiko adapter checks remain intact.
		appDir="$PWD/composeApp/build/compose/binaries/main-release/app/Nuvio/lib/app"
		for skikoJar in "$appDir"/skiko-awt-[0-9]*.jar; do
			rm -rf skiko-patch
			mkdir skiko-patch
			(
				cd skiko-patch
				jar xf "$skikoJar" org/jetbrains/skiko/GraphicsApi_jvmKt.class
			)
			LC_ALL=C sed -i 's/virgl/vrigl/g' \
				skiko-patch/org/jetbrains/skiko/GraphicsApi_jvmKt.class
			grep -a --quiet 'vrigl' skiko-patch/org/jetbrains/skiko/GraphicsApi_jvmKt.class
			jar uf "$skikoJar" -C skiko-patch org/jetbrains/skiko/GraphicsApi_jvmKt.class
		done

		mkdir -p "$out/bin" "$out/libexec"
		cp -R composeApp/build/compose/binaries/main-release/app/Nuvio \
			"$out/libexec/nuvio"
		makeWrapper "$out/libexec/nuvio/bin/Nuvio" "$out/bin/Nuvio"
		install -Dm644 "$out/libexec/nuvio/lib/Nuvio.png" \
			"$out/share/icons/hicolor/512x512/apps/nuvio.png"

		runHook postInstall
	'';

	postFixup = ''
		wrapProgram "$out/bin/Nuvio" \
			"''${gappsWrapperArgs[@]}" \
			--prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibraries}"
	'';

	passthru.updateScript = finalAttrs.mitmCache.updateScript;

	meta = {
		description = "Desktop media client for user-installed sources";
		homepage = "https://github.com/NuvioMedia/NuvioDesktop";
		license = lib.licenses.gpl3Only;
		mainProgram = "Nuvio";
		platforms = [
			"aarch64-linux"
			"x86_64-linux"
		];
	};
})
