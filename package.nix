{
	lib,
	stdenvNoCC,
	python3Packages,
	pythonHooks,
	libcap,
	sudo ? null,
}: lib.callWith' python3Packages ({
	python,
	pythonImportsCheckHook,
	setuptools,
	wrapPython,
	pylint ? null,
	argparse-manpage ? null,
}: let
	stdenv = stdenvNoCC;
	pyprojectToml = lib.importTOML ./pyproject.toml;
	project = pyprojectToml.project;
in stdenv.mkDerivation (self: let
	inherit (self) genMan doPylint;
in {
	pname = "${python.pythonAttr}-${project.name}";
	version = project.version;

	strictDeps = true;
	__structuredAttrs = true;

	doCheck = true;
	doInstallCheck = true;

	genMan = !(python.isPyPy || argparse-manpage != null);
	doPylint = !(python.isPyPy || pylint != null);

	src = lib.fileset.toSource {
		root = ./.;
		fileset = lib.fileset.unions [
			./pyproject.toml
			./src
		];
	};

	SUDO = lib.getExe sudo;
	CAPSH = lib.getExe' libcap "capsh";

	postPatch = lib.optionalString (sudo != null) <| lib.dedent ''
		substituteInPlace "src/cappy/__init__.py" \
			--replace-fail "@sudo@" "$SUDO" \
			--replace-fail "@capsh@" "$CAPSH"
	'';

	outputs = [ "out" "dist" ] ++ lib.optionals genMan [
		"man"
	];

	nativeBuildInputs = (pythonHooks python).asList ++ [
		wrapPython
		setuptools
	] ++ lib.optionals genMan [
		argparse-manpage
	];

	nativeCheckInputs = lib.optionals doPylint [
		pylint
	];

	checkPhase = lib.optionalString doPylint <| lib.dedent ''
		pylint "cappy"
	'';

	nativeInstallCheckInputs = [
		pythonImportsCheckHook
	];

	propagatedBuildInputs = [
		libcap
	];

	postInstall = lib.optionalString genMan <| lib.dedent ''
		argparse-manpage \
			--module cappy \
			--function get_parser \
			--manual-title "General Commands Manual" \
			--project-name "${project.name}" \
			--description "${self.meta.description}" \
			--author "Qyriad <qyriad@qyriad.me>" \
			--prog cappy \
			--version "$version" \
			--output "$man/share/man1/cappy.1"
	'';

	postFixup = ''
		echo "wrapping Python programs in postFixup..."
		wrapPythonPrograms
		echo "done wrapping Python programs in postFixup"
	'';

	passthru.mkDevShell = {
		mkShellNoCC,
		pylint,
		uv,
	}: mkShellNoCC {
		name = "nix-shell-${self.finalPackage.name}";
		inputsFrom = [ self.finalPackage ];
		packages = [
			pylint
			uv
		];
	};

	meta = {
		homepage = "https://github.com/Qyriad/cappy";
		description = "Use capsh to run a program as the current user with with new capabilities";
		maintainers = with lib.maintainers; [ qyriad ];
		license = with lib.licenses; [ mit ];
		sourceProvenance = with lib.sourceTypes; [ fromSource ];
		platforms = lib.platforms.linux;
		# The version specified in pyproject.toml.
		disabled = python.pythonOlder "3.11";
		broken = self.finalPackage.meta.disabled;
		isBuildPythonPackage = python.meta.platforms;
		mainProgram = "cappy";
	};
}))
