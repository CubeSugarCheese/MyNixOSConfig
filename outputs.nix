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
