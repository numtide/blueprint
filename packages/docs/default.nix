{
  pkgs,
  perSystem,
  inputs,
  ...
}:
let
  libReference = pkgs.runCommandLocal "lib-reference" { nativeBuildInputs = [ pkgs.nixdoc ]; } ''
    mkdir $out
    nixdoc --category lib \
           --description "Blueprint public library functions" \
           --file ${../../lib/default.nix} \
           --prefix "" \
           --anchor-prefix "" \
           > $out/lib_reference.md
  '';
in
pkgs.stdenvNoCC.mkDerivation {
  name = "docs";

  unpackPhase = ''
    cp -r ${../../docs} docs
    chmod -R +w docs
    cp ${../../mkdocs.yml} mkdocs.yaml
    mkdir -p docs/content/reference
    cp ${libReference}/lib_reference.md docs/content/reference/lib_reference.md
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
