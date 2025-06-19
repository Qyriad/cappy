{
	pkgs ? import <nixpkgs> { },
	qpkgs ? let
		src = fetchTarball "https://github.com/Qyriad/nur-packages/archive/main.tar.gz";
	in import src { inherit pkgs; },
	cappy ? import ./default.nix { inherit pkgs qpkgs; },
}: let
	inherit (pkgs) lib;

	mkDevShell = cappy: pkgs.callPackage cappy.mkDevShell { };
	devShell = mkDevShell cappy;
	byPythonVersion = lib.mapAttrs (lib.const mkDevShell) cappy.byPythonVersion;

in devShell.overrideAttrs (prev: {
	passthru = lib.recursiveUpdate (prev.passthru or { }) {
		inherit byPythonVersion;
	};
})
