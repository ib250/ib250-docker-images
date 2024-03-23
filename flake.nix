{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];
    eachSystem = nixpkgs.lib.genAttrs systems;
  in {
    packages = eachSystem (system: {
      buildImage = with import nixpkgs {inherit system;};
        writeScriptBin "build-image" ''
          docker buildx create --use --name node-amd64 2>/dev/null
          docker buildx create --append --name node-arm64

          set -eou pipefail
          docker buildx build --platform linux/amd64,linux/arm64 . "$@"
        '';
    });

    devShells = eachSystem (system: {
      default = nixpkgs.legacyPackages.${system}.mkShell {
        nativeBuildInputs = [self.packages.${system}.buildImage];
      };
    });
  };
}
