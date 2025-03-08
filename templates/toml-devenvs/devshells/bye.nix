{ perSystem, ... }:
perSystem.devshell.mkShell {
  imports = [ (perSystem.devshell.importTOML ./bye.toml) ];
  devshell.packages = [ perSystem.self.bye ];
}
