{ pkgs, ... }:
{
  # Automatically creates a loader in /lib/* to avoid patching stuff
  # To disable it temporarily use
  # unset NIX_LD
  programs.nix-ld = {
    enable = true;
    # 不要加 glibc：nix-ld 自带 loader，额外的 glibc 可能和程序自带的 libc 混用
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
    ];
  };
}
