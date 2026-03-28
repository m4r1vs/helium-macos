{
  description = "Nix development flake for the helium browser";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs = {nixpkgs, ...}: let
    lib = nixpkgs.lib;
    supportedSystems = [
      "aarch64-darwin"
    ];
    forAllSystems = lib.genAttrs supportedSystems;
  in {
    devShell = forAllSystems (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
        with pkgs;
          mkShellNoCC {
            buildInputs = [
              coreutils-prefixed
              ninja
              quilt
              readline
              (python313.withPackages (python-pkgs: [
                (python-pkgs.httplib2.overridePythonAttrs (old: {
                  dependencies = (old.dependencies or []) ++ [python-pkgs.pysocks];
                  postInstall =
                    (old.postInstall or "")
                    + # bash
                    ''
                            # Find where the site-packages for this specific package are
                            SITE_PACKAGES=$out/lib/python3.13/site-packages/httplib2
                            mkdir -p $SITE_PACKAGES

                            # Create the bridge that gerrit_util.py expects
                            echo "try:
                          import socks
                      except ImportError:
                          pass
                      else:
                          from socks import *" > $SITE_PACKAGES/socks.py
                    '';
                }))
                python-pkgs.requests
                python-pkgs.pillow
              ]))
            ];
          }
    );
  };
}
