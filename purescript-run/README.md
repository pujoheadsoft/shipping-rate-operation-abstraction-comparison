# PureScript + purescript-run

## 対応とバージョン

- PureScript 0.15.15、purescript-run 5.0.0、purescript-freeap 7.0.0、package set 81.1.0
- Domainはhead/tailで送料の非空を保証し、`UserId`、`PostalCode`、`Weight`をnewtypeで区別する。
- User APIからユーザーIDに対応する郵便番号を取得し、その配送先についてCarrier X/Y/Zの送料を取得して最安値を返す。Carrier X/Y/Z、UserApiClient、PostalCodePort、ShippingRatePortは別のrow-polymorphic first-order `Run` effect。

Gatewayは `Shipment -> FreeAp (Run carrierEffects) (Either FetchShippingRatesError ShippingRates)`。Carrier operationは `Request -> Run (carrierEffect | r) (Either CarrierApiError Response)`。Gatewayは各operationを共通の`ShippingRate`へ変換し、汎用の`parallelSequence`で`Traversable`内の任意個数の未解釈処理から静的な並列batchを組み立てる。Gatewayでは`NonEmpty Array`を使うため、1社以上という保証を失わない。Carrier失敗の結合には`Either`のApplicativeを使う。

`FreeAp`自体にはMonadがないため、PostalCodePortとShippingRatePortを逐次実行するUseCaseとの接続には `ParallelRun r = Free (FreeAp (Run r))` を使う。Freeの各stepが一つの静的並列batchを表す。`runApplicationPorts`は郵便番号取得を単一Run、送料取得を並列batchとして`ParallelRun`へliftし、Mainは必ずUseCaseを入口として実行する。

各Driverの公開`runCarrier...`はopen row handlerであり、Carrier effectを除去して`AFF`を追加する。Mainは3つのDriverを合成して `Run carrierEffects ~> Aff` を構築し、`runParallel`が `foldFreeAp (parallel <<< interpret)` で各batchを並列実行する。GatewayはDriverや自然変換を引数に受け取らない。

## Effect、Error、Concurrency

`run` 5.0.0のソースでは`type AFF r = (aff :: Aff | r)`で、`liftAff`は具体的な`Aff a`を一命令として`Run`へliftし、`runBaseAff`はその命令を取り出す。つまり標準`AFF`は、任意の`Run r a`をfiberへunliftするhigher-order operationではない。

この実装では、標準`Run`へ並列operationを追加する代わりに、`FreeAp (Run r)`を外側の静的構造として使う。順序は、未解釈Carrier branchでbatchを構築 → Application edgeで各RunをAffへinterpret → `ParAff`のApplicativeとして並列実行、となる。Gatewayのeffect rowにはCarrier X/Y/Zが残る。独自higher-order effectやunsafe coercionは使わない。

実HTTPは`Driver`だけがFetch/Yoga JSONを使い、各Carrier endpoint、encode、decodeを所有する。既存PureScript版の`ReaderT/ExceptT/Aff`に対し、dependency operationはextensible rowへ出るが、concurrencyは最終的に`Aff`側で行う。

## 評価

Carrierの失敗は`Either Left`という通常値なので、全branchを完了した後にGateway errorへ変換する。`Left`だけでは兄弟branchをcancelしない。一方、Aff自体の失敗と親fiberのcancelは`ParAff`を通じて実行中の兄弟branchへ伝播する。

この表現は、Applicativeに記述できる静的な並列batchと、Freeで接続された逐次stepを扱える。ただし、Polysemy/effectfulのhigher-order concurrency effectと完全に同じ表現力ではない。実行中に得た値から同じbatchの分岐数や形を変えることはできず、一般的なfork/join handleをeffect rowに持つわけでもない。

テストはrequest/result、Gateway/UseCase error mapping、UseCaseから外側handlerまでの接続、AVar barrierによる未解釈Carrier branchのoverlap、X/Y/Z順の結果、`Either Left`時の全件待機、親cancelとAff failureの伝播を確認する。

参考: [purescript-run source](https://github.com/natefaubion/purescript-run)

```sh
spago test
spago run
```
