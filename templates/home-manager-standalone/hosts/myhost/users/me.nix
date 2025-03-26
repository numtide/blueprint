{ perSystem, ... }:
{
  home.stateVersion = "24.11";

  home.packages = [ perSystem.blueprint.docs ];
}
