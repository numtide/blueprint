{
  description = "my flake";

  # Add all your dependencies here
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Keep the magic invocations to minimum.
  outputs = inputs: inputs.blueprint { inherit inputs; };
}
