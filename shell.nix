{
	pkgs ? import <nixpkgs> { },
	cappy ? import ./default.nix { inherit pkgs; },
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
