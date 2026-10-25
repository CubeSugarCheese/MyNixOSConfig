{
  lib,
  stdenvNoCC,
  runCommandLocal,
  curl,
  coreutils,
  cacert,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  writeText,
  noto-fonts-cjk-sans,
  stdenv,
  alsa-lib,
  at-spi2-core,
  bzip2,
  cairo,
  cups,
  expat,
  fontconfig,
  freetype,
  gawk,
  glib,
  gnugrep,
  gnused,
  gtk3,
  libdrm,
  libgbm,
  libGL,
  libGLU,
  libice,
  libsm,
  libtool,
  libusb1,
  libuuid,
  libva,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxml2_13,
  libxrandr,
  libxrender,
  libxtst,
  libxv,
  nspr,
  pango,
  systemdLibs,
  udev,
  wayland,
  xdg-utils,
  xz,
  zlib,
}:

let
  # The bundled Qt 5.12 predates reliable variable-font support. Keep this
  # compatibility fallback local to WPS rather than changing desktop fonts.
  uiFonts = noto-fonts-cjk-sans.override { static = true; };
  fontConfig = writeText "wps-fonts.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
      <dir>${uiFonts}/share/fonts</dir>
      <selectfont>
        <rejectfont>
          <glob>*/NotoSans*CJK-VF*.ttc</glob>
        </rejectfont>
      </selectfont>
    </fontconfig>
  '';
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "wpsoffice-cn";
  version = "12.1.2.29183";

  # The official download button signs the URL using a public client-side key.
  # Generate a fresh signature at fetch time rather than pinning an expiring URL.
  src =
    runCommandLocal "wps-office-${finalAttrs.version}-amd64.deb"
      {
        nativeBuildInputs = [
          curl
          coreutils
        ];
        outputHashMode = "flat";
        outputHashAlgo = "sha256";
        outputHash = "sha256-d/+9wb52yDThhTwn/5Bj5J1dOx8wsgbXhXYbW/VgyDs=";
        impureEnvVars = lib.fetchers.proxyImpureEnvVars;
        SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
      }
      ''
        uri=/wps/download/ep/Linux2023/29183/wps-office_${finalAttrs.version}.AK.preread.sw.Personal_806791_amd64.deb
        timestamp=$(date +%s)
        signature=$(printf '%s' "7f8faaaa468174dc1c9cd62e5f218a5b$uri$timestamp" | md5sum | cut -d ' ' -f 1)
        curl --fail --location --retry 3 --retry-delay 3 --connect-timeout 30 \
          "https://wps-linux-personal.wpscdn.cn$uri?t=$timestamp&k=$signature" \
          --output "$out"
      '';

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    alsa-lib
    at-spi2-core
    bzip2
    cairo
    cups
    expat
    fontconfig
    freetype
    glib
    gtk3
    libdrm
    libgbm
    libGL
    libGLU
    libice
    libsm
    libtool
    libusb1
    libuuid
    libva
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxml2_13
    libxrandr
    libxrender
    libxtst
    libxv
    nspr
    pango
    systemdLibs
    udev
    wayland
    xz
    zlib
  ];

  # Shared libraries also dlopen these dependencies (notably libcef -> libudev).
  # runtimeDependencies only updates executables, so append paths to all ELFs.
  # Use the compatible libxml2.so.2 ABI rather than aliasing libxml2.so.16.
  appendRunpaths = map (package: "${lib.getLib package}/lib") [
    cups
    libGLU
    libxml2_13
    pango
    udev
  ];

  # The vendor ships optional AI and font watermark plugins without all their
  # runtime dependencies. Keep strict checking for all other libraries.
  autoPatchelfIgnoreMissingDeps = [
    "libksailite.so"
    "libmysqlclient.so.18"
  ];

  unpackCmd = "dpkg-deb --extract $src .";
  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;
  dontWrapQtApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -a opt "$out/"
    cp -a usr/. "$out/"
    office="$out/opt/kingsoft/wps-office/office6"

    # The deb contains this symlink but omits its libbz2.so.1.0.4 target.
    ln -sfn "${lib.getLib bzip2}/lib/libbz2.so.1.0" "$office/libbz2.so"

    # Peony is a UKUI file manager integration plugin, not used by Plasma.
    rm "$office/libpeony-wpsprint-menu-plugin.so"

    # The vendor's light dialogs hardcode backgrounds but inherit text colors
    # from the platform palette. KDE's dark palette makes their labels unreadable.
    # Use Qt's built-in light palette and style, including in spawned helpers.

    # WPS bundles its own Qt and Fcitx input-context plugin. Select that plugin
    # explicitly so XWayland windows can use Fcitx5/Rime directly, while native
    # Wayland applications keep the desktop's input-method defaults.

    # Avoid installing the vendor's generic "misc" command into the user PATH.
    mv "$out/bin/misc" "$out/bin/wps-misc"
    for command in wps wpp et wpspdf wps-misc; do
      substituteInPlace "$out/bin/$command" \
        --replace-fail /opt/kingsoft/wps-office "$out/opt/kingsoft/wps-office"
      wrapProgram "$out/bin/$command" \
        --prefix PATH : ${
          lib.makeBinPath [
            coreutils
            gawk
            gnugrep
            gnused
            xdg-utils
          ]
        } \
        --unset QT_PLUGIN_PATH \
        --unset QT_QPA_PLATFORM_PLUGIN_PATH \
        --unset QML2_IMPORT_PATH \
        --set QT_QPA_PLATFORMTHEME generic \
        --set QT_STYLE_OVERRIDE Fusion \
        --set QT_IM_MODULE fcitx \
        --set FONTCONFIG_FILE ${fontConfig} \
        --set-default QT_QPA_PLATFORM xcb
    done

    for desktop in "$out/share/applications/"*.desktop \
      "$out/opt/kingsoft/wps-office/desktops/"*.desktop; do
      substituteInPlace "$desktop" --replace-fail /usr/bin "$out/bin"
    done

    runHook postInstall
  '';

  meta = {
    description = "WPS Office Chinese personal edition";
    homepage = "https://linux.wps.cn/";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "wps";
  };
})
