{ pkgs, inputs, ... }:
{

  imports = [ inputs.self.nixosModules.host-shared ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.me.home = /Users/me;

  system.stateVersion = 6; # initial nix-darwin state
}
