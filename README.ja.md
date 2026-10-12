<div align="center">

<img src="website/public/img/app-icon-180.png" width="128" height="128" alt="RightKit アイコン" />

# RightKit

**macOS Finder のための高機能右クリックツールボックス。右クリックひとつで、すぐ完了。**

軽量、ネイティブ、ピュア。最新の SwiftUI と軽量なシステム機能拡張で構築された Finder コンテキストメニュー拡張ユーティリティ。

<p>
  <a href="README.md">简体中文</a> •
  <a href="README.en.md">English</a> •
  <a href="README.ja.md"><strong>日本語</strong></a> •
  <a href="README.ko.md">한국어</a>
</p>

[![macOS 26+](https://img.shields.io/badge/macOS-26%2B-000000?style=flat&logo=apple&logoColor=white)](https://rightkit.yiliang.app/ja/)
[![Swift 6](https://img.shields.io/badge/Swift-6.0-F05138?style=flat&logo=swift&logoColor=white)](https://swift.org)
[![Mac App Store](https://img.shields.io/badge/Mac_App_Store-Available-007AFF?style=flat&logo=apple&logoColor=white)](https://apps.apple.com/app/id6816212746)
[![GitHub Release](https://img.shields.io/badge/Release-0.1.3-34C759?style=flat)](https://github.com/AquaHydro/rightkit/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-FF8F6C?style=flat)](LICENSE)
[![App Sandbox](https://img.shields.io/badge/App_Sandbox-Enabled-2A2B31?style=flat)](docs/technical.md)

[公式サイト](https://rightkit.yiliang.app/ja/) · [Mac App Store で購入](https://apps.apple.com/app/id6816212746) · [公式サイト版 DMG をダウンロード](https://github.com/AquaHydro/rightkit/releases/latest) · [機能仕様](docs/features.md) · [デザイン仕様](DESIGN.md) · [技術境界](docs/technical.md)

</div>

---

<p align="center">
  <img src="docs/evidence/app-store/en/01-new-file.png" alt="RightKit プレビュー" width="880" />
</p>

## 💡 RightKit を選ぶ理由

macOS の Finder はシンプルで洗練されていますが、日常の頻繁な操作では手数が多くなりがちです。新規テキストや表計算ファイルを作るのに一度アプリを起動したり、ターミナルでパスへ移動するために `cd` を打ち込んだり、ファイルの整理でフォルダウインドウを並べて行ったり、ハッシュ確認や画像変換のために別のツールを探したりする必要があります。

**RightKit** は、これらの頻出ワークフローを右クリックメニューの中にすっきりと集約します。

- **ネイティブで自然なデザイン**：Apple の Human Interface Guidelines に準拠し、余計な装飾を排して macOS の Finder とシームレスに調和します。
- **ミリ秒単位の応答性**：メインアプリと Finder 機能拡張を明確に分離した軽量設計。起動時の事前ウォームアップとビットマップキャッシュにより、右クリック時に一切の引っかかりを生じさせません。
- **コンテキストに応じたスマート表示**：選択中の対象（空白部分、単一ファイル、複数フォルダ、画像ファイルなど）を自動判別し、その状況で使えるコマンドのみをスマートに組み立てます。
- **App Sandbox と完全ローカル処理**：完全に App Sandbox 内で動作し、ユーザーが明示的に許可した監視フォルダのみにアクセスします。外部通信やデータ収集は一切行いません。
- **システム保護領域の安全ガード**：完全削除には確認ダイアログが付き、ルート `/` やユーザーのホームフォルダ、システムフォルダは保護対象として安全にガードされます。

---

## ✨ 主な機能

### 1. 新規ファイル (New File)

右クリックしたその場所で、必要な文書を即座に作成。

- **12 種類の組み込み形式**：テキスト（.txt）、Markdown（.md）、リッチテキスト（.rtf）、Word（.docx）、Excel（.xlsx）、PowerPoint（.pptx）、JSON、XML、HTML、CSS、JavaScript、シェルスクリプト（.sh）。
- **カスタムテンプレート**：よく使うドキュメントをテンプレートとして追加可能。作成時には完全な複製をその場に展開します。
- **同名ファイルの自動番号付け**：すでに同じファイル名がある場合は自動で連番を付与（例：`名称未設定 2.docx`）。既存のファイルを上書きすることはありません。
- **柔軟な動作設定**：「作成前にファイル名を確認」「作成後にデフォルトアプリで自動的に開く」のオン・オフを切り替え可能。

<p align="center">
  <img src="docs/evidence/app-store/en/01-new-file.png" alt="新規ファイルのプレビュー" width="820" />
</p>

### 2. カット、コピー先、移動先 (Cut, Copy & Move)

Finder でのファイル整理をより快適にする操作体系。

- **右クリックでカット＆ペースト**：項目を選んで「カット」し、移動先フォルダで「ペースト」すればそのまま移動が完了。専用の待避リストを使用し、システムのクリップボードを汚しません。
- **送り先フォルダのプリセット**：よく使う保存先フォルダを登録しておけば、サブメニューからワンステップで「コピー先」または「移動先」へ転送できます。
- **よく使うフォルダの即時起動**：フォルダの空白部分で右クリックして、登録済みのディレクトリへ素早くジャンプ。
- **進行状況表示**：転送に1秒以上かかる大きなファイルや大量の項目の処理では、ネイティブの進行状況ウインドウが表示され、安全にキャンセルできます。

<p align="center">
  <img src="docs/evidence/app-store/en/02-move-to.png" alt="移動とコピーのプレビュー" width="820" />
</p>

### 3. アプリで開く (Open in App)

開発者やデザイナー、効率を重視するユーザーのための機能。

- **コンテキスト自動判定**：ファイルを選択した場合はエディタで開き、フォルダを選択した場合はターミナルがそのフォルダを作業ディレクトリとして直接開きます。
- **主要ツールの自動検出**：ターミナル（Terminal）、Ghostty、Visual Studio Code、Xcode を自動検出。システム内の任意の `.app` も手動で追加できます。
- **安全な呼び出し**：システムの Workspace API を通じて安全に起動し、シェルコマンドの文字列連結を行いません。

<p align="center">
  <img src="docs/evidence/app-store/en/03-open-in-app.png" alt="アプリで開くのプレビュー" width="820" />
</p>

### 4. 16 個のファイルツール (Toolbox)

日常的なファイル操作に便利な 16 種類のツールを搭載。設定で個別にオン・オフやグループ内の並べ替えが可能です。

| グループ | コマンド名 | 内容 |
| --- | --- | --- |
| **パスと名称** | パスをコピー、名前をコピー | 選択項目の POSIX パスや表示名をコピー。空白部分では「現在のパスをコピー」 |
| **整理・共有** | 名前からフォルダを作成 | ファイル名と同じ名前のフォルダを新規作成し、そのファイルを中へ移動 |
| | エイリアスをデスクトップに作成 | 選択した項目のエイリアスをデスクトップへすばやく作成 |
| | AirDrop | システム標準の AirDrop 共有シートを呼び出してすばやく送信 |
| | 書き込み権限を付与 | 現在のユーザーに選択項目の書き込み権限を付与（所有者は変更せず、非再帰的） |
| | ファイル情報（ハッシュ） | MD5、SHA-1、SHA-256、SHA-512 をローカルでストリーミング計算して表示 |
| **表示設定** | 選択項目を非表示または表示 | ターミナルコマンドを使わずにファイルの不可視属性を切り替え |
| | 拡張子を非表示または表示 | Finder 上でのファイル拡張子の表示・非表示を切り替え |
| **画像とアイコン** | 画像を変換 | PNG、JPEG、HEIC、TIFF の各形式へ素早く相互変換 |
| | macOS アイコンセットを作成 | `.iconset` フォルダと標準の `.icns` ファイルを一度に生成 |
| | iOS アイコンセットを作成 | 主要な 13 サイズを揃えた iOS アプリアイコンフォルダを書き出し |
| | 壁紙に設定、フォルダアイコンを設定 | 選択した画像をデスクトップ壁紙に適用、またはフォルダの独自アイコンに設定 |
| **安全な削除** | フォルダを解除 | フォルダ内の直接の項目を親フォルダへ引き上げ、空になったフォルダをゴミ箱へ移動 |
| | 完全に削除 | ゴミ箱を経由せずに直接削除。確認ダイアログとシステム保護機能付き |

<p align="center">
  <img src="docs/evidence/app-store/en/04-toolbox.png" alt="ツールボックスのプレビュー" width="820" />
</p>

### 5. コンテキストメニューにとどまらない連携

- **ショートカットと Spotlight**：新規ファイル、ハッシュ計算、画像変換、アイコン生成、QR コード作成などをシステムの自動化ワークフローへ統合。
- **macOS システムサービス**：
  - **オフライン QR コード作成**：選択テキストから高解像度 QR コードを端末内で安全に生成。PNG 保存や画像コピーに対応。
  - **Web 翻訳サービス**：選択テキストを Google 翻訳や Baidu 翻訳で素早く検索。
- **多言語対応**：日本語、英語、簡体字中国語、韓国語にネイティブ対応。システム設定に自動追従、またはアプリ内で切り替え可能。

---

## 📥 入手とインストール

RightKit は同一のコードベースから 2 つのチャンネルで提供されています。

| 項目 | Mac App Store（ストア版） | 公式サイト版（GitHub Release） |
| --- | --- | --- |
| **入手方法** | [Mac App Store で購入](https://apps.apple.com/app/id6816212746) | [GitHub Releases から無料ダウンロード (DMG)](https://github.com/AquaHydro/rightkit/releases/latest) |
| **対象** | App Store で一括管理したい方、個人開発を応援していただける方 | 手動で DMG からインストールしたい方 |
| **機能差分** | すべての機能を利用可能 | すべての機能を利用可能 |
| **アップデート** | Mac App Store 経由で自動サイレント更新 | アプリ内で最新 Release をチェックし、ワンクリックで案内 |
| **サンドボックス** | App Sandbox 有効 | App Sandbox 有効 |

### 初回利用時の設定手順

macOS のセキュリティ設計に基づき、初回起動時に以下の 2 点を設定してください：

1. **監視フォルダのアクセス許可**：RightKit を起動し、ようこそウインドウまたは設定の「一般」で「個人フォルダへのアクセスを許可」（ホームフォルダ全体を推奨）をクリックして許可します。RightKit は許可されたフォルダ内でのみメニューを表示します。
2. **Finder 機能拡張を有効化**：「システム設定 → 一般 → ログイン項目と機能拡張」を開き、「Finder 機能拡張」の一覧で RightKit をオンにします。

設定ウインドウの「一般」タブには、機能拡張の動作状態（「有効」「未実行」「バックグラウンドサービス停止」「無効」）を示すカードがあり、必要に応じてシステム設定へのショートカットや Finder の再起動を行えます。

<p align="center">
  <img src="docs/evidence/app-store/en/05-settings.png" alt="設定ウインドウと状態カード" width="820" />
</p>

---

## 🛡️ プライバシーとセキュリティ

1. **厳格な App Sandbox**：メインアプリと機能拡張の両方がサンドボックス内で実行されます。ネットワーク権限は最小限に抑えられています（ストア版はネットワーク権限なし、公式サイト版は GitHub API への更新確認のみ）。
2. **Security-Scoped Bookmarks**：フォルダアクセスは macOS 標準のセキュリティスコープ付きブックマークに依存し、ユーザーが許可していない外部パスへアクセスすることはできません。
3. **システム保護パスの防護**：ルート `/`、ホームフォルダ、`/System`、`/Library`、`/usr` などの重要領域に対しては「完全に削除」の実行を防止する仕組みを備えています。
4. **追跡・分析の完全排除**：アナリティクス SDK、クラッシュ報告ライブラリ、トラッカーなどは一切組み込まれていません。操作したファイル名やパスが送信されることはありません。

---

## 🛠️ アーキテクチャとエンジニアリング

プロジェクトは 4 つの明確なターゲットに分割されています：

```text
RightKit (Workspace)
├── RightKit          # SwiftUI メインアプリ：設定、確認ダイアログ、ファイル I/O 処理、ショートカット、システムサービスを担当
├── RightKitFinder    # 軽量 Finder Sync 機能拡張：監視フォルダを管理し、ミリ秒単位でコンテキストメニューを構築してメインアプリへ通知
├── RightKitAgent     # LaunchAgent デーモン：App Group XPC サービスをホストし、メニュー操作時に確実にメインアプリを呼び出し
└── RightKitCore      # 純粋な Swift ロジックパッケージ：メニュー規則、モデル、保護パス判定、リネーム計算を 100% のテスト網羅率で実装
```

### 機能拡張のパフォーマンス最適化

Finder Sync 機能拡張の実装に不備があると、Finder 全体の動作が重くなる原因になります。RightKit では以下の最適化を徹底しています：
- **メニュー生成時の重い I/O 排除**：メニューコールバック内でファイル読み書き、ハッシュ計算、高負荷処理を行いません。
- **事前ウォームアップ**：拡張の起動時や設定変更時に裏でメニュー構造を事前生成し、アイコンサービスへの接続を済ませておくことで初回の右クリックの遅延を抑えます。
- **16 pt 2x 単一解像度ビットマップ**：プロセス間通信で Finder に渡すアイコンを単一解像度ビットマップに正規化し、転送オーバーヘッドを最小限に抑えています。

---

## 🔨 ローカルビルドと開発

### 動作要件

- macOS 26 以降
- Xcode 27 以降
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)（プロジェクト構造は `project.yml` で管理されています）

### 主な Make コマンド

```sh
# Xcode プロジェクトを生成し、全テストを実行し、両チャンネルのビルドと仕様検証を実施
make verify

# Debug ターゲットをビルドして即座に起動
make run

# 公式サイト版をビルド（Developer ID 署名、公証、DMG パッケージング。出力先は .build/release/）
make release

# ストア版をビルド（アーカイブ、.pkg の書き出し、署名検査。出力先は .build/release-appstore/）
make release-appstore

# ストア版を App Store Connect へアップロード
make upload-appstore
```

### ドキュメント構成

コードの変更や確認の際は、以下の仕様書を参照してください：

- [機能仕様 (docs/features.md)](docs/features.md)：すべての機能の挙動、初期値、メニュー表示ルール、エラーメッセージ。
- [デザイン仕様 (DESIGN.md)](DESIGN.md)：配色、タイポグラフィ、コンポーネント規格。
- [技術境界 (docs/technical.md)](docs/technical.md)：プロセス分割、App Group 通信、サンドボックス権限、リリース仕様。
- [検証基準 (docs/verification.md)](docs/verification.md)：テストケースと品質基準。
- [ロードマップ (docs/roadmap.md)](docs/roadmap.md)：開発の順序とマイルストーン。

ドキュメントの整合性チェック：

```sh
python3 scripts/check_docs.py
```

---

## 🎬 公式ミュージックアニメ MV：『右クリックの向こう』

RightKit のデザイン哲学と世界観を表現するため、ブランドマスコット Riko のオリジナルアニメ MV **『Under the Right Click · 右クリックの向こう』** を制作しました（再生時間 3分28秒、170 BPM J-rock アニメ OP）。

<p align="center">
  <img src="website/assets/character/hero-pv-poster-ak.png" alt="『右クリックの向こう』ポスター" width="820" />
</p>

### ストーリーと製品のメタファー：失序のアーカイブ・シティ

> 「指先 宙に浮かべて カーソルが光る。三本のライン それだけを信じて。3、2、1…… Right click! 世界の裏側を開いて。」

舞台は無数のファイルキャビネットで築かれた「アーカイブ・シティ」。「エントロピーの波」が押し寄せ、ビルは崩壊し、名前を失ったファイルが雪のように舞い散ります。街のアーキビストである **Riko** は、右クリックの力で重なるメニュー（新規作成・コピー・移動）を展開。乱れたファイルを元の引き出しへと還し、夜明けとともにエントロピーを 0.0% へとリセットします。

どんなに深いフォルダでファイルが迷子になっても、右クリックひとつですべてが元の場所へ戻る。RightKit の製品思想をそのままアニメーションとして昇華させました。

### 独自の「riso-cel」リペイントパイプライン

MV のレンダリングエンジンコードは本リポジトリに含まれています：
- **シェーダーによる質感再現**：WebGL シェーダー（Kuwahara フィルタ、XDoG による 12 fps 手ブレ墨線、45° ハーフトーン網点、リソグラフ紙の風合い）を通して、90年代セル画と孔版印刷の質感を再現。
- **パイプライン公開**：[`mv/under-the-right-click/`](mv/under-the-right-click/README.md) にて、ヘッドレスブラウザによるコマ落ちなしのレンダリング、歌詞タイムライン、および詳細な [絵コンテ表 (STORYBOARD.md)](mv/under-the-right-click/STORYBOARD.md) をご覧いただけます。

<p align="center">
  <img src="mv/under-the-right-click/qa/contact-sheet.jpg" alt="『右クリックの向こう』コンタクトシート" width="820" />
</p>

---

## 🎨 ブランドキャラクターと素材ライセンス

RightKit のブランドマスコットは **Riko** です。コーラルピンクのグラデーションヘアとアホ毛、マウスカーソル＆メニュー型のヘアピンがトレードマークの、明るく頼れるアシスタントです。

- **ソースコードと文書**：[MIT ライセンス](LICENSE) のもとで公開されています。
- **ブランド資産の保護**：RightKit の名称、Riko のキャラクター画像、アプリアイコン、メニューバーアイコン、オリジナルイラスト、動画などの素材はすべての権利を保持しています。詳細は [素材ライセンス規約 (ASSETS.md)](ASSETS.md) および [MV 許諾表示 (mv/under-the-right-click/NOTICE.md)](mv/under-the-right-click/NOTICE.md) をご覧ください。オープンソース公開は、ブランド素材の無断転載や他プロダクトでの使用を許可するものではありません。
- **サードパーティ製アイコン**：[サードパーティ表示 (THIRD_PARTY_NOTICES.md)](THIRD_PARTY_NOTICES.md) および [アプリアイコン出典 (website/assets/apps/SOURCES.md)](website/assets/apps/SOURCES.md) をご参照ください。

---

## 💬 フィードバックとコミュニティ

- **Issue の投稿**：バグの報告や機能のご提案は [GitHub Issues](https://github.com/AquaHydro/rightkit/issues) にて受け付けています。
- **お問い合わせ**：メール `contact@yiliang.me` までご連絡ください。
- **開発者**：[Liao Yiliang (氢氧根)](https://rightkit.yiliang.app/ja/) によって個人開発されています。
