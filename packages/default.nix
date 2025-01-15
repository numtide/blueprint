{ pkgs, flake, ... }:

let
  lib = pkgs.lib;
  nixos = import (lib.path.append pkgs.path "nixos/lib") { inherit lib; };
in
nixos.runTest (
  /*
    TODO: what are these arguments? if i put pkgs in here i'm getting:

    error: infinite recursion encountered
    at /nix/store/cb1gs888vfqxawvc65q1dk6jzbayh3wz-source/lib/modules.nix:1016:24:
      1015|     { _type = "override";
      1016|       inherit priority content;
          |                        ^
      1017|     };
  */
  { ... }:
  {
    name = "nixos-test";

    defaults._module.args = {
      inherit flake;
    };

    nodes.machine =
      { ... }:
      {
        imports = [
          (
            # this is the module that in the real scenario lives outside of the `runTest` caller code
            { config, pkgs, lib, flake, ... }:

            {
              imports = [
                flake.inputs.extra-container.nixosModules.default
              ];
              config =
                # mysteriously broken:
                # pkgs.lib.mkIf true { };

              # works:
              lib.mkIf true { };
            }
          )
        ];
      };

    testScript = _: '''';
    hostPkgs = pkgs;
  }
)
