{
  description = "lean flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    inputs:
    let
      # use self to create self
      blueprint = import ./lib inputs;
    in
    blueprint { inherit inputs; };
}
