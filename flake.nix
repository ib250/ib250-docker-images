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
            contents = [
              usrBinEnv
              binSh
              pkgs.duckdb
              pkgs.duckdb.dev
              (
                pkgs.runCommand "duckdb-extensions" {} ''
                  mkdir -p $out
                  ${pkgs.duckdb}/bin/duckdb -c "
                    set extension_directory = '$out';
                    install postgres;
                    install sqlite;
                  "
                ''
              )
            ];
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
                let
                  allImages = builtins.attrNames packages.${nix-system};
                in
                pkgs.writeShellScriptBin "build-images.${nix-system}"
                  ''
                    set -eo pipefail

                    if ! type -p docker > /dev/null
                    then
                      echo 'Install docker in the host outside flake'
                      exit 1
                    fi


                    DRYRUN=0
                    targets_=
                    while (( $# > 0 ))
                    do
                      case $1 in
                        -n | --dry-run )
                          DRYRUN=1
                          shift
                          ;;
                        -a | --all )
                          targets_=${builtins.concatStringsSep ":" allImages}
                          shift
                          ;;
                        ${builtins.concatStringsSep " | " allImages} )
                          targets_="$targets_:$1"
                          shift
                          ;;
                        * )
                          echo "Unrecognised image, must be one of:" ${builtins.toString allImages}
                          exit 1
                          ;;
                      esac
                    done

                    mkdir -p dist/${docker-arch}
                    export DEFAULT_DOCKER_PLATFORM=${docker-arch}

                    DRYRUN_CMD=
                    if [[ "$DRYRUN" -eq "1" ]]
                    then
                      DRYRUN_CMD=echo
                    fi

                    docker run \
                      -it \
                      --rm \
                      -v ismailbello513-${nix-system}:/nix \
                      -v $(pwd):/work \
                      -w /work \
                      -e out_link_path=dist/${docker-arch} \
                      -e DRYRUN=$DRYRUN \
                      -e TARGETS="$targets_" \
                      nixos/nix:latest \
                      /work/build.sh

                    for img in dist/${docker-arch}/*.tar.gz
                    do
                      $DRYRUN_CMD docker load < $img
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
