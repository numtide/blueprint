{
  nixos-rebuild,
  runCommand,
  writeShellApplication,
}:
let
  pb = writeShellApplication {
    name = "bp";
    runtimeInputs = [

    ];

    text = ''
      set -euo pipefail

      case "''${1:-}" in
        "switch")
          shift
          # Allow running the command as a user
          export SUDO_USER=1
          echo ${nixos-rebuild}/bin/nixos-rebuild --flake . switch "$@"
          ;;
        *)
          echo "Usage: bp [switch]"
          ;;
      esac
    '';

    meta = {
      description = "ignore me, this is not ready";

      tests.does-it-run = runCommand "bp-does-it-run" { } ''
        ${pb}/bin/bp --help > $out
      '';
    };
  };
in
pb
