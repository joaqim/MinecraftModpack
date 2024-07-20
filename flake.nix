{
  description = "FabricModpack";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    packwiz2nix = {
      url = "github:getchoo/packwiz2nix/rewrite";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, systems, packwiz2nix, self, ... }: flake-parts.lib.mkFlake { inherit inputs; } ({ moduleWithSystem, ... }: {
    systems = import systems;

    perSystem = { system, pkgs, config, lib, ... }: {
      _module.args = {
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            (import ./nix/overlay.nix)
          ];
        };
      };

      packages =
        let
          packwiz2nixLib = inputs.packwiz2nix.lib.${system};

          #These builds expects *Double Invocation*
          # Without proper hash, the first build _will_ fail. 
          # The failed result will tell you the expected `hash` to assign below.
          # When you've set the hash, the next build will return with a `/nix/store` entry of the results, 
          # symlinked as `./result`.

          packwiz-pack-hash = null;
          modrinth-pack-hash = "sha256-+9NpIatjjbJ/5/+hHoSNdoKwA0Ive/jFafwXYF/IQ2Y=";
        in
        {
          
          packwiz-server = packwiz2nixLib.fetchPackwizModpack {
            manifest = "${self}/pack.toml";
            hash = packwiz-pack-hash;
            side = "server";
          };

          modrinth-pack = pkgs.callPackage ./nix/packwiz-modrinth.nix {
            src = self;
            hash = modrinth-pack-hash;
          };

          # Not used for anything right now
          # packwiz-client = packwiz2nixLib.fetchPackwizModpack {
          #   manifest = "${self}/pack.toml";
          #   hash = "sha256-cd3NdmkO3yaLljNzO6/MR4Aj7+v1ZBVcxtL2RoJB5W8=";
          #   side = "client";
          # };
        };

      checks = config.packages;
    };
  });
}
