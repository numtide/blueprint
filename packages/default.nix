{ pkgs, ... }:

pkgs.testers.runNixOSTest (
  { ... }:
  {
    name = "nixos-test";

    nodes.machine =
      { pkgs, ... }:
      {
        imports = [
          (
            { ... }:

            {
              config =
                # mysteriously broken:
                pkgs.lib.mkIf true { };

              # works:
              # lib.mkIf true { };
            }
          )
        ];
      };

    testScript = _: '''';
  }
)
