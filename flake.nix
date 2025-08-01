{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
		flake-utils.url = "github:numtide/flake-utils";
		qyriad-nur = {
			url = "github:Qyriad/nur-packages";
			flake = false;
		};
	};

	outputs = {
		self,
		nixpkgs,
		flake-utils,
		qyriad-nur,
	}: flake-utils.lib.eachDefaultSystem (system: let
		pkgs = import nixpkgs { inherit system; };
		qpkgs = import qyriad-nur { inherit pkgs; };
		inherit (pkgs) lib;

		cappy = import ./default.nix { inherit pkgs qpkgs; };

		# default.nix exposes cappy evaluated for multiple `pythonXPackages` sets,
		# so let's translate that to additional flake output attributes.
		extraVersions = lib.mapAttrs' (pyName: value: {
			name = "${pyName}-cappy";
			inherit value;
		}) cappy.byPythonVersion;

		devShell = import ./shell.nix { inherit pkgs qpkgs; };
		extraDevShells = lib.mapAttrs' (pyName: value: {
			name = "${pyName}-cappy";
			inherit value;
		}) devShell.byPythonVersion;

	in {
		packages = extraVersions // {
			default = cappy;
			inherit cappy;
		};

		devShells = extraDevShells // {
			default = devShell;
		};
	});
}
