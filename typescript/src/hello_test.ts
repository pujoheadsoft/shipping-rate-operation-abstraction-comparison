import { hello } from "./hello.ts";

Deno.test("hello returns the greeting", () => {
  const expected = "Hello, world!";
  const actual = hello();

  if (actual !== expected) {
    throw new Error(`Expected ${expected}, but received ${actual}`);
  }
});
