import { hello } from "./hello.ts";

if (import.meta.main) {
  console.log(hello());
}
