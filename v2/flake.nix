{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";

    fenix.url = "github:nix-community/fenix";
    neovim-flake.url = "github:ib250/neovim-flake";
  };

  outputs =
    { self
    , fenix
    , neovim-flake
    , nixpkgs
    ,
    }:
    let
      systems = {
        "aarch64-darwin" = "linux/arm64/v8";
        "x86_64-linux" = "linux/amd64";
        "aarch64-linux" = "linux/arm64/v8";
      };

      eachSystem = gen:
        # f: { pkgs: <nixpkgs>; system: system } -> drv
        nixpkgs.lib.genAttrs (builtins.attrNames systems) (
          system:
          gen {
            inherit system;
            pkgs = import nixpkgs { inherit system; };
          }
        );

    in
    rec {
      packages = eachSystem ({ pkgs, system }:
        with pkgs.dockerTools;
        {
          goose = buildLayeredImage {
            name = "ismailbello513/goose";
            tag = "latest";
            created = "now";
            contents = [ usrBinEnv binSh pkgs.goose ];
          };

          duckdb = buildLayeredImage {
            name = "ismailbello513/duckdb";
            tag = "latest";
            created = "now";
            contents = [ usrBinEnv binSh pkgs.duckdb ];
          };

          fenix = buildLayeredImage {
            name = "ismailbello513/rust";
            tag = "latest";
            created = "now";
            contents = with fenix.packages.${system};
              [ usrBinEnv binSh complete.toolchain ];
          };

          golang = buildLayeredImage {
            name = "ismailbello513/golang";
            tag = "latest";
            created = "now";
            # go_1_23 controlled by flake inputs
            contents = [ usrBinEnv binSh pkgs.go ];
          };

          devtools = buildLayeredImage {
            name = "ismailbello513/devtools";
            tag = "latest";
            created = "now";
            contents = with neovim-flake.packages.${system};
              [
                usrBinEnv
                binSh
                caCertificates
                fakeNss
                pkgs.eza
                nvim-overlay-env
              ];
          };
        });

      formatter = eachSystem ({ pkgs, ... }: pkgs.nixpkgs-fmt);

      devShells = eachSystem ({ pkgs, ... }: {
        default = pkgs.mkShell {
          buildInputs =
            let
              mkDockerBuildScript = nix-system: docker-arch: (
                pkgs.writeShellScriptBin "build-images.${nix-system}"
                  ''
                    set -eou pipefail

                    if ! type -p docker > /dev/null
                    then
                      echo 'Install docker in the host outside flake'
                      exit 1
                    fi

                    mkdir -p dist/${docker-arch}
                    export DEFAULT_DOCKER_PLATFORM=${docker-arch}
                    docker run \
                      -it \
                      --rm \
                      -v ismailbello513-${nix-system}:/nix \
                      -v $(pwd):/work \
                      -w /work \
                      -e out_link_path=dist/${docker-arch} \
                      nixos/nix:latest \
                      /work/build.sh \
                      ${builtins.concatStringsSep " " (builtins.attrNames packages.${nix-system})}

                    for img in dist/${docker-arch}/*.tar.gz
                    do
                      docker load < $img
                    done
                  ''
              );

              builders = builtins.mapAttrs mkDockerBuildScript systems;
            in
            builtins.attrValues builders;
        };
      });

    };
}
