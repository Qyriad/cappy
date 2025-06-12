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
	libcap,
}: let
	stdenv = stdenvNoCC;
	# FIXME: should this be python.stdenv?
	inherit (stdenv) hostPlatform buildPlatform;

	pyprojectToml = lib.importTOML ./pyproject.toml;
	project = pyprojectToml.project;
in stdenv.mkDerivation (self: {
	pname = "${python.pythonAttr}-${project.name}";
	version = project.version;

	strictDeps = true;
	__structuredAttrs = true;

	doCheck = true;
	doInstallCheck = true;

	src = lib.fileset.toSource {
		root = ./.;
		fileset = lib.fileset.unions [
			./pyproject.toml
			./src
		];
	};

	outputs = [ "out" "dist" ];

	nativeBuildInputs = [
		pypaBuildHook
		pypaInstallHook
		pythonRuntimeDepsCheckHook
		pythonOutputDistHook
		ensureNewerSourcesForZipFilesHook
		pythonRemoveBinBytecodeHook
		wrapPython
		setuptools
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

