import { afterEach, beforeEach, expect, test } from "bun:test";
import { mkdtemp, readFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

import { startServer } from "./index";

let server: ReturnType<typeof startServer>;
let file: string;

beforeEach(async () => {
  file = join(await mkdtemp(join(tmpdir(), "location-")), "location.jsonl");
  server = startServer(0, "127.0.0.1", file);
});

afterEach(() => server.stop(true));

const post = (body: string, contentType = "application/json") =>
  fetch(new URL("/api/location", server.url), {
    method: "POST",
    headers: { "content-type": contentType },
    body,
  });

test("appends one compact JSON line per request", async () => {
  expect((await post('{"lat": 1, "lon": 2}')).status).toBe(204);
  expect((await post('{\n  "lat": 3,\n  "lon": 4\n}')).status).toBe(204);

  expect(await readFile(file, "utf8")).toBe(
    '{"lat":1,"lon":2}\n{"lat":3,"lon":4}\n',
  );
});

test("accepts form encoded bodies", async () => {
  expect(
    (await post("lat=1&lon=2", "application/x-www-form-urlencoded")).status,
  ).toBe(204);

  expect(await readFile(file, "utf8")).toBe('{"lat":"1","lon":"2"}\n');
});

test("rejects a body that is not JSON", async () => {
  expect((await post("not json")).status).toBe(400);
});

test("rejects other methods and unknown paths", async () => {
  expect((await fetch(new URL("/api/location", server.url))).status).toBe(405);
  expect((await fetch(new URL("/", server.url))).status).toBe(404);
  expect((await fetch(new URL("/health", server.url))).status).toBe(200);
});
