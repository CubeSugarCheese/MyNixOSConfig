{ lib, vscode-utils }:

vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = {
    name = "clice";
    publisher = "clice-io";
    version = "0.1.2026071902"; # 请替换为当前的实际版本号
    # 首次构建时，将此处留空或填入 lib.fakeSha256，Nix 会报错并给出正确哈希
    sha256 = lib.fakeSha256; 
  };

  meta = {
    description = "C++ language support powered by clice, a language server built on LLVM/Clang";
    homepage = "https://github.com/clice-io/clice";
    license = lib.licenses.apache; # 请根据项目实际许可证调整
    platforms = lib.platforms.linux; # 根据你的系统调整，扩展支持多平台
  };
}