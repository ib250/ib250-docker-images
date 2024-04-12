{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";

    neovim-flake.url = "github:ib250/neovim-flake/switch-to-kickstart";
    neovim-flake.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    fenix,
    neovim-flake,
    ...
  }: let
    systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];
    eachSystem = nixpkgs.lib.genAttrs systems;
  in {
    lib.images = builtins.attrNames (import ./default.nix {
      # TODO: a little hacky, find a better way
      pkgs = {};
      fenix = {};
      neovim-flake = {};
    });

    packages = eachSystem (system: let
      pkgs = import nixpkgs {inherit system;};

      buildImage = pkgs.writeScriptBin "build-image" ''
        set -eou pipefail
        docker buildx build --platform $DOCKER_BUILD_PLATFORM . "$@"
      '';

      buildImages' = map (image: ''
        ${self.packages.${system}.buildImage}/bin/build-image \
          --build-arg ATTR=${image} -t $REPO/${image}:latest \
          --push
      '');

      buildAndPushAllImages = pkgs.writeScriptBin "build-and-push-all" ''
        set -eoux pipefail
        ${builtins.concatStringsSep "\n" (buildImages' self.lib.images)}
      '';
    in
      {
        inherit
          buildImage
          buildAndPushAllImages
          ;
      }
      // (pkgs.callPackages ./default.nix {
        fenix = fenix.packages.${system};
        neovim-flake = neovim-flake.packages.${system}.default;
      }));

    devShells = eachSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      self-pkgs = self.packages.${system};
    in {
      default = let
        mkBuildImage' = image:
          with self-pkgs;
            pkgs.writeScriptBin "build.${image}" ''
              ${buildImage}/bin/build-image --build-arg "ATTR=${image}" -t $REPO/${image}:latest "$@"
            '';
      in
        pkgs.mkShell {
          nativeBuildInputs = with self-pkgs;
            [
              buildImage
              buildAndPushAllImages
            ]
            ++ (map mkBuildImage' self.lib.images);

          REPO = "docker.io/ismailbello513";
          DOCKER_BUILD_PLATFORM = "linux/amd64";
        };
    });
  };
}
