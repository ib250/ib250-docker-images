let

  supportedSystems = [
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
    "aarch64-linux"
  ];

in {

  forEachSupportedSystem = {
    nixpkgs,
    overlays ? [],
    systems ? supportedSystems,
    f,
  }:
    nixpkgs.lib.genAttrs systems (system:
      f {
        pkgs = import nixpkgs {
          inherit system;
          inherit overlays;
        };
      });

  fenixOverlay = {fenix}: (_: prev: {
    fenix = let
      fenix' = fenix.inputs.nixpkgs.legacyPackages.${prev.system};
    in
      fenix'.overlays.default;
  });
}
