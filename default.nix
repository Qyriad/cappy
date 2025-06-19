{
	pkgs ? import <nixpkgs> { },
	python3Packages ? pkgs.python3Packages,
	qpkgs ? let
		src = fetchTarball "https://github.com/Qyriad/nur-packages/archive/main.tar.gz";
	in import src { inherit pkgs; },
}:

let
	inherit (pkgs) lib;
	cappy = python3Packages.callPackage ./package.nix { };

	byPythonVersion = qpkgs.pythonScopes
	|> lib.mapAttrs (_: pyScope: pyScope.callPackage cappy.override { })
	|> lib.filterAttrs (_: cappy': !cappy'.meta.disabled);

in cappy.overrideAttrs (prev: lib.recursiveUpdate prev {
	passthru = prev.passthru or { } // {
		inherit byPythonVersion;
	};
})
