{ pname, pkgs }:
let
  bp = pkgs.writeShellApplication {
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
          echo ${pkgs.nixos-rebuild}/bin/nixos-rebuild --flake . switch "$@"
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
      does-it-run = pkgs.runCommand "bp-does-it-run" { } ''
        ${bp}/bin/${pname} --help > $out
      '';
    };
  };
}
