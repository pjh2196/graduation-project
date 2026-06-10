# POS / 店舗アプリについて

この `pos` フォルダは、以前作成した検証用の Streamlit 版 POS 画面です。

現在の最新版の店舗アプリは、iOS アプリ側に統合しています。

最新版の店舗アプリ関連ファイルは以下です。

- `MiniMyizer/Views/PosView.swift`
- `MiniMyizer/Views/QRScannerView.swift`
- `MiniMyizer/Network/APIClient.swift`
- `MiniMyizer/Network/PaymentRecord.swift`

今回の主な更新内容は以下です。

- 店舗アプリ側に返品・取消機能を追加
- 顧客アプリの履歴詳細に表示される返品・取消用QRを読み取り、取引IDを取得
- `/cancel-confirmed-payment` API を呼び出して確定済み取引を取消
- 取消完了時に「お客様へ返金する現金」を表示
- 取引完了・キャンセル完了・返品取消完了の表示を独自ポップアップに変更

そのため、現在の実装確認は `pos` フォルダではなく、ルート直下の `MiniMyizer` プロジェクトを確認してください。
