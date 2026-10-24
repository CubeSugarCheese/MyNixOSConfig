{
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "personal-nonfree-fonts";
  version = "1.0";

  src = ./files;
  dontConfigure = true;
  dontBuild = true;
  preferLocalBuild = true;
  allowSubstitutes = false;

  installPhase = ''
    runHook preInstall

    find . -type f \( -iname '*.ttf' -o -iname '*.ttc' -o -iname '*.otf' -o -iname '*.otc' \) \
      -exec install -Dm644 '{}' "$out/share/fonts/personal-nonfree/{}" \;

    runHook postInstall
  '';

  meta = {
    description = "Personal fonts bundled with the NixOS configuration";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
  };
}
