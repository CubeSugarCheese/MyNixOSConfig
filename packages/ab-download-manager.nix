{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  alsa-lib,
  cups,
  fontconfig,
  freetype,
  gtk3,
  libGL,
  libx11,
  libxext,
  libxi,
  libxrender,
  libxtst,
  libxrandr,
  xdg-utils,
  zlib,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "ab-download-manager";
  version = "1.11.1";

  src = fetchurl {
    url = "https://github.com/amir1376/ab-download-manager/releases/download/v${finalAttrs.version}/ABDownloadManager_${finalAttrs.version}_linux_x64.tar.gz";
    hash = "sha256-yV3EwFrwCTS6OofoLM3bbslbe7rQSdIQ2mUJ862mX0k=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    alsa-lib
    cups
    fontconfig
    freetype
    gtk3
    libGL
    libx11
    libxext
    libxi
    libxrender
    libxtst
    libxrandr
    zlib
  ];

  # Java's shared libraries load these with dlopen; executable RUNPATH alone
  # is not inherited by those libraries. Preserve paths on every patched ELF.
  appendRunpaths = map (package: "${lib.getLib package}/lib") [
    fontconfig
    gtk3
    libGL
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/ab-download-manager" "$out/bin"
    cp -r bin lib "$out/lib/ab-download-manager/"
    install -Dm644 lib/ABDownloadManager.png \
      "$out/share/icons/hicolor/256x256/apps/ab-download-manager.png"

    makeWrapper "$out/lib/ab-download-manager/bin/ABDownloadManager" \
      "$out/bin/ab-download-manager" \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]}
    makeWrapper "$out/lib/ab-download-manager/bin/ABDownloadManagerCli" \
      "$out/bin/ab-download-manager-cli" \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]}
    makeWrapper "$out/lib/ab-download-manager/bin/ABDownloadManagerNativeMessagingHost" \
      "$out/bin/ab-download-manager-native-messaging-host"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "ab-download-manager";
      desktopName = "AB Download Manager";
      comment = "Manage and organize downloads";
      exec = "ab-download-manager %U";
      icon = "ab-download-manager";
      categories = [
        "Network"
        "FileTransfer"
      ];
      terminal = false;
    })
  ];

  meta = {
    description = "Desktop download manager with browser integration";
    homepage = "https://abdownloadmanager.com/";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "ab-download-manager";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
