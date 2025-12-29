# python3Packages.callPackage
{
	lib,
	stdenvNoCC,
	python,
	setuptools,
	pypaBuildHook,
	pypaInstallHook,
	pythonCatchConflictsHook,
	pythonRuntimeDepsCheckHook,
	pythonNamespacesHook,
	pythonOutputDistHook,
	pythonImportsCheckHook,
	ensureNewerSourcesForZipFilesHook,
	pythonRemoveBinBytecodeHook,
	wrapPython,
	argparse-manpage ? null,
	libcap,
}: let
	stdenv = stdenvNoCC;
	# FIXME: should this be python.stdenv?
	inherit (stdenv) hostPlatform buildPlatform;

	pyprojectToml = lib.importTOML ./pyproject.toml;
	project = pyprojectToml.project;

in stdenv.mkDerivation (self: let
	inherit (self) genMan;
in {
	pname = "${python.pythonAttr}-${project.name}";
	version = project.version;

	strictDeps = true;
	__structuredAttrs = true;

	doCheck = true;
	doInstallCheck = true;

	genMan = !(python.isPyPy || argparse-manpage != null);

	src = lib.fileset.toSource {
		root = ./.;
		fileset = lib.fileset.unions [
			./pyproject.toml
			./src
		];
	};

	outputs = [ "out" "dist" ] ++ lib.optionals genMan [
		"man"
	];

	nativeBuildInputs = [
		pypaBuildHook
		pypaInstallHook
		pythonRuntimeDepsCheckHook
		pythonOutputDistHook
		ensureNewerSourcesForZipFilesHook
		pythonRemoveBinBytecodeHook
		wrapPython
		setuptools
	] ++ lib.optionals genMan [
		argparse-manpage
	] ++ lib.optionals (buildPlatform.canExecute hostPlatform) [
		pythonCatchConflictsHook
	] ++ lib.optionals (python.pythonAtLeast "3.3") [
		pythonNamespacesHook
	];

	nativeInstallCheckInputs = [
		pythonImportsCheckHook
	];

	propagatedBuildInputs = [
		libcap
	];

	postInstall = lib.optionalString genMan <| lib.trim ''
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
})

