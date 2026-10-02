{
  description = "Location log ingest endpoint — location.jamesst.one";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  outputs =
    inputs:
    let
      eachSystem = inputs.nixpkgs.lib.genAttrs (import inputs.systems);

      pkgsFor = eachSystem (system: import inputs.nixpkgs { inherit system; });
    in
    {
      # `packages.<system>.default` is the HTTP server itself, not a directory
      # of assets: it keeps the log on disk, so it has to be running.
      #   services.caddy.virtualHosts."location.jamesst.one".extraConfig = ''
      #     reverse_proxy hermanii:3003
      #   '';
      packages = eachSystem (system: {
        default = pkgsFor.${system}.callPackage ./default.nix { };
      });

      nixosModules = rec {
        location = import ./nix/module.nix inputs.self;
        default = location;
      };

      checks = eachSystem (system: {
        build = inputs.self.packages.${system}.default;
        unit = pkgsFor.${system}.callPackage ./unit-tests.nix { };
        integration = pkgsFor.${system}.callPackage ./integration-check.nix {
          location = inputs.self.packages.${system}.default;
        };
      });

      devShells = eachSystem (system: {
        default = pkgsFor.${system}.mkShell {
          packages = [ pkgsFor.${system}.bun ];
        };
      });
    };
}
