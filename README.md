# Location

Ingest endpoint for the location log: `POST /api/location` appends the JSON
body to a JSONL file, one compact object per line.

```sh
curl -X POST -H 'content-type: application/json' \
  --data '{"lat":-37.8,"lon":144.9}' http://localhost:3003/api/location
```

A successful append answers `204` with an empty body, `400` if the body is not
JSON (or form-encoded), `405` for any other method. `GET /health` returns `ok`.

## Running

| env             | default            |
| --------------- | ------------------ |
| `PORT`          | `3003`             |
| `LOCATION_HOST` | `0.0.0.0`          |
| `LOCATION_FILE` | `./location.jsonl` |

```sh
bun run start        # or: nix run .
bun test
```

## NixOS

```nix
services.location = {
  enable = true;
  port = 3003;
};
```

The log lands in `/var/lib/location/location.jsonl`. No credentials are
needed; put the service behind a reverse proxy that terminates TLS.
