{
  nixpkgs,
  home-manager,
  codex-desktop-linux,
  claude-desktop-nix-flake,
  rust-overlay,
  llm-agents,
  ...
}:
let
  pkgs = import nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
    overlays = [
      rust-overlay.overlays.default
      # Use static CJK fonts for both system packages and exported local packages.
      (_final: prev: {
        noto-fonts-cjk-sans = prev.noto-fonts-cjk-sans.override { static = true; };
        noto-fonts-cjk-serif = prev.noto-fonts-cjk-serif.override { static = true; };
      })
    ];
  };
  localPkgs = pkgs.callPackage ./packages { };
in
{
  formatter.x86_64-linux = pkgs.nixfmt-tree;

  packages.x86_64-linux = {
    inherit (localPkgs)
      ab-download-manager
      clice
      personal-fonts
      wpsoffice
      ;
  };

  nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
    modules = [
      { nixpkgs.pkgs = pkgs; }
      (import ./nixos.nix {
        inherit
          home-manager
          codex-desktop-linux
          claude-desktop-nix-flake
          llm-agents
          ;
      })
    ];
  };
}
