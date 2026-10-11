# Shipping Rate operation-abstraction comparison

## 比較の基準

各実装に共通するapplication semanticsを基準にした。

- 入力は配送先郵便番号と重量を持つ`Shipment`。
- Carrier X/Y/Zは互いに異なるrequest/response契約を維持する。
- Gatewayは3社を並行取得し、X/Y/Z順ですべての`ShippingRate`を非空コレクションとして返す。
- `ShippingRate.carrier`は`CarrierX` / `CarrierY` / `CarrierZ`であり、service code/nameではない。
- Carrier失敗は`FetchShippingRatesFailed`、Port失敗は`GetShippingRatesFailed`へ変換する。
- 選択、最安値計算、filter、sort、fallback、retryは行わない。

業務上の意味は全版で揃えた。通常のTypeScriptはDriverの技術的失敗をPromise rejectionとしてGatewayの`try/catch`で変換する。Effect TSを含むeffect版はDriver/API境界でもtyped error channelとして表す。

## 証拠の表記

- **test**: 実際のbuild/testで確認した。
- **source**: 使用versionのlibrary sourceまたは当該実装から確認した。
- **docs**: 使用versionに対応する公式documentation/APIから確認した。
- **inference**: 上記からの設計上の推論。runtime testでは未確認。
- **unverified**: 今回は確認できていない。

「今回の標準APIで採用していない」と「system全体で不可能」は区別する。

## Effectと並行実行の横断比較

| System | Application-defined effects | Typed error | Concurrency | 未解釈application effectをchildに保持 | 必要な仕組み・解釈境界 | 根拠 |
|---|---|---|---|---|---|---|
| Koka | language effect (`carrier-x/y/z-api-client`) | `fail<E>`と`result` | `interleaved` | 可能 | handler scope内で`interleaved`を実行 | source/build。厳密なbarrier testは未追加 |
| Kyo | UseCaseは`ArrowEffect`、Carrierは`ContextEffect` | `Abort<E>` + API `Either` | `Async.zip` | 可能 | Carrier Driverを`handleInheritable`で提供 | test/source |
| Flix | language-native algebraic effect | `Result` | region + `spawn` + Channel | user-defined effectのままでは不可 | Carrier handlerを先に適用してprimitive effectへ変換 | compile-fail test/docs |
| Polysemy | GADT effect in `Sem r` | `Error E` | higher-order `Async` + `Resource` | 可能 | weaving、`Final IO`、child handleのbracket | overlap/cancel test + 1.9.2 source |
| effectful | dynamic effect in `Eff es` | static `Error E` | `Concurrent.concurrently` | 可能 | unliftingとchildへのenvironment継承 | overlap/cancel test + docs |
| PureScript Run | row-polymorphic first-order functor | `Either` | `Aff.parSequence` | 標準`AFF`では行っていない | Carrierを`Aff`へinterpretした後に並行化 | overlap test + run 5.0.0 source |
| 既存PureScript | `ReaderT`による値依存 | `ExceptT`/`Either` | `Aff.parSequence` | 該当なし | `ReaderT Dependencies (ExceptT E Aff)`のbranchを並行化 | overlap test/source |
| TypeScript | closure/record | discriminated `Result`; 技術失敗はrejection | `Promise.all` | 該当なし | Promise runtimeがclosureを共有 | overlap test/source |
| TypeScript + Effect 4 | `Context.Service` requirement | `Effect<A, E, R>`の`E` | `Effect.all` (`unbounded`) | 可能。本実装ではservice取得後の閉じたbranchをfork | Gateway LayerがCarrier Layerをrequireし、Mainで提供 | overlap/cancel test + docs |

## なぜ差が出るか

### Koka

Gatewayのeffect rowにCarrier X/Y/Z、`async`、`fail`が残ったまま、`interleaved`へ3つの関数を渡す。Driverの`ask`と`exn`はhandler内部で処理し、外へは`async`だけが残る。これはlanguage handlerとeffect rowで直接表現される。

### KyoのArrowEffectとContextEffect

UseCaseが要求する`ShippingRatePort`は操作を閉じた集合として列挙するため`ArrowEffect`で表す。一方、Carrier clientは複数操作を持てるservice値として`ContextEffect`で表し、Driverが`handleInheritable`で提供する。これにより`Async.zip`のchild fiberにも同じclient contextが継承され、Carrierごとの独自`Isolate`実装は不要になった。barrier testは3つのCarrier操作が重なり、Gatewayが正しい値で終了することを確認した。

このCarrier clientはstatelessなservice interfaceである。状態effectを並列化する場合には、依然としてfork時の複製・共有・merge semanticsを別途設計する必要がある。

### TypeScript + EffectのContextとLayer

Portは`Context.Service`として宣言し、必要な依存を`Effect<Success, Error, Requirements>`の`Requirements`へ載せる。UseCaseは`ShippingRatePort`だけを要求し、Gateway LayerはCarrier X・Y・Zを要求して`ShippingRatePort`を提供する。MainはCarrier LayerをGateway Layerへ渡すだけで、具体clientをUseCaseへ手渡さない。

Gateway Layerは構築時に3つのCarrier serviceを取得し、閉じた`fetchShippingRates`操作を作る。このためGateway実装の下位依存はLayerの入力に現れる一方、提供後のPort操作には漏れない。3社取得は`Effect.all`の`unbounded` concurrencyで並行化し、入力tupleと同じX・Y・Z順で結果を返す。

### Flixとspawn制約

Flix 0.77.0では、未処理`Client` effectを含む式を`spawn`すると、`Client`とspawnが許すprimitive effects `(Chan + IO + NonDet)`をunifyできずcompile errorになる。このため各Carrier handlerをbranchへ先に適用し、IO computationへ変換してからregion内でspawnする。これはworkaroundではなく、effect exclusionが要求する解釈順である。

### Polysemyのhigher-order Async

Polysemyの`Async` operationはchildの`Sem r a`を保持するhigher-order effectなので、Carrier effectを含む計算を受け取れる。後から適用するinterpreterはweavingによりchild内部にも作用する。

Polysemy 1.9.2.0の`sequenceConcurrently`は`traverse async`の後に`traverse await`するだけで、handleをbracketしない。そのため本実装は`Resource.bracket`でspawnした全handleを囲み、scope離脱時に必ずcancelする。親cancel時に全3 childが終了することをtestした。

`Async`の`Maybe`はcancel標識ではない。公式sourceでは、child内で局所的な`Error`等が失敗し、`Inspector`が値を取り出せない可能性を表す。Gatewayでは`Nothing`をapplication errorへ変換する。

残る制約として、X/Y/Z順にwaitするため、後順位のchildが予期しない例外で終了しても、先頭childが停止していれば即座には観測しない。Resource leakは防止したが、`async` packageの`concurrently`相当の完全なfail-fast joinではない。

### effectfulのenvironmentとunlifting

effectful標準`Concurrent` interpreterが`Eff es`をchild threadへunliftし、dynamic effect environmentを伝播する。`concurrently`はscope内で両childを管理し、一方の異常終了や親cancel時に残りをcancelする。本実装では3-way joinをnested `concurrently`で表し、overlapと親cancel後の全child終了をtestした。

environmentが伝播しても、handlerが閉じ込めた可変資源のthread safetyまでは型が保証しない。共有clientやconnection poolは別途並行安全である必要がある。

### PureScript RunのAFF

`run` 5.0.0 sourceでは、`AFF`は`(aff :: Aff | r)`であり、`liftAff`は具体的な`Aff a`をfirst-order命令として持ち上げる。`runBaseAff`はその命令を取り出す。標準`AFF`は任意の`Run r a`をchildへunliftするhigher-order operationではない。

そのため本実装はCarrier effectを各branchで`Run (AFF + ())`へinterpretし、`runBaseAff`で`Aff`へlowerしてから`parSequence`する。AVar barrier testは、このinterpret済みAff branchのoverlapを確認する。

これは「purescript-run全体で原理的に不可能」という結論ではない。独自higher-order effectや別runtime encodingは設計可能かもしれないが、標準`AFF`の性質とは別であり、今回は不自然な独自runtimeを追加していない。

## 失敗とキャンセル

業務上の契約は全版で同じで、いずれかのCarrier失敗を`FetchShippingRatesFailed`へ変換する。現行Gateway testsは正常系とCarrier Y失敗を代表ケースとして確認する。X/Z/複数同時失敗を個別網羅するtestは未追加であり、比較実験上の残課題である。

runtime上のcancel semanticsは同じではない。

| System | 親cancel・child失敗の性質 | 今回の確認 |
|---|---|---|
| TypeScript | `Promise.all`はrejectionを返すが、標準では他Promiseをcancelしない | overlap test。cancelは未検証 |
| TypeScript + Effect | `Effect.all`のstructured fibers。失敗時は残りのFiberを中断し、Driverの`fetch`へ中断用`AbortSignal`を渡す | overlapと残り2 Fiberの中断をbarrier testで確認。HTTPへの伝播は未検証 |
| PureScript / PureScript Run | `Aff` fiberはcancel可能。test workerは`bracket`でkill | overlapとtest cleanup。Carrier失敗時のsibling cancelは未検証 |
| Koka | `interleaved`のruntime semanticsに従う | build/test。cancel専用testは未検証 |
| Kyo | `Async.zip`と`Scope`によるstructured cancellation | overlap/正常終了をtest。HTTP中cancelは未検証 |
| Flix | region終了までspawn childを管理 | timed barrier test。child例外/cancel専用testは未検証 |
| Polysemy | 標準`sequenceConcurrently`だけではscope管理不足。今回Resourceを追加 | 親cancel後の全child終了をtest |
| effectful | `concurrently`がstructured join/cancel | 親cancel後の全child終了をtest |

## HTTP境界

全実装でGatewayはHTTP libraryをimportしない。

```text
UseCase -> ShippingRatePort -> Gateway
  -> Carrier application effect/client
  -> Carrier interpreter/handler/driver
  -> generic HTTP + JSON
  -> real I/O
```

- Kokaは基準実装どおりHTTP実体をstubのまま維持した。
- TypeScriptとEffect TSは`fetch`、既存PureScript/PureScript RunはFetch、Flixは`Net.Http`、Haskell両版は`http-conduit`、Kyoは`kyo-http`を使う。
- Effect TSのDriverは`Effect.tryPromise`へ`fetch`を包み、fiber interruptionの`AbortSignal`を渡す。HTTP failureとJSON decode failureはCarrierごとのtyped errorへ変換する。
- Haskell両版は`SomeException`をやめ、`HttpException`だけをDriver errorへ変換する。JSON decode errorは`Either`として別に変換し、async exceptionをHTTP失敗として握りつぶさない。
- Kyoは同期JDK `HttpClient.send`を廃止し、Kyo schedulerとstructured cancellationに統合されたNIO `kyo-http`を使用する。typed `HttpException`だけをDriver errorへ変換し、panic/interruptionは保持する。

ローカルHTTPサーバーを用いたrequest encoding、status、不正JSON、通信失敗の統合testは今回追加していない。Gateway contract testはHTTPをstubしているため、この境界は全実装共通のproduction test gapとして残る。「HTTP境界をモデル化した」ことと「実通信を統合testした」ことは区別する。

## Production practicality

| System | Effect/concurrency | Ecosystem/I/O | Production上の主な注意 |
|---|---|---|---|
| Koka | effect rowとhandlerは簡潔 | HTTP等の選択肢・運用実績は限定的 | runtime/tooling、実HTTP接続を別途評価 |
| Kyo RC7 | structured concurrencyとtyped effectsが統合 | `kyo-http`を含む統合stack | RC API、ArrowEffectとContextEffectの使い分け |
| Flix 0.77 | effect exclusionとregionが明快 | JVM利用可だがlanguage ecosystemは小さい | interpret-before-spawn制約、library選択 |
| Polysemy 1.9.2 | 表現力は高い | Haskell ecosystemを利用可能 | higher-order/local-state semantics、joinのfail-fast性、性能 |
| effectful 2.6 | IO志向で高性能、structured concurrencyあり | Haskell ecosystemを直接利用しやすい | dynamic handler資源のthread safety |
| PureScript Run | extensible first-order rowは簡潔 | PureScript/Aff/JS ecosystem | higher-order concurrency境界は自前設計が必要 |
| 既存PureScript | transformer stackが一般的 | Aff/Fetchが直接使える | effect requirementの拡張性より単純さを優先 |
| TypeScript | closure/Promiseが最小 | ecosystem/deploymentが最も一般的 | typed effect rowなし、Promise sibling cancelなし |
| TypeScript + Effect 4 | typed error・requirements・structured concurrency | TypeScript/JS ecosystemを利用可能 | serviceは操作ADTではなくinterface。Layer設計の学習コスト |

## 検証コマンド

全実装をまとめるターゲットを追加した。

```sh
make test-all
```

個別には次を使う。

```sh
make test-koka
make test-ps
make test-ts
make test-effect-ts
make test-kyo
make test-flix
make test-polysemy
make test-effectful
make test-ps-run
```

Flixの禁止例は通常test sourceへ含めず、次が意図的にcompile failureになることで確認する。

```sh
cd flix
java -jar ~/.local/share/flix.jar check compile-fail/UnhandledEffectInSpawn.flix
```

## 今回の検証状況

| Implementation | Build | Test | 未解決事項 |
|---|---|---|---|
| Koka | success | success (4/4) | HTTP実体は意図的にstub。cancel barrier未追加 |
| PureScript | success | success (5/5) | sibling cancellation、HTTP統合test |
| TypeScript | success | success (5/5) | Promiseに標準sibling cancellationなし、HTTP統合test |
| TypeScript + Effect 4.0.2 | success | success (6/6) | `AbortSignal`伝播、HTTP統合test |
| Kyo | success | success (5/5) | RC版。HTTP中cancelとHTTP統合test |
| Flix | success | success (5/5) | child failure/cancel test、HTTP統合test |
| Haskell + Polysemy | success | success (6/6) | 後順位child例外のfail-fast観測、HTTP統合test |
| Haskell + effectful | success | success (6/6) | handler資源のthread safety、HTTP統合test |
| PureScript + Run | success | success (5/5) | 標準AFFではinterpret-before-parallel、HTTP統合test |

## 公式資料

- [Kyo core](https://getkyo.io/latest/kyo-core/)
- [Kyo HTTP](https://getkyo.io/latest/kyo-http/)
- [Effect: Managing Services](https://effect.website/docs/v4/requirements-management/services)
- [Effect: Managing Layers](https://effect.website/docs/v4/requirements-management/layers)
- [Effect: Basic Concurrency](https://effect.website/docs/v4/concurrency/basic-concurrency)
- [Flix effects and handlers](https://doc.flix.dev/effects-and-handlers.html)
- [Polysemy Async 1.9.2.0](https://hackage.haskell.org/package/polysemy-1.9.2.0/docs/Polysemy-Async.html)
- [effectful Concurrent 2.6.1.0](https://hackage-content.haskell.org/package/effectful-2.6.1.0/docs/Effectful-Concurrent-Async.html)
- [purescript-run source](https://github.com/natefaubion/purescript-run)
