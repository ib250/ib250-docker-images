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
    lib.images = builtins.attrNames (import ./default.nix);

    packages = eachSystem (system: {
      buildImage = with import nixpkgs {inherit system;};
        writeScriptBin "build-image" ''
          set -eou pipefail
          docker buildx build --platform linux/amd64 . "$@"
        '';

      buildAndPushNixBasicImage = with import nixpkgs {inherit system;};
        writeScriptBin "build.nix-basic" ''
          ${self.packages.${system}.buildImage}/bin/build-image \
            -t $REPO/nix-basic:latest -f nix-basic.Dockerfile
        '';

      buildAndPushAllImages = with import nixpkgs {inherit system;}; let
        buildImageCommand = image: ''
          ${self.packages.${system}.buildImage}/bin/build-image \
            --build-arg ATTR=${image} -t $REPO/${image}:latest \
            --push

        '';

        commands = map buildImageCommand self.lib.images;
      in
        writeScriptBin "build-and-push-all" ''
          set -eoux pipefail

          ${self.packages.${system}.buildAndPushNixBasicImage}/bin/build.nix-basic

          ${builtins.concatStringsSep "\n" commands}
        '';
    });

    devShells = eachSystem (system: {
      default = with nixpkgs.legacyPackages.${system};
      with self.packages.${system};
        mkShell {
          nativeBuildInputs = [buildAndPushNixBasicImage buildImage buildAndPushAllImages];
          REPO = "docker.io/ismailbello513";

          shellHook = let
            mkBuildImageAlias = image:
              with self.packages.${system}; ''
                alias build.${image}='${buildImage}/bin/build-image --build-arg "ATTR=${image}" -t $REPO/${image}:latest'
              '';

            aliases = map mkBuildImageAlias self.lib.images;
          in
            builtins.concatStringsSep "\n" aliases;
        };
    });
  };
}
