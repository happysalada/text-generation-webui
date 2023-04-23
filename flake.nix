{
  description = "Application packaged using poetry2nix";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.poetry2nix = {
    url = "github:happysalada/poetry2nix/add_overrides";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # see https://github.com/nix-community/poetry2nix/tree/master#api for more functions and examples.
        inherit (poetry2nix.legacyPackages.${system}) mkPoetryApplication defaultPoetryOverrides;
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = {
          myapp = mkPoetryApplication {
            projectDir = self;
            overrides = defaultPoetryOverrides.extend (self: super: {
              # attrs = super.attrs.overridePythonAttrs (old: {
              #   nativeBuildInputs = (old.nativeBuildInputs or [ ])
              #     ++ [
              #       self.hatchling
              #       self.hatch-fancy-pypi-readme
              #       self.hatch-vcs
              #     ];
              # });
              # bitsandbytes = super.bitsandbytes.overridePythonAttrs (old: {
              #   propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [
              #     self.setuptools
              #   ];
              # });
              cmake = super.cmake.overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                  pkgs.cmake
                ];
                buildInputs = (old.buildInputs or [ ]) ++ [
                  self.scikit-build
                ];
              });
              # ffmpy = super.ffmpy.overridePythonAttrs (old: {
              #   propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [
              #     self.setuptools
              #   ];
              # });
              llama-cpp-python = super.llama-cpp-python.overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                  pkgs.cmake
                ];
                buildInputs = (old.buildInputs or [ ]) ++ [
                  self.scikit-build
                ];
              });
              # pillow = super.pillow.overridePythonAttrs (old: {
              #   propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [
              #     pkgs.zlib
              #   ];
              # });
              tokenizers = super.tokenizers.overridePythonAttrs (old: {
                nativeBuildInputs = with pkgs.rustPlatform; (old.nativeBuildInputs or [ ] ++ [
                  rust.rustc
                  rust.cargo
                  self.setuptools-rust
                ]);
              });
              safetensors = 
              let
                getCargoHash = version: {
                }.${version} or (
                  self.lib.warn "Unknown safetensors version: '${version}'. Please update getCargoHash." self.lib.fakeHash
                );
              in
              super.safetensors.overridePythonAttrs (old: {
                cargoDeps = pkgs.rustPlatform.fetchCargoTarball {
                  inherit (old) src;
                  name = "${old.pname}-${old.version}";
                  hash = getCargoHash old.version;
                };
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                  pkgs.rustPlatform.cargoSetupHook
                ];
                # buildInputs = (old.buildInputs or [ ]) ++ lib.optional pkgs.stdenv.isDarwin pkgs.libiconv;
              });
            });
          };
          default = self.packages.${system}.myapp;
        };

        devShells.default = pkgs.mkShell {
          packages = [ poetry2nix.packages.${system}.poetry ];
        };
      });
}
