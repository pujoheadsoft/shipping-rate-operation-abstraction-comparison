export class HttpError extends Error {
  constructor(
    readonly status: number,
    statusText: string,
  ) {
    super(`HTTP ${status} ${statusText}`);
    this.name = "HttpError";
  }
}

export const fetchGet = async (url: string): Promise<string> => {
  const response = await fetch(url);

  if (!response.ok) {
    throw new HttpError(response.status, response.statusText);
  }

  return response.text();
};

export const fetchPost = async (
  url: string,
  body: string,
): Promise<string> => {
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body,
  });

  if (!response.ok) {
    throw new HttpError(response.status, response.statusText);
  }

  return response.text();
};
