(final: prev: {
  # Backport the logind inhibitor fix so systemd >= 257 does not hide
  # Cinnamon's suspend, restart and shutdown buttons.
  cinnamon-session = prev.cinnamon-session.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (prev.fetchurl {
        url = "https://github.com/linuxmint/cinnamon-session/commit/2f256e0acf0130e16b156cd3e8f53dd576b2e31a.patch";
        hash = "sha256-7a6Q604Tv/3avX/25j7VXIqca4w60rVeJL3qypv9e1w=";
      })
    ];
  });
})
