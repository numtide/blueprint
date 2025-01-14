{ pkgs, flake, ... }:

pkgs.testers.runNixOSTest (_: {
  name = "nixos-test";
  nodes.machine = _: {
    imports = [
      (
        { pkgs, lib, ... }:

        {
          config =
            # mysteriously broken:
            # pkgs.lib.mkIf true { }

            # works:
            lib.mkIf true { };
        }
      )
    ];
  };

  testScript = _: '''';
})
