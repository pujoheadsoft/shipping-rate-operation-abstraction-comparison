# Flix

## 対応とバージョン

- Flix 0.79.0、JDK 25.0.4
- Domain、Carrier固有DTO、UseCase/Port、全3件返却、error mappingは既存版と同じ。
- Carrier operationは `Request -> Result[CarrierXApiError, Response] \ CarrierXApiClient`。Portもlanguage-native effect。
- 代数側の`handle...With`はCarrier effectを具体clientの`IO`へ変換する。本番の`runShippingRatePort`はGateway、本番の`runCarrier...`はDriverに置く。

Gatewayは `Shipment -> Result[FetchShippingRatesError, ShippingRates] \ {CarrierXApiClient, CarrierYApiClient, CarrierZApiClient}`。各Driver clientは `Environment -> Request -> Result[CarrierX/Y/ZApiError, Response] \ IO` を返し、Carrier handlerがuser-defined effectを除去する。HTTP層の`DriverError`は各DriverでCarrier固有errorへ変換する。

## Effect、Error、Concurrency

Flixは未処理user-defined effectを`spawn`へ持ち込むことを禁止し、childはpureまたはprimitive effectでなければならない。`compile-fail/UnhandledEffectInSpawn.flix`を0.79.0でコンパイルすると、`Client`と`(Chan + IO + NonDet)`が一致しないエラーになる。

したがって順序はKoka/Kyoと異なり、各branchでCarrier handlerを先に適用して`IO`へ変換 → region内で`spawn` → Channelでjoin、となる。region終了前にchildは終了する。Carrier/Portの業務上の失敗は`Result`で表し、Gateway/UseCaseでそれぞれ上位errorへ写像する。

実HTTPは標準`Net.Http` handlerを`IO`へ解釈し、各Carrier Driverがendpoint、JSON object encode、response decodeを所有する。HTTP/JSON型はGatewayへ出ない。

## 評価

effect exclusionによりhandler後にCarrier effectが消えたことが型へ出るのは自然。一方、「未解釈effectをchildへ渡す」比較では明確に不可能であり、interpret-before-spawnが正式な設計となる。実務ではこの制限が安全性と推論容易性を与える反面、handler propagationを使う並行設計は書けない。

テストはrequest/result、Gateway/UseCase error mapping、およびタイムアウト付き`CountDownLatch` barrierによる3 branchのoverlapとX/Y/Z順の結果を確認する。逐次実行へ退行しても待機し続けず、明示的に失敗する。

```sh
cd flix
java --enable-native-access=ALL-UNNAMED -jar flix.jar test
java --enable-native-access=ALL-UNNAMED -jar flix.jar check compile-fail/UnhandledEffectInSpawn.flix
```

最後のコマンドは、未解釈Carrier effectを含む`spawn`が型検査で拒否されることを確認するため、意図的に失敗する。

参考: [Flix Effects and Handlers](https://doc.flix.dev/effects-and-handlers.html)
