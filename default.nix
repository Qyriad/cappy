{
	pkgs ? import <nixpkgs> { },
	qpkgs ? let
		src = fetchTarball "https://github.com/Qyriad/nur-packages/archive/main.tar.gz";
	in import src { inherit pkgs; },
}:

let
	inherit (pkgs) lib;
	cappy = qpkgs.callPackage ./package.nix { };
	cappyForPython = pyScope: cappy.override { python3Packages = pyScope; };

	byPythonVersion = qpkgs.pythonScopes
	|> lib.mapAttrs (_: pyScope: cappyForPython pyScope)
	|> lib.filterAttrs (_: cappy': !cappy'.meta.disabled);

in cappy.overrideAttrs (prev: lib.recursiveUpdate prev {
	passthru = prev.passthru or { } // {
		inherit byPythonVersion;
	};
})
