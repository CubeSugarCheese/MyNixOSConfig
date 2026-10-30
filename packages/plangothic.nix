{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "plangothic";
  version = "2.9.5795";

  src = fetchurl {
    url = "https://github.com/Fitzgerald-Porthmouth-Koenigsegg/Plangothic_Project/releases/download/V${finalAttrs.version}/Plangothic-Static-V${finalAttrs.version}.zip";
    hash = "sha256-qm1H6T+hGbxQNBDTWiRUHRxNdAiGMvuaCC3c4nAwYYE=";
  };

  nativeBuildInputs = [ unzip ];
  dontConfigure = true;
  dontBuild = true;

  installPhase =
    let
      licenseFile = fetchurl {
        url = "https://raw.githubusercontent.com/Fitzgerald-Porthmouth-Koenigsegg/Plangothic_Project/V${finalAttrs.version}/LICENSE-OFL.txt";
        hash = "sha256-5WTwbQGOe5W8NZTJahfx1Bhlr0A4w3XnqpdN1p3zhgI=";
      };
    in
    ''
      runHook preInstall

      # P1 and P2 cover different characters; the TTC duplicates both fonts.
      install -Dm644 PlangothicP{1,2}-Regular.ttf -t "$out/share/fonts/truetype"
      install -Dm644 ${licenseFile} "$out/share/doc/plangothic/LICENSE-OFL.txt"

      runHook postInstall
    '';

  meta = {
    description = "Source Han Sans supplement covering CJK unified ideograph extensions";
    homepage = "https://github.com/Fitzgerald-Porthmouth-Koenigsegg/Plangothic_Project";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
