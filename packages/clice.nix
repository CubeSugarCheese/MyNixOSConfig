{ lib, vscode-utils, autoPatchelfHook, stdenv }:

vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = let
    sources = {
      "x86_64-linux" = {
        arch = "linux-x64";
        hash = "sha256-h7OnH95uIZvBHBgRBRlOtmrJPoD9aIBlqFXDmxjTVk4=";
      };
      # 如果你也需要其他平台，可以按同样格式添加：
      # "aarch64-linux" = { arch = "linux-arm64"; hash = "..."; };
    };
  in {
    name = "clice";
    publisher = "clice-io";
    version = "0.1.2026101907";
  } // sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  # 其余部分保持不变
  vsixSource = "open-vsx";
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ (lib.getLib stdenv.cc.cc) ];
  preFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    addAutoPatchelfSearchPath $out/share/vscode/extensions/clice-io.clice/clice/bin
  '';

  meta = {
    description = "C++ language support powered by clice";
    homepage = "https://github.com/clice-io/clice";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}