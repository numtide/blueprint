{
  pkgs,
  perSystem,
  ...
}:
pkgs.stdenvNoCC.mkDerivation {
  name = "docs";

  unpackPhase = ''
    cp ${../../mkdocs.yml} mkdocs.yaml
    cp -r ${../../docs} docs
  '';

  nativeBuildInputs = with pkgs.python3Packages; [
    mike
    mkdocs
    mkdocs-material
    mkdocs-awesome-pages-plugin
  ];

  buildPhase = ''
    mkdocs build
  '';

  installPhase = ''
    mv site $out
  '';
}
