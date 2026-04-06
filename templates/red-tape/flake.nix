{
  description = "Flake using red-tape's mkFlake via blueprint";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";

    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Use the richer red-tape mkFlake, re-exported by blueprint.
  # It is built on the adios-flake module system, giving you
  # composable contrib modules for home-manager, nix-darwin, etc.
  outputs = inputs: inputs.blueprint.mkFlake { inherit inputs; src = ./.; };
}
