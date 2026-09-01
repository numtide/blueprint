{ pkgs, ... }:
{

  programs.vim.enable = true;

  # you can check if host is darwin by using pkgs.stdenv.hostPlatform.isDarwin
  environment.systemPackages = [
    pkgs.btop
  ] ++ (pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.xbar ]);
}
