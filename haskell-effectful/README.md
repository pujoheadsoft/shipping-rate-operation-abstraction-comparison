# Haskell + effectful

## 対応とバージョン

- Stack 3.9.1 / LTS Haskell 24.61、effectful 2.6.1.0
- Domainは`NonEmpty ShippingRate`に加え、`UserId`、`PostalCode`、`Weight`をnewtypeで区別する。User APIから配送先の郵便番号を取得し、Carrier X/Y/Zの送料から最安値を返す。
- Gatewayは `Eff es ShippingRates` requiring Carrier X/Y/Z、`Error FetchShippingRatesError`、`Concurrent`。
- Carrier interpreterは環境をclosureに保持し、内部で`Reader`、`Error DriverError`、`IOE`を使うdynamic handler。

代表的なoperationは `CarrierXRateRequest -> Eff es (Either CarrierXApiError CarrierXRateResponse)`。Gatewayは `Shipment -> Eff es ShippingRates` で、Carrier X/Y/Z、`Error FetchShippingRatesError`、`Concurrent`を要求し、Carrier errorをFetch errorへ変換する。Carrier X Driverの実体は `(Reader CarrierXApiEnvironment :> es, Error DriverError :> es, IOE :> es) => CarrierXRateRequest -> Eff es CarrierXRateResponse`。公開interpreterは環境を受け取り、内部の`Reader`と`Error DriverError`を処理してCarrier effectだけを除去する。

## Effect、Error、Concurrency

Gatewayはeffectful標準の`Effectful.Concurrent.Async.concurrently`を使い、3つの`Eff es` branchをstructuredにjoinする。`Concurrent` handlerはchildごとにeffect environmentを引き継ぐため、Carrier effectsを残したまま並行化できる。実行時には`runConcurrent`の内側へCarrier interpreterを置き、子threadでdynamic handlerが動く形にしている。

composition rootの順序は UseCase → PostalCodePort / ShippingRatePort interpreter → User / Carrier X/Y/Z interpreter → Concurrent → GetCheapestShippingRate Error → IOE。各Port interpreterはGateway固有の失敗を`Either`へ戻す。User APIの404は`PostalCodeNotFound`を経て`ShippingDestinationNotFound`へ変換し、それ以外の取得失敗は`GetCheapestShippingRateFailed`へ変換する。`Driver`だけが`http-conduit`/Aesonとendpoint/JSONを所有する。

## 評価

IO ecosystemとの統合と性能を重視するproduction-orientedな形として自然。高水準APIがscope終了時にchildをjoin/cancelする。effectfulのdynamic environmentはchildへ引き継がれるため、handlerが共有する可変資源のthread safetyは利用者の責任になる。

テストはrequest/result、Gateway/UseCase error mapping、STM barrierによるoverlap、親cancel後に3つのchildが終了することをタイムアウト付きで確認する。

```sh
stack test
```

`stack run` はcomposition rootから実HTTP Driverを実行する。

参考: [effectful 2.6.1.0 concurrency API](https://hackage-content.haskell.org/package/effectful-2.6.1.0/docs/Effectful-Concurrent-Async.html)
