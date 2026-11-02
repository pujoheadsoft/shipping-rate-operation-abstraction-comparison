# Kyo

## 対応とバージョン

- JDK 25.0.4 (Temurin)、Scala 3.9.0、Kyo 1.0.0-RC7（`kyo-core` / `kyo-http`）、uJson 4.4.3
- `UserId`と`Weight`からUser API経由で配送先を取得し、3社の送料から最安値を選ぶ。`Shipment`、非空の`ShippingRates`、Carrier固有DTO、X/Y/Z順、段階ごとのerror mappingは他実装と揃えている。
- Carrier依存は複数operationを追加できる`Client` traitを保持する独立した`ContextEffect`で、現在の公開operationは `Request -> Either[CarrierApiError, Response] < (CarrierXApiClient & Async)`。依存実装を環境値として子fiberへ継承できる。Portは`ArrowEffect`の`Op[A]`として明示し、代数側にはoperationだけを置く。productionの`run`はShippingRatePortならGateway、Carrier effectならDriverに置く。

User APIもGatewayにはJSONを露出せず、DriverだけがHTTPとwire DTOを扱う。`PostalCodePort`は`ArrowEffect`、User API clientは`ContextEffect`として構成する。

Gatewayの公開シグネチャは `Shipment => ShippingRates < (CarrierXApiClient & CarrierYApiClient & CarrierZApiClient & Async & Abort[FetchShippingRatesError])`。DriverはCarrier requestを受け、`Either[CarrierApiError, Response] < Async`を返す。`ContextEffect.handleInheritable`はCarrier effectを除き、clientの`Async`を残す。

## Effect、Error、Concurrency

Gatewayは具体HTTPを知らず、3つの未解釈Carrier computationを`Async.zip`へ渡す。Carrierの`Client`実装は`ContextEffect.handleInheritable`で束縛され、Kyo標準のcontext継承により各child fiberから同じ値を参照できる。手書きの`Current` operationや`Isolate`は不要で、merge対象の状態もない。

MainはUseCaseを起点に、`ShippingRatesGateway.run` → Carrier X/Y/Z Driverの`run` → `Abort.run`を`.handle`で左から右へ適用する。各公開`run`は実装を所有する外側の層で`ArrowEffect.handleLoop`を直接使う。`KyoApp`が実行境界となる。

Gateway内部の順序は `Async.zip` → childで継承済みCarrier contextを参照 → `Abort.run`。Carrier API errorはGatewayで`FetchShippingRatesFailed`へ変換する。UseCaseは配送先未登録を`ShippingDestinationNotFound`、それ以外のPostal/Shipping Port失敗を`GetCheapestShippingRateFailed`へ変換し、成功時に最安値を選ぶ。

実HTTPはCarrier DriverだけがuJsonでCarrier固有JSONを扱い、汎用`Driver.HttpClient`はKyo標準`kyo-http`の`HttpClient.postText`を使う。明示的に`application/json`を指定し、非2xx・接続失敗等の`Abort[HttpException]`だけを`DriverOperationFailed`へ変換する。予期しないpanicやfiber interruptionは`runPartialOrThrow`により通常のDriver errorへ握りつぶさない。JVM backendは公式ドキュメントどおりJava NIOであり、以前の`Async.defer`内の同期`java.net.http.HttpClient.send`は使用しない。

## 評価

依存を`ContextEffect`として未解釈のまま並行化でき、Kyo標準の継承規則を使える点は自然。独自operationの状態をfiber間で扱う場合には依然として`Isolate`設計が必要だが、このサンプルのstatelessなclient依存には不要である。productionではstructured scopeとtyped abortは有利だが、RC APIの移行リスクは評価する必要がある。

テストは最安値選択、Gateway/UseCase error mappingと短絡、および`CountDownLatch` barrierによるbranch overlap、Gatewayの正常終了とX/Y/Z順の返却値をタイムアウト付きで確認する。失敗時にもreleaseとrunner interruptionを行う。

```sh
scala-cli test . --server=false
```

参考: [Kyo 1.0.0-RC7 documentation](https://getkyo.io/latest/)、[kyo-http](https://getkyo.io/latest/kyo-http/)

JDK 25ではScala runtimeの旧lazy-val互換コードから`sun.misc.Unsafe`の非推奨警告が出る。Scala CLIの実験的Slothはこの警告を消せる一方、依存クラスのframe hierarchyを解決できない警告や、ahead-of-time変換時の`VerifyError`を起こしたため、このサンプルでは有効化していない。これはサンプルコードではなくScala runtime/依存側の警告である。
