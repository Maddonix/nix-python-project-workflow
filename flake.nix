{
  description = "Application packaged using poetry2nix";
  inputs = {
    # flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ##### ADD EXTERNAL DATA AS INPUTS #####
    # Necesarry to link files in shellHook
    tennis-data = {
      url = "github:JeffSackmann/tennis_atp";
      flake = false;
    };
    #######################################

  };



  outputs = { self, nixpkgs, flake-utils, poetry2nix, tennis-data }:
    # flake-utils.lib.eachDefaultSystem (system:
    let
        system = "x86_64-linux";
        # see https://github.com/nix-community/poetry2nix/tree/master#api for more functions and examples.
        pkgs = nixpkgs.legacyPackages.${system};
        
        _poetry2nix = poetry2nix.lib.mkPoetry2Nix { inherit pkgs; };

    in
      let 
        env = _poetry2nix.mkPoetryEnv {
          projectDir = ./.;

          overrides = _poetry2nix.defaultPoetryOverrides.extend
            (self: super: {
              pandas = super.pandas.overridePythonAttrs
              (
                old: {
                  buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                }
              );
          });

        };
      in
        {

          # Call with nix develop
          devShell."${system}" = pkgs.mkShell {
            buildInputs = [ 
              env
              pkgs.poetry

              # Make venv (not very nixy but easy workaround to use current non-nix-packaged python module)
              pkgs.python3Packages.venvShellHook
            ];

            # Define Environment Variables
            TEST_VAR = "test";

            # Setup external datasources
            # shellHook = ''
            # '';

            # Define Python venv
            venvDir = ".venv";
            postShellHook = ''
              mkdir -p data
              ln -snf ${tennis-data}/atp_matches_2020.csv data/dataset.csv

              pip install --upgrade pip
              pip install opencv-python -U
              pip install django -U
              pip install django-bootstrap5 -U
            '';
          };


        # });
        };
}
