This template shows how you can define and reuse nixos and home-manager modules.


This flake defines two hosts `my-darwin` and `my-nixos`, both importing a
shared `modules/nixos/host-shared.nix` module between them.


Also, both hosts define a `me` user and their home-managed configuration
simply imports `modules/homes/home-shared.nix`.


The idea is you can use this example to get started on how to share
configurations between different system and home environments on different
hosts.