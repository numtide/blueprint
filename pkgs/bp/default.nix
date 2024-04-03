{
  pname,
  pkgs,
  self,
  ...
}:
pkgs.writeShellApplication {
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
}
