{ pkgs, osConfig, ... }:
{

  # only available on linux, disabled on macos
  services.ssh-agent.enable = pkgs.stdenv.hostPlatform.isLinux;

  home.packages =
    [ pkgs.ripgrep ]
    ++ (
      # you can access the host configuration using osConfig.
      pkgs.lib.optionals (osConfig.programs.vim.enable && pkgs.stdenv.hostPlatform.isDarwin) [ pkgs.skhd ]
    );

  home.stateVersion = "24.11"; # initial home-manager state
}
