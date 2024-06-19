{
  nixos-rebuild,
  runCommand,
  writeShellApplication,
}:
let
  bp = writeShellApplication {
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
    };
  };
in
bp
// {
  # https://github.com/NixOS/nixpkgs/pull/320973
  passthru = bp.passthru // {
    tests = {
      does-it-run = runCommand "bp-does-it-run" { } ''
        ${bp}/bin/bp --help > $out
      '';
    };
  };
}
