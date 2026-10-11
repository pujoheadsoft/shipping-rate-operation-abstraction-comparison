import { Context, Effect, Layer } from "effect";

export class HttpRequestFailed {
  readonly _tag = "HttpRequestFailed";
}

export class HttpClient extends Context.Service<
  HttpClient,
  {
    readonly post: (url: string, body: string) => Effect.Effect<string, HttpRequestFailed>;
  }
>()("rates/driver/HttpClient") {}

export const fetchPost = (url: string, body: string): Effect.Effect<string, HttpRequestFailed> =>
  Effect.tryPromise({
    try: async (signal) => {
      const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body,
        signal,
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status} ${response.statusText}`);
      }

      return response.text();
    },
    catch: () => new HttpRequestFailed(),
  });

export const HttpClientLive: Layer.Layer<HttpClient, never, never> = Layer.succeed(HttpClient, {
  post: fetchPost,
});
