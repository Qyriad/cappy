{
	pkgs ? import <nixpkgs> { },
	python3Packages ? pkgs.python3Packages,
}:

let
	inherit (pkgs) lib;
	cappy = python3Packages.callPackage ./package.nix { };

	foldToList = list: f: lib.foldl' f [ ] list;
	# Fold to a list of name-value pairs, and then lib.listToAttrs it.
	foldToListToAttrs = list: f: (lib.listToAttrs (foldToList list f));

	# Some entries in `pkgs.pythonInterpreters` like `pypy39_prebuilt`,
	# are not disabled derivations or even attrsets, merely bare `throw`s.
	isValidPython = pyAttr: python: let
		res = builtins.tryEval (lib.isDerivation python && python.isPy3);
		hasScope = lib.hasAttr "${pyAttr}Packages" pkgs;
	in if res.success then res.value && hasScope else false;

	# List of attr-pairs
	validPythons = lib.pipe pkgs.pythonInterpreters [
		(lib.filterAttrs isValidPython)
		(lib.mapAttrsToList (pyAttr: python: {
			inherit pyAttr python;
		}))
	];

	byPythonVersion = foldToListToAttrs validPythons (acc: { pyAttr, python }: let
		pyScope = pkgs."${pyAttr}Packages";
		cappyForPython = pyScope.callPackage cappy.override { };
		notDisabled = !cappyForPython.meta.disabled;
	in acc ++ lib.optional notDisabled {
		name = pyAttr;
		value = cappyForPython;
	});

in cappy.overrideAttrs (prev: lib.recursiveUpdate prev {
	passthru = prev.passthru or { } // {
		inherit byPythonVersion;
	};
})
