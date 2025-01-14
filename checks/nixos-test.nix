{ pkgs, flake, ... }:

pkgs.testers.runNixOSTest (_: {
  name = "nixos-test";
  nodes.machine = _: {
    imports = [
      (
        { pkgs, ... }:

        {
          config = pkgs.lib.mkIf true { };
        }
      )
    ];
  };

  testScript = _: '''';
})
