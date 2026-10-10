{
    description = "Optional development shell for template-ada";

    inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    outputs =
        { nixpkgs, ... }:
        let
            # Alire's prebuilt GNAT/SPARK toolchains used here target x86_64 Linux.
            system = "x86_64-linux";
            pkgs = import nixpkgs { inherit system; };
            # Run downloaded binaries with FHS paths, glibc headers/libraries and
            # GMP for SPARK, without changing the user's interactive shell.
            alire = pkgs.buildFHSEnv {
                name = "alr";
                targetPkgs = p: [
                    p.alire
                    p.git
                    p.prek
                    p.curl
                    p.cacert
                    p.unzip
                    p.zip
                    p.gnumake
                    p.gcc
                    p.binutils
                    p.glibc
                    p.glibc.dev
                    p.gmp
                    p.zlib
                    p.zstd
                ];
                runScript = pkgs.lib.getExe pkgs.alire;
            };
        in
        {
            devShells.${system}.default = pkgs.mkShellNoCC {
                packages = [
                    pkgs.git
                    pkgs.prek
                    alire
                ];
            };
        };
}
