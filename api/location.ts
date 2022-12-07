import { VercelRequest, VercelResponse } from "@vercel/node";
import { retryDecorator } from "ts-retry-promise";
import fetch from "node-fetch";

// const fetch = retryDecorator(fetcher);

const GITHUB_AUTH = process.env["GITHUB_AUTH"];
const GITHUB_DISPATCH_URL =
  "https://api.github.com/repos/jamesmstone/location/dispatches";

export default (request: VercelRequest, response: VercelResponse) => {
  const payload = { event_type: "l-append", client_payload: request.body };
  fetch(GITHUB_DISPATCH_URL, {
    body: JSON.stringify(payload),
    headers: {
      Accept: "application/vnd.github+json",
      Authorization: `Bearer ${GITHUB_AUTH}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    method: "POST",
  })
    .then((githubResponse) => {
      response.status(githubResponse.status);
      return githubResponse.text();
    })
    .then((githubResponseJson) => {
      response.send(githubResponseJson);
    });
};
