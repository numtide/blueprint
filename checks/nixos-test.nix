{
  pkgs,
  flake,
  ...
}:

pkgs.testers.runNixOSTest (_: {
  name = "nixos-test";
  nodes.machine = _: {
    imports = [
      flake.nixosModules.repro
    ];
  };

  testScript = _: ''
    machine.succeed("echo repro")
  '';
})
