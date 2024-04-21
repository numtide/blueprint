{
  pname,
  pkgs,
  self,
  ...
}:
let
  pb = pkgs.writeShellApplication {
    name = pname;
    runtimeInputs = [

    ];

    text = ''
      set -euo pipefail

      case "''${1:-}" in
        "switch")
          shift
          # Allow running the command as a user
          export SUDO_USER=1
          echo ${pkgs.nixos-rebuild}/bin/nixos-rebuild --flake ${self} "$@"
          ;;
        *)
          echo "Usage: ${pname} [switch]"
          ;;
      esac
    '';

    meta = {
      description = "ignore me, this is not ready";

      tests.does-it-run = pkgs.runCommand "${pname}-does-it-run" { } ''
        ${pb}/bin/bp --help > $out
      '';
    };
  };
in
pb
