{
  description = "flakes made easy";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/triplet";
  };

  outputs =
    inputs:
    let
      # Use self to create self
      blueprint = import ./lib { inherit inputs; };
    in
    blueprint { inherit inputs; };
}
