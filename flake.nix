{
  description =
    "The simplest, fastest repository for training/finetuning medium-sized GPTs.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";

    utils.url = "github:numtide/flake-utils";

    ml-pkgs.url = "github:katanallama/ml-pkgs";
    # ml-pkgs.url = "path:/home/bh/projects/ml-pkgs"; # for testing

    ml-pkgs.inputs.nixpkgs.follows = "nixpkgs";
    ml-pkgs.inputs.utils.follows = "utils";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    {
      overlays.dev = nixpkgs.lib.composeManyExtensions [
        inputs.ml-pkgs.overlays.torch-family
        inputs.ml-pkgs.overlays.misc
      ];
    } // inputs.utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ self.overlays.dev ];
        };
      in {
        devShells.default = let
          python-env = pkgs.python3.withPackages (pyPkgs:
            with pyPkgs; [
              numpy
              pandas
              pytorchWithCuda11
              huggingface-transformers
              wandb
              tqdm
              datasets
              blobfile
              tiktoken
            ]);

          name = "nanoGPT";
        in pkgs.mkShell {
          inherit name;

          packages = [ python-env ];

          shellHooks = let pythonIcon = "f3e2";
          in ''
            export PS1="$(echo -e '\u${pythonIcon}') {\[$(tput sgr0)\]\[\033[38;5;228m\]\w\[$(tput sgr0)\]\[\033[38;5;15m\]} (${name}) \\$ \[$(tput sgr0)\]"
          '';
        };
      });
}
