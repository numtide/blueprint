{
  pkgs,
  flake,
  ...

}:

pkgs.runCommand "repro" {
  passthru.tests.repro = import ../checks/nixos-test.nix {
    inherit pkgs flake;
  };
} ''
  touch $out
''

