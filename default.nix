{
	pkgs ? import <nixpkgs> { },
	python3Packages ? pkgs.python3Packages,
}:

let
	inherit (pkgs) lib;
	cappy = python3Packages.callPackage ./package.nix { };

	foldToList = list: f: lib.foldl' f [ ] list;
	pipeNullable = lib.foldl' (value: f: lib.mapNullable f value);
	maybeGetAttrFrom = attrset: name: attrset."${name}" or null;
	append = appendage: base: base + appendage;

	pyAttrOrNull = python: let
		res = builtins.tryEval (python.pythonAttr or null);
	in if res.success then res.value else null;

	pyInterpreters = lib.attrValues pkgs.pythonInterpreters;

	optionalValidPython = python: let
		pyAttr = pyAttrOrNull python;
		isPy3 = python.isPy3 or false;
		scope = pipeNullable pyAttr [
			(append "Packages") # python312 -> python312Packages
			(maybeGetAttrFrom pkgs) # python312Packages -> pkgs.python312Packages
		];
		isValid = scope != null && isPy3;
	in lib.optional isValid {
		name = scope.python.pythonAttr;
		value = scope.callPackage ./package.nix { };
	};

	byPythonVersion = let
		listOfCappyPairs = foldToList pyInterpreters (acc: python: acc ++ optionalValidPython python);
		nonDisabledCappyPairs = lib.filter ({ name, value }: !value.meta.disabled) listOfCappyPairs;
	in lib.listToAttrs nonDisabledCappyPairs;

in cappy.overrideAttrs (prev: {
	passthru = lib.recursiveUpdate (prev.passthru or { }) {
		inherit byPythonVersion;
	};
})

