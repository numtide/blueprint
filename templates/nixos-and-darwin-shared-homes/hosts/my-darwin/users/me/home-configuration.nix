{
  pkgs,
  inputs,
  hostConfig,
  ...
}:
{

  imports = [ inputs.self.homeModules.home-shared ];
}
