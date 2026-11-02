# TypeScript + Effect

Effect 4によって、User APIから配送先を取得し、3社の送料から最安値を返すユースケースを実装した版。

## 境界

- `usecase`: `PostalCodePort`と`ShippingRatePort`を宣言する。配送先未登録を区別し、それ以外のPort失敗をユースケース失敗へ変換して最安値を選ぶ。
- `gateway`: User APIとCarrier X/Y/Zの技術非依存な契約を宣言し、各PortのLive Layerでドメインへ変換する。
- `driver`: API clientを実装し、URL、HTTP、JSONとwire DTOを扱う。
- `main`: Driver LayerをGateway Layerへ渡し、アプリケーションを実行する。

Gateway Layerは構築時にUser/Carrierサービスを取得する。そのため、提供後のPortは下位のAPI requirementを外へ漏らさない。Carrier取得は`Effect.all`で並行実行し、結果のX/Y/Z順を維持する。

## 実行

```sh
npm install
npm run format
npm run typecheck
npm test
npm start
```

既定ではUser APIとCarrier APIへ`localhost:8081`〜`8084`で接続する。各base URLは環境変数で上書きできる。
