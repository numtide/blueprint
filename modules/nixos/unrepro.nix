# handled by injectPublisherArgs
{
  flake,

  # throws an error; there might be a bug with this
  # perSystem,
  ...
}:

# this is the module that in the real scenario lives outside of the `runTest` caller code
{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [ flake.inputs.extra-container.nixosModules.default ];
  config =

    # (mysteriously) broken:
    # pkgs.lib.mkIf true {

    # works:
    lib.mkIf true {
      environment.systemPackages = [
        # perSystem.self.packages.hello
        flake.packages.${pkgs.stdenv.system}.hello
      ];
    };
}
