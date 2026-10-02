import { appendFile, mkdir } from "node:fs/promises";
import { dirname, resolve } from "node:path";

const DEFAULT_PORT = 3003;

export const locationFile = (): string =>
  resolve(process.env.LOCATION_FILE ?? "location.jsonl");

const parseBody = async (request: Request): Promise<unknown> => {
  const raw = await request.text();
  if (
    (request.headers.get("content-type") ?? "").includes(
      "application/x-www-form-urlencoded",
    )
  ) {
    return Object.fromEntries(new URLSearchParams(raw));
  }
  return JSON.parse(raw);
};

const append = async (file: string, payload: unknown): Promise<void> => {
  await mkdir(dirname(file), { recursive: true });
  await appendFile(file, `${JSON.stringify(payload)}\n`);
};

export function startServer(
  port: number = DEFAULT_PORT,
  hostname: string = "0.0.0.0",
  file: string = locationFile(),
) {
  const ingest = async (request: Request): Promise<Response> => {
    if (request.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }
    let payload: unknown;
    try {
      payload = await parseBody(request);
    } catch {
      return new Response("Bad Request", { status: 400 });
    }
    await append(file, payload);
    // Clients were built against GitHub's dispatch reply, relayed verbatim by
    // the old Vercel function: an empty 204.
    return new Response(null, { status: 204 });
  };

  return Bun.serve({
    port,
    hostname,
    routes: {
      "/api/location": ingest,
      "/api/location/": ingest,
      "/health": () => new Response("ok\n"),
    },
    fetch: () => new Response("Not found", { status: 404 }),
  });
}

if (import.meta.main) {
  const file = locationFile();
  const server = startServer(
    Number(Bun.env.PORT ?? DEFAULT_PORT),
    Bun.env.LOCATION_HOST ?? "0.0.0.0",
    file,
  );
  console.log(`location listening at ${server.url} appending to ${file}`);
}
