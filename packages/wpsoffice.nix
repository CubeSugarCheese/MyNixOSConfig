{
  wpsoffice-cn,
  makeWrapper,
  libva,
}:

wpsoffice-cn.overrideAttrs (
  finalAttrs: oldAttrs: {
    version = "12.1.2.29183";

    # Reuse nixpkgs' signed-download environment and pin the newer vendor archive.
    src = oldAttrs.src.overrideAttrs (_: {
      name = "wps-office-${finalAttrs.version}-amd64.deb";
      outputHash = "sha256-d/+9wb52yDThhTwn/5Bj5J1dOx8wsgbXhXYbW/VgyDs=";
      buildCommand = ''
        readonly SECURITY_KEY="7f8faaaa468174dc1c9cd62e5f218a5b"
        uri=/wps/download/ep/Linux2023/29183/wps-office_${finalAttrs.version}.AK.preread.sw.Personal_806791_amd64.deb
        timestamp=$(date +%s)
        signature=$(printf '%s' "$SECURITY_KEY$uri$timestamp" | md5sum | cut -d ' ' -f 1)
        curl --fail --location --retry 3 --retry-delay 3 --connect-timeout 30 \
          "https://wps-linux-personal.wpscdn.cn$uri?t=$timestamp&k=$signature" \
          --output "$out"
      '';
    });

    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ makeWrapper ];

    # The newer archive includes VA-API codecs but omits this optional AI library.
    buildInputs = oldAttrs.buildInputs ++ [ libva ];
    autoPatchelfIgnoreMissingDeps = (oldAttrs.autoPatchelfIgnoreMissingDeps or [ ]) ++ [
      "libksailite.so"
    ];
  }
)
