{
  description = "flakes made easy";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    red-tape.url = "github:phaer/red-tape";
  };

  outputs =
    inputs:
    let
      # Use self to create self
      blueprint = import ./lib { inherit inputs; };
    in
    blueprint { inherit inputs; }
    // {
      # Re-export red-tape's mkFlake so users can access it via inputs.blueprint.mkFlake
      inherit (inputs.red-tape) mkFlake;
    };
}
