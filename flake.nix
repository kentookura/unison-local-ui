{
  description = "A very basic flake";

  outputs = {
    self,
    nixpkgs,
  } @ inputs: let
    pkgs = import inputs.nixpkgs {
      config.allowUnfree = true;
      system = "x86_64-linux";
    };
  in {
    devShells."x86_64-linux".default = import ./shell.nix {
      inherit inputs pkgs;
    };
  };
}
