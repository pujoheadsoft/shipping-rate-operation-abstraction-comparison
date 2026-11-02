# 依存・失敗・非同期をどう表し、どう扱うか — 送料取得のサンプルコード

送料取得を題材に、処理に伴う依存・失敗・非同期をどう表し、表されたものをどう扱うかを見るためのサンプルコード集です。同じユースケースを複数の言語とライブラリで実装しています。

ここで比較したいのは、構文の違いや機能の多さではなく、次のような表現と扱い方の違いです。

- 処理が必要とする値や操作を、引数、closure、Reader、service、capability、effectなどのどこに表すか
- 起こりうる失敗を、例外、値、typed error、error effectなどでどう表し、どこで扱うか
- 非同期処理や並行処理をどの計算に含め、その結果・失敗・キャンセルをどう扱うか
- 操作を使う側と、その操作へ具体的な意味を与える側をどう分けるか

特定の方式が優れていると結論づけることや、各言語で可能な表現を網羅することは目的としていません。各ディレクトリは、その言語で採用した一つの表現例です。同じ言語でも、別の設計やライブラリを選べます。

## 共通ユースケース

各実装は、次の同じ処理を行います。

```text
UserId + Weight
  -> User APIから配送先郵便番号を取得
  -> Shipmentを組み立てる
  -> Carrier X / Y / Zから送料を並行取得
  -> 3社の送料から最安値を選ぶ
```

この共通処理を題材にすることで、業務ロジックの違いではなく、各言語やEffectシステムの設計上の違いを比較します。

## 実装一覧

| 実装 | 主な依存表現・仕組み |
|---|---|
| [Koka](koka/) | language effectとhandler |
| [Kyo](scala-kyo/) | `ArrowEffect`と`ContextEffect` |
| [Flix](flix/) | algebraic effect、region、`spawn` |
| [Haskell + Polysemy](haskell-polysemy/) | GADT effectとhigher-order `Async` |
| [Haskell + effectful](haskell-effectful/) | dynamic effectとunlifting |
| [PureScript](purescript-mtl/) | `ReaderT` / `ExceptT` / `Aff` |
| [PureScript + Run](purescript-run/) | extensible effect rowと静的並列batch |
| [TypeScript](typescript/) | closure、record、`Promise` |
| [TypeScript + Effect](typescript-effect/) | `Context.Service`、Layer、typed error |
| [OCaml + Eio capabilities](ocaml-eio-capabilities/) | record capabilityとstructured concurrency |
| [OCaml + Eio application effects](ocaml-eio-effects/) | extensible effectと明示的なrunner |

## 実装方針
設計はレイヤードアーキテクチャーを採用しています。
レイヤーは、ドメイン層・ユースケース層・ゲートウェイ層・インフラ層です。
ドメインについては意図的に完璧を目指していません。
例えばスマートコンストラクタのようなものは用意していませんし、ドメインロジックも送料のFCCから最安値を取り出すものだけです。
基本的に各実装においてレイヤーや責務などは合わせてあります。

実装の進め方ですが、まずすべてのベースとして Koka でコードを書きました。
これをもとに他言語の実装をAIに横展開させました。
（一部学習のため自分の手で書きたいものは敢えて手書きしましたが）
それをレビューして手直しを行っていて、細かい関数内の実装は各言語において「その言語らしさ」を求めてはいますが、どの程度実現できているかは私のその言語に対する習熟度によってまちまちであります。
より慣れた言語の方が、今の好みが反映されている感があります。

ちなみにこのREADMEの大半の部分はAIにまとめさせたものになります。

## 実行方法

各コマンドはリポジトリのルートで実行します。実装が接続するUser APIとCarrier X/Y/Z APIは、WireMockで起動できます。

```sh
make dependencies-up
```

そのうえで、見たい実装を一つ実行します。

```sh
make run-ts
make run-ps-mtl
make run-koka
make run-effect-ts
make run-kyo
make run-flix
make run-polysemy
make run-effectful
make run-ps-run
make run-ocaml-eio-capabilities
make run-ocaml-eio-effects
```

すべてのtoolchainが導入済みなら、全実装を順番に実行できます。

```sh
make run
```

終了後は、WireMockを停止します。

```sh
make dependencies-down
```

各実装には、それぞれの言語処理系とpackage managerが必要です。実際に使われるコマンドはルートの`Makefile`、READMEがある実装では個別の補足も参照してください。接続先は既定で`localhost:8081`〜`8084`で、`USER_API_BASE_URL`と`CARRIER_X_API_BASE_URL`、`CARRIER_Y_API_BASE_URL`、`CARRIER_Z_API_BASE_URL`により変更できます。

## このサンプルの見方

- 各実装では業務上の振る舞いを揃えています。違いが現れるのは、依存・失敗・非同期を表す型や、具体的な処理を与える場所です。
- operationやeffectを使う実装では、操作を宣言する場所、操作を使う場所、handlerやinterpreterを適用する場所を分けて見ると構造を追いやすくなります。
- 並行処理では、childがどの計算やenvironmentを保持するか、失敗やキャンセルを誰が扱うかにも注目します。
- ある実装で採用していない方法と、その言語やsystemでは実現できないことを区別します。

全体の違いは「Effectと並行実行の横断比較」、再現方法は「検証コマンド」、実装から得られた考察は「比較から得られた知見」にまとめています。

## 共通の比較条件

各実装に共通するapplication semanticsを基準にしています。

- 入力は`UserId`と`Weight`。User APIから配送先郵便番号を取得して`Shipment`を組み立てる。
- Carrier X/Y/Zは互いに異なるrequest/response契約を維持する。
- Gatewayは3社を並行取得し、X/Y/Z順ですべての`ShippingRate`を非空コレクションとして返す。
- `ShippingRate.carrier`は`CarrierX` / `CarrierY` / `CarrierZ`であり、service code/nameではない。
- Carrier失敗はGatewayで`FetchShippingRatesFailed`へ変換し、UseCaseは郵便番号または送料Portの失敗を`GetCheapestShippingRateFailed`へ変換する。配送先未登録だけは`ShippingDestinationNotFound`として区別する。
- UseCaseは3社の結果から最安値を選ぶ。同額ならX/Y/Z順で先に現れた送料を維持し、filter、sort、fallback、retryは行わない。

業務上の意味は全版で揃えた。通常のTypeScriptはDriverの技術的失敗をPromise rejectionとしてGatewayの`try/catch`で変換する。一方、他の実装では型付きの失敗値またはerror effectを用いて失敗を明示する。具体的な表現は`Result` / `Either` / OCamlの`result` / `Abort<E>` / `Error E` / Effect TSのtyped error channelなど、各systemで異なる。

## 証拠の表記

- **test**: 実際のbuild/testで確認した。
- **source**: 使用versionのlibrary sourceまたは当該実装から確認した。
- **docs**: 使用versionに対応する公式documentation/APIから確認した。
- **inference**: 上記からの設計上の推論。runtime testでは未確認。
- **unverified**: 今回は確認できていない。

「今回の標準APIで採用していない」と「system全体で不可能」は区別する。

## Effectと並行実行の横断比較

| System | Application dependency representation | Typed error | Concurrency | 未解釈application effectをchildに保持 | 必要な仕組み・解釈境界 | 根拠 |
|---|---|---|---|---|---|---|
| Koka | language effect (`carrier-x/y/z-api-client`) | `fail<E>`と`result` | `interleaved` | 可能 | handler scope内で`interleaved`を実行 | source/build。厳密なbarrier testは未追加 |
| Kyo | UseCaseは`ArrowEffect`、Carrierは`ContextEffect` | `Abort<E>` + API `Either` | `Async.zip` | 可能 | Carrier Driverを`handleInheritable`で提供 | test/source |
| Flix | language-native algebraic effect | `Result` | region + `spawn` + Channel | user-defined effectのままでは不可 | Carrier handlerを先に適用してprimitive effectへ変換 | compile-fail test/docs |
| Polysemy | GADT effect in `Sem r` | `Error E` | higher-order `Async` + `Resource` | 可能 | weaving、`Final IO`、child handleのbracket | overlap/cancel test + 1.9.2 source |
| effectful | dynamic effect in `Eff es` | static `Error E` | `Concurrent.concurrently` | 可能 | unliftingとchildへのenvironment継承 | overlap/cancel test + docs |
| PureScript Run | row-polymorphic first-order functor | `Either` | `FreeAp (Run r)`の静的batchを`ParAff`で実行 | 静的batch内では保持。実fiberには解釈後の`Aff`を渡す | `FreeAp`で並列batch、`Free`で逐次stepを表す`ParallelRun`。application edgeで自然変換を適用 | overlap/cancel/failure test + run 5.0.0 source |
| 既存PureScript | `ReaderT`による値依存 | `ExceptT`/`Either` | `Aff.parSequence` | 該当なし | `ReaderT Dependencies (ExceptT E Aff)`のbranchを並行化 | overlap test/source |
| TypeScript | closure/record | discriminated `Result`; 技術失敗はrejection | `Promise.all` | 該当なし | Promise runtimeがclosureを共有 | overlap test/source |
| TypeScript + Effect 4 | `Context.Service` requirement | `Effect<A, E, R>`の`E` | `Effect.all` (`unbounded`) | 可能。本実装ではservice取得後の閉じたbranchをfork | Gateway LayerがCarrier Layerをrequireし、Mainで提供 | overlap/cancel test + docs |
| OCaml + Eio capabilities | record capability | `result` | nested `Eio.Fiber.pair` | 該当なし | GatewayへCarrier recordsを明示的に渡す | overlap/cancel test + source |
| OCaml + Eio application effects | OCaml extensible effects | Carrierは`result`、Gateway失敗はeffect | application-defined `Parallel.All3`をEioで解釈 | handlerの暗黙継承はしない | polymorphic runnerで各childへCarrier handlersを再導入 | overlap/cancel test + source |

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

Flix 0.79.0では、未処理`Client` effectを含む式を`spawn`すると、`Client`とspawnが許すprimitive effects `(Chan + IO + NonDet)`をunifyできずcompile errorになる。このため各Carrier handlerをbranchへ先に適用し、IO computationへ変換してからregion内でspawnする。これはworkaroundではなく、effect exclusionが要求する解釈順である。

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

現在の実装は標準`Run`へ独自のfork operationを追加せず、`FreeAp (Run r)`を静的並列batchとして外側に置く。Gatewayの`fetchShippingRates`はCarrier X/Y/Zを未解釈の`Run` computationとしてbatchへ格納し、`NonEmpty Array`の構造とX/Y/Z順を維持する。Carrierの`Either`はApplicativeに結合されるため、1社が`Left`でも残りのbranchを完了してから`FetchShippingRatesFailed`となる。

UseCaseのような逐次処理との接続には、各stepを一つの`FreeAp` batchとして持つ`ParallelRun r = Free (FreeAp (Run r))`を使う。`ShippingRatePort` handlerはGatewayのbatchを`ParallelRun`へliftし、composition rootの`runParallel`が各batchへCarrier自然変換を適用して`Aff`へ解釈した後、`foldFreeAp (parallel <<< interpret)`で`ParAff`として実行する。したがって、未解釈Carrier effectは静的batchの記述には残るが、実際に起動されるfiberが保持するのは解釈後の`Aff`である。

AVar barrier testは未解釈Carrier branchから構成した3つの処理が実際にoverlapすることに加え、`Either Left`時に他branchを待つこと、親fiberのcancelが3 branchへ伝播すること、1 branchの`Aff` failureが待機中の兄弟branchを中断することを確認する。これはhigher-order concurrency effectをeffect rowへ追加した設計ではなく、Applicativeな静的batchとFreeによる逐次stepの組み合わせである。

### OCaml/Eioのcapabilityとapplication effect

`ocaml-eio-capabilities`はPortとCarrier clientをrecord of functionsとして表し、Gatewayが値として受け取る。並行処理はGatewayが`Eio.Fiber.pair`を直接呼ぶ。Eio runtimeが内部実装にOCaml effectsを使うことは、このapplication dependencyをeffect operationにすることとは別である。

`ocaml-eio-effects`はPort、Carrier client、Gateway失敗、3-way parallelをapplication-defined OCaml effectsとして表す。`Parallel.All3` handlerはEio child fiberを起動するが、外側のCarrier handlerがchildへ暗黙にapplication handlerとして継承されるとは扱わない。そのためpolymorphic runnerが各childをCarrier handlersで包み直す。このbridgeは比較のための実験的設計であり、標準的なOCaml/Eio application architectureとして推奨しているわけではない。

両OCaml版はDomain、Port、Gateway、Driver、effect runtimeの公開境界を`.mli`で固定し、依存関係を各opam fileへ宣言している。Carrier X/Y/ZすべてについてURL、request JSON、非2xx、response JSON decodeのDriver contract testを持つ。実行例はPiaf adapterを使い、User APIから配送先を取得して最安送料を表示する。

## 失敗とキャンセル

業務上の契約は全版で同じで、いずれかのCarrier失敗を`FetchShippingRatesFailed`へ変換する。現行Gateway testsは正常系とCarrier Y失敗を代表ケースとして確認する。X/Z/複数同時失敗を個別網羅するtestは未追加であり、比較実験上の残課題である。

runtime上のcancel semanticsは同じではない。

| System | 親cancel・child失敗の性質 | 今回の確認 |
|---|---|---|
| TypeScript | `Promise.all`はrejectionを返すが、標準では他Promiseをcancelしない | overlap test。cancelは未検証 |
| TypeScript + Effect | `Effect.all`のstructured fibers。失敗時は残りのFiberを中断し、Driverの`fetch`へ中断用`AbortSignal`を渡す | overlapと残り2 Fiberの中断をbarrier testで確認。HTTPへの伝播は未検証 |
| PureScript | `Aff` fiberはcancel可能。test workerは`bracket`でkill | overlapとtest cleanup。Carrier失敗時のsibling cancelは未検証 |
| PureScript Run | `runParallel`が各`FreeAp` batchを`ParAff`として実行 | overlap、親cancel、`Aff` failure時の兄弟cancelを確認。Carrierの`Either Left`は兄弟をcancelせず全件待機することも確認 |
| Koka | `interleaved`のruntime semanticsに従う | build/test。cancel専用testは未検証 |
| Kyo | `Async.zip`と`Scope`によるstructured cancellation | overlap/正常終了をtest。HTTP中cancelは未検証 |
| Flix | region終了までspawn childを管理 | timed barrier test。child例外/cancel専用testは未検証 |
| Polysemy | 標準`sequenceConcurrently`だけではscope管理不足。今回Resourceを追加 | 親cancel後の全child終了をtest |
| effectful | `concurrently`がstructured join/cancel | 親cancel後の全child終了をtest |
| OCaml + Eio capabilities | `Eio.Fiber.pair`のstructured concurrency | overlapと親cancel後の全3 child終了をtest |
| OCaml + Eio application effects | `Parallel.All3` handlerがnested `Eio.Fiber.pair`へ解釈 | 未解釈Carrier effectのoverlapと親cancel後の全3 child終了をtest |

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
- OCaml両版は注入可能なHTTP境界とAPIごとのJSON codecを持ち、実行例ではPiafによるEio HTTP/HTTPS adapterをUser APIと全3 Carrierへ接続する。Carrier Driver testはURL/body、status、JSON decodeを確認する。実通信の統合testは未追加である。
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
| Flix 0.79 | effect exclusionとregionが明快 | JVM利用可だがlanguage ecosystemは小さい | interpret-before-spawn制約、library選択 |
| Polysemy 1.9.2 | 表現力は高い | Haskell ecosystemを利用可能 | higher-order/local-state semantics、joinのfail-fast性、性能 |
| effectful 2.6 | IO志向で高性能、structured concurrencyあり | Haskell ecosystemを直接利用しやすい | dynamic handler資源のthread safety |
| PureScript Run | extensible first-order rowとApplicativeな静的batch | PureScript/Aff/JS ecosystem | `FreeAp` batchと`Free` stepの独自`ParallelRun`を理解する必要があり、一般的なdynamic fork/joinではない |
| 既存PureScript | transformer stackが一般的 | Aff/Fetchが直接使える | effect requirementの拡張性より単純さを優先 |
| TypeScript | closure/Promiseが最小 | ecosystem/deploymentが最も一般的 | typed effect rowなし、Promise sibling cancelなし |
| TypeScript + Effect 4 | typed error・requirements・structured concurrency | TypeScript/JS ecosystemを利用可能 | serviceは操作ADTではなくinterface。Layer設計の学習コスト |
| OCaml + Eio capabilities | record capabilityとstructured concurrencyが直接的 | OCaml/Eio + Piaf | 実HTTP中のcancel伝播は統合testで別途検証が必要 |
| OCaml + Eio application effects | application effectsとEio bridgeを明示できる | OCaml/Eio + Piaf | handler再導入用runnerが独自設計。effect rowによる静的追跡はない |

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
make test-ocaml-eio-capabilities
make test-ocaml-eio-effects
```

Flixの禁止例は通常test sourceへ含めず、次が意図的にcompile failureになることで確認する。

```sh
cd flix
java --enable-native-access=ALL-UNNAMED -jar flix.jar check compile-fail/UnhandledEffectInSpawn.flix
```

## 今回の検証状況

| Implementation | Build | Test | 未解決事項 |
|---|---|---|---|
| Koka | success | success (4/4) | HTTP実体は意図的にstub。cancel barrier未追加 |
| PureScript | success | success (5/5) | sibling cancellation、HTTP統合test |
| TypeScript | success | success (5/5) | Promiseに標準sibling cancellationなし、HTTP統合test |
| TypeScript + Effect 4.0.2 | success | success (12/12) | `AbortSignal`の実HTTPへの伝播、HTTP統合test |
| Kyo | success | success (6/6) | RC版。HTTP中cancelとHTTP統合test |
| Flix | success | success (10/10) | child failure/cancel test、HTTP統合test |
| Haskell + Polysemy | success | success (6/6) | 後順位child例外のfail-fast観測、HTTP統合test |
| Haskell + effectful | success | success (6/6) | handler資源のthread safety、HTTP統合test |
| PureScript + Run 5.0.0 | success | success (9/9) | `FreeAp`/`Free`による静的batch。dynamic fork/joinとHTTP統合testは対象外 |
| OCaml 5.3 + Eio 1.3 capabilities | success | success (17/17) | Piaf adapterの実通信・HTTP中cancel伝播は未統合test |
| OCaml 5.3 + Eio 1.3 application effects | success | success (17/17) | 独自runnerによるhandler再導入。Piaf adapterは未統合test |

## 比較から得られた知見

### 依存の抽象化と代数的effectは同義ではない

Dependency Inversionはclosure、record capability、Reader、service interface、effect operationのいずれでも実現できる。UseCaseやGatewayを具体Driverから分離するだけなら、代数的effectは必須ではない。一方、operationを未解釈の計算として保持し、interpreterの適用位置や継続の再開方法まで抽象化できるかは表現ごとに異なる。したがって「依存を差し替えられること」と「application operationをeffectとして扱うこと」は別の評価軸である。

### 並行処理との合成が方式の違いを顕在化させる

逐次的なUseCaseだけでは各方式の差は小さく見えるが、未解釈のCarrier computationを並行化すると、childが何を保持できるか、handlerやenvironmentをどう伝播するか、scope離脱や失敗時に誰がchildを中断するかを決める必要がある。Kokaはeffect rowを保ったまま並行化でき、Flixはhandlerを先に適用する必要がある。Polysemyとeffectfulはそれぞれweaving/unliftingを使い、OCaml application effects版は明示的なrunnerでhandlerを再導入する。PureScript Run版は一般的なfork effectではなく、未解釈operationを含む静的`FreeAp` batchをapplication edgeで`ParAff`へ解釈する。この並行境界が、各方式の表現力と制約を最も明確に示した。

### 表現力だけではproduction適性を判断できない

未解釈effectをchildへ渡せることや型へeffect requirementが現れることは有用だが、それだけでproduction上の優位は決まらない。既存I/O libraryとの接続、structured cancellation、resource scope、予期しない例外の扱い、handlerが共有する資源のthread safety、toolingとecosystem、独自interpreterの理解・保守コストを合わせて評価する必要がある。この比較では、実現できた設計、testで確認したruntime semantics、実通信やcancel伝播など未検証の運用境界を分けて扱うことが重要だった。

## 公式資料

- [Kyo core](https://getkyo.io/latest/kyo-core/)
- [Kyo HTTP](https://getkyo.io/latest/kyo-http/)
- [Effect: Managing Services](https://effect.website/docs/v4/requirements-management/services)
- [Effect: Managing Layers](https://effect.website/docs/v4/requirements-management/layers)
- [Effect: Basic Concurrency](https://effect.website/docs/v4/concurrency/basic-concurrency)
- [Flix effects and handlers](https://doc.flix.dev/effects-and-handlers.html)
- [Piaf HTTP client](https://github.com/anmonteiro/piaf)
- [Polysemy Async 1.9.2.0](https://hackage.haskell.org/package/polysemy-1.9.2.0/docs/Polysemy-Async.html)
- [effectful Concurrent 2.6.1.0](https://hackage-content.haskell.org/package/effectful-2.6.1.0/docs/Effectful-Concurrent-Async.html)
- [purescript-run source](https://github.com/natefaubion/purescript-run)
