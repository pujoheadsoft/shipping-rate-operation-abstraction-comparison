# TypeScript + Effect

Effect 4によって、同じ送料取得ユースケースを実装した版。

## 境界

- `usecase`: `ShippingRatePort`を宣言し、ユースケース失敗へ変換する。
- `gateway`: Carrier X/Y/Zのポートを宣言し、リクエスト・レスポンスとドメインを変換する。`ShippingRatePort`のLive Layerもここで構築する。
- `driver`: Carrierポートを実装し、URL、HTTP、JSONを扱う。
- `main`: Driver LayerをGateway Layerへ渡し、アプリケーションを実行する。

Gateway Layerは構築時にCarrierサービスを取得する。そのため、提供後の`ShippingRatePort.fetchShippingRates`はCarrier requirementを外へ漏らさない。

## 実行

```sh
npm install
npm run format
npm run typecheck
npm test
npm start
```

実在しないCarrier URLを使うため、`npm start`のHTTPアクセスは失敗する。
