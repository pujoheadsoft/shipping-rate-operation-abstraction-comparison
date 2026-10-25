# Haskell + Polysemy

## 対応とバージョン

- Stack 3.9.1 / LTS Haskell 22.44（GHC 9.6.7）、Polysemy 1.9.2.0
- Domainは`NonEmpty ShippingRate`に加え、`UserId`、`PostalCode`、`Weight`をnewtypeで区別する。User APIから配送先の郵便番号を取得し、Carrier X/Y/Zの送料から最安値を返す。
- Gatewayは `Members '[CarrierXApiClient, CarrierYApiClient, CarrierZApiClient, Error FetchShippingRatesError, Async, Resource] r => Shipment -> Sem r ShippingRates`。
- Carrier interpreterは環境をclosureに保持し、内部で`Reader`、`Error DriverError`、`Embed IO`を使う。

Carrier X operationは `CarrierXRateRequest -> Sem '[CarrierXApiClient] (Either CarrierXApiError CarrierXRateResponse)` 相当。Gatewayは`Members`制約でX/Y/Z、`Error FetchShippingRatesError`、`Async`を要求する。Carrier X Driverの実体は `Members '[Reader CarrierXApiEnvironment, Error DriverError, Embed IO] r => CarrierXRateRequest -> Sem r CarrierXRateResponse`。公開interpreterは環境を受け取り、内部の`Reader`と`Error DriverError`を処理してCarrier effectだけを除去する。

## Effect、Error、Concurrency

`Polysemy.Async`はhigher-order effectであり、childにはまだCarrier effectsを含む`Sem r`を渡せる。Carrier interpretersを後から適用するとweavingによってchild内部にも作用し、その後`asyncToIOFinal`が`Final IO`へlowerする。このためGatewayはeffect abstractionを保ったままconcurrencyを記述できる。

ただしPolysemy 1.9.2.0の`sequenceConcurrently`は、実装上`traverse async`の後に`traverse await`するだけである。親のcancelや途中の例外に対するhandle解放を保証しないため、この実装では`Resource.bracket`で全handleを囲む`sequenceConcurrentlyScoped`を使用し、scope離脱時に必ず全childをcancelする。

`Async`が返す`Maybe`は「cancelされた」という印ではない。公式ソースの説明どおり、child内で局所的な`Error`等が失敗し、`Inspector`が値を取り出せない場合に`Nothing`となる。本Gatewayは`Nothing`を`FetchShippingRatesFailed`へ変換する。

なおwaitはX/Y/Z順なので、後順位のchildが予期しないIO例外で終了し、先頭childが停止したままの場合にfail-fastで観測する仕組みではない。`Resource`により最終的な漏洩は防ぐが、この応答性はproduction上の残課題である。

composition rootの順序は UseCase → PostalCodePort / ShippingRatePort interpreter → User / Carrier X/Y/Z interpreter → GetCheapestShippingRate Error → Async → Resource → Embed IO → Final IO。各Port interpreterはGateway固有の失敗を`Either`へ戻す。User APIの404は`PostalCodeNotFound`を経て`ShippingDestinationNotFound`へ変換し、それ以外の取得失敗は`GetCheapestShippingRateFailed`へ変換する。`Driver`だけが`http-conduit`/Aesonとendpoint/JSON契約を知る。

## 評価

未解釈effectを並行childへ渡せる点はKokaに近い。一方、higher-order effect、weaving、`Final IO`、interpreter順の理解が必要で、単純なfirst-order effectより推論コストが高い。非IO interpreterのstate等は並行時にlocal semanticsとなり得るため、productionでは各interpreterの並行意味論と性能を確認する。

テストはrequest/result、Gateway/UseCase error mapping、STM barrierによるoverlap、親cancel後に3つのchildが終了することをタイムアウト付きで確認する。

```sh
stack test
```

`stack run` はcomposition rootから実HTTP Driverを実行する。

参考: [Polysemy 1.9.2.0 documentation](https://hackage.haskell.org/package/polysemy-1.9.2.0/docs/Polysemy-Async.html)
