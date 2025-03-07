{ pkgs, hostConfig, ... }:
{

  # only available on linux, disabled on macos
  services.ssh-agent.enable = pkgs.stdenv.isLinux;

  home.packages =
    [ pkgs.ripgrep ]
    ++ (
      # you can access the host configuration using hostConfig.
      pkgs.lib.optionals (hostConfig.programs.vim.enable && pkgs.stdenv.isDarwin) [ pkgs.skhd ]
    );

  home.stateVersion = "24.11"; # initial home-manager state
}
