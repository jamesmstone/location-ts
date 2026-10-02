{
  bun,
  lib,
  runCommand,
}:
# `nix flake check` only builds the `checks` outputs, so the unit suite has to
# be one of them to run in CI at all.
runCommand "location-unit-tests"
  {
    nativeBuildInputs = [ bun ];
    src = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.unions [
        ./index.ts
        ./index.test.ts
        ./package.json
      ];
    };
  }
  ''
    export HOME=$TMPDIR
    cp -r $src/. $TMPDIR/src
    cd $TMPDIR/src
    bun test
    touch $out
  ''
