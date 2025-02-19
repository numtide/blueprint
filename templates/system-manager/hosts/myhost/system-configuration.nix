{ pkgs, ... }:
{
  config = {
    nixpkgs.hostPlatform = "x86_64-linux";

    services.nginx.enable = true;

    environment = {
      systemPackages = [ pkgs.ripgrep ];
    };
  };
}
