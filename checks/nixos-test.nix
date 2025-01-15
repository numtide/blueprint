{ pkgs, flake, ... }:

let
  outerFlake = flake;
in

pkgs.testers.runNixOSTest (_: {
  name = "nixos-test";
  nodes.machine = _: {
    imports = [
      (
        { flake, pkgs, lib, ... }:

        {
          imports = [
            flake.inputs.extra-container.nixosModules.default

            # works:
            # outerFlake.inputs.extra-container.nixosModules.default
          ];

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
