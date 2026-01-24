{ inputs, pkgs, ... }:
let
  pre-commit-check = import ./checks/pre-commit-check.nix { inherit inputs pkgs; };
in
pkgs.mkShell {
  # Add build dependencies
  packages = [ ];

  # Add environment variables
  env = { };

  shellHook = ''
    ${pre-commit-check.shellHook}

    # Load custom bash code
  '';
}
