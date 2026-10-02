{
  curl,
  lib,
  location,
  runCommand,
}:
runCommand "location-integration" { nativeBuildInputs = [ curl ]; } ''
  export HOME=$TMPDIR
  cd $TMPDIR

  PORT=3999 LOCATION_FILE=$TMPDIR/data/location.jsonl ${lib.getExe location} &
  trap 'kill %1' EXIT

  for _ in $(seq 100); do
    curl -sf http://127.0.0.1:3999/health >/dev/null && break
    sleep 0.1
  done

  status=$(curl -s -o body -w '%{http_code}' -X POST \
    -H 'content-type: application/json' \
    --data '{"lat":1,"lon":2}' \
    http://127.0.0.1:3999/api/location)

  [ "$status" = 204 ]
  [ ! -s body ]
  grep -Fxq '{"lat":1,"lon":2}' $TMPDIR/data/location.jsonl

  touch $out
''
