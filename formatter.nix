{
  pkgs,
  system,
  inputs,
  ...
}:
inputs.treefmt-nix.lib.mkWrapper pkgs {
  projectRootFile = ".git/config";

  programs = {
    nixfmt-rfc-style.enable = true;
    prettier.enable = true;
  };

  settings.formatter.prettier = {
    options = [
      "--tab-width"
      "4"
    ];
    includes = [
      "*.css"
      "*.html"
      "*.js"
      "*.json"
      "*.jsx"
      "*.md"
      "*.mdx"
      "*.scss"
      "*.ts"
      "*.yaml"
    ];
  };
}
