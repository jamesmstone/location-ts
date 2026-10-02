{
  bun,
  lib,
  makeWrapper,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "location";
  version = "1.0.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./index.ts
      ./package.json
    ];
  };

  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/location
    cp index.ts package.json $out/share/location/

    # No --chdir: the data file is resolved against the cwd the unit sets.
    makeWrapper ${lib.getExe bun} $out/bin/location \
      --add-flags "run $out/share/location/index.ts"

    runHook postInstall
  '';

  meta = {
    description = "Location log ingest endpoint";
    mainProgram = "location";
  };
}
