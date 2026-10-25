import type { PostalCode } from "./postal_code.ts";
import type { Weight } from "./weight.ts";

export type Shipment = Readonly<{
  destinationPostalCode: PostalCode;
  weight: Weight;
}>;
