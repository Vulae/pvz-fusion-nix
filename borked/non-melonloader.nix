# This only works on the non-melon loader version.
# Probably the cleaner version, but cannot be used because melonloader kinda sucks and wants to do all crazy stuff that you cannot control.
# To use this, either remove WINEDLLOVERRIDES below, or disable melonloader with arg --no-mods
{
    description = "Plants vs. Zombies Fusion with english translations";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = { self, nixpkgs, flake-utils }:
        flake-utils.lib.eachDefaultSystem (system:
            let
                pkgs = import nixpkgs { inherit system; };

                gameVersion = "3.8.1";
                gameHash = "sha256-0TMp3Ae5t9UbU+DlSFN7WAgNIpTLs3NJXw6A+RiOPKA=";

                # The game has some file paths thats mandarin, and `pkgs.fetchzip` doesn't like that.
                winAppZip = pkgs.fetchurl {
                    url = "https://github.com/Teyliu/PVZF-Translation/releases/download/${gameVersion}_beta/PvZ.Fusion.${gameVersion}.Multi-lang.Beta.by.Blooms.zip";
                    sha256 = gameHash;
                };
                winAppDir = "Game Files";
                winAppExe = "Game Files/PlantsVsZombiesRH.exe";

                pname = "PlantsVsZombiesFusion";

                app = pkgs.stdenv.mkDerivation {
                    pname = pname;
                    version = gameVersion;

                    dontUnpack = true;

                    nativeBuildInputs = [
                        pkgs.p7zip
                        pkgs.makeWrapper
                    ];

                    installPhase = ''
                        runHook preInstall

                        7z x -y -o"$out/opt" "${winAppZip}"
                        chmod -R u+w "$out/opt"

                        mkdir -p "$out/bin"
                        makeWrapper ${pkgs.wineWow64Packages.stable}/bin/wine "$out/bin/${pname}" \
                            --run 'mkdir -p "$HOME/.local/share/PVZF/wine"' \
                            --run 'export WINEPREFIX="$HOME/.local/share/PVZF/wine"' \
                            --run 'export WINEDEBUG="fixme-all"' \
                            --run 'export WINEDLLOVERRIDES="version=n,b"' \
                            --run 'export USER="wineuser"' \
                            --set WINEARCH "win64" \
                            --add-flags "'$out/opt/${winAppExe}'" \
                            --run "cd '$out/opt/${winAppDir}'"

                        runHook postInstall
                    '';
                };
            in
            {
                packages.default = app;
            }
        );
}
