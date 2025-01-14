{
  pkgs,
  flake,
  ...

}:

pkgs.stdenv.mkDerivation {
  phases = [];

  passthru.tests.repro = import ../checks/nixos-test.nix {
    inherit pkgs flake;
  };
}

