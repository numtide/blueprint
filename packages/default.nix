{
  pkgs,
  flake,
  system,
  ...
}:

pkgs.testers.runNixOSTest (
  { lib, ... }:
  {
    name = "nixos-test";

    nodes.machine =
      { pkgs, ... }:
      {
        imports = [ flake.nixosModules.unrepro ];

        environment.systemPackages = [
          (pkgs.writeShellScriptBin "hello2" ''
            exec ${lib.getExe flake.packages.${system}.hello}
          '')
        ];
      };

    testScript = _: ''
      machine.succeed("hello")
      machine.succeed("hello2")
    '';
  }
)
