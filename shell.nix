{
  inputs,
  pkgs,
}: let
in
  pkgs.mkShell {
    buildInputs = with pkgs; [
      elmPackages.elm
      elmPackages.elm-test
      elmPackages.elm-format
      elmPackages.elm-language-server
    ];
    shellHook = ''
    '';
  }
