{
  description = "Packages and dev Shell for the btw-quizz Website";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      with builtins;
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
        parseProgramFile = path: 
          let
            repeat = element: n: if n <= 0 then [] else [element] ++ (repeat element (n - 1));
            withArticles = name: [
              "Die ${name}"
              "die ${name}"
              "Das ${name}"
              "das ${name}"
              name
            ];
            content = readFile path;
            lines = lib.splitString "\n" content;
            metadata = lines
              |> head
              |> fromJSON
              ;
            phrases = tail lines
              |> map (l: lib.trim l)
              |> filter (l: l != "" && ! lib.hasPrefix "# " l)
              |> map (replaceStrings (withArticles metadata.party) (repeat "[Parteiname]" 5))
              ;
          in
            metadata // { inherit phrases;};
      in
      {
        packages =
            let
              version = "0.0.1-vue-beta";
            in
           rec {
          default = btw-quizz;
          data = pkgs.writeText "data.json" (lib.filesystem.listFilesRecursive ./resources
            |> map parseProgramFile
            |> toJSON
          );
          srcWithData = pkgs.stdenv.mkDerivation {
            pname = "quizz-src";
            inherit version;
            src = ./.; 
            installPhase = ''
              mkdir -p $out/public
              cp -r $src/* $out
              cp ${data} $out/public/data.json
            '';
          };
          btw-quizz = pkgs.buildNpmPackage rec {
            pname = "btw-quizz";
            inherit version;
            src = srcWithData;
            npmDepsHash = "sha256-JxBrO7BSif/9sqzCYEPSnUi8/kWzUw+V41ygetvm0vs=";
            installPhase = ''
              mkdir -p $out
              cp -r dist/* $out
            '';
          };

        };

        devShell = pkgs.mkShell
          {
            nativeBuildInputs = with pkgs; [
              nodejs
              (vscode-with-extensions.override {
                vscodeExtensions = with pkgs.vscode-extensions; [
                  jnoortheen.nix-ide
                  vue.volar
                ];
                vscode = vscodium;
              })

            ];
          };
      }
    );
}
