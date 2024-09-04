{ pkgs }:
pkgs.mkShell {
  # Add build dependencies
  packages = [ ];

  # Add environment variables
  env = { };

  # Load custom bash code
  shellHook = ''

  '';
}
