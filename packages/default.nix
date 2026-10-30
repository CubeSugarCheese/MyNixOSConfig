{ callPackage }:

{
  ab-download-manager = callPackage ./ab-download-manager.nix { };
  clice = callPackage ./clice.nix { };
  personal-fonts = callPackage ./personal-fonts { };
  plangothic = callPackage ./plangothic.nix { };
  wpsoffice = callPackage ./wpsoffice.nix { };
}
