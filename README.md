# PCの下の力持ち

メモリ使用率に応じて、メニューバーの中で重量挙げをする小さなキャラクターです。  
あなたのPCを陰で支えてくれます。

| メモリ使用率 | 状態 | アニメ |
| --- | --- | --- |
| 〜20%  | 余裕！ (笑顔でダンベル超高速) | 0.4秒/回 |
| 20〜40% | 軽い軽い (笑顔でダンベル) | 0.9秒/回 |
| 40〜60% | ふつう (普通の表情でダンベル) | 1.6秒/回 |
| 60〜80% | ぐぬぬ… (バーベルで食いしばり) | 3.2秒/回 |
| 80〜90% | 上がらん！！ (途中で停止＋汗) | 静止 |
| 90%〜  | ぺしゃんこ… (バーベルに潰される) | 静止 |

## 動作環境

- macOS 13 (Ventura) 以降
- Apple Silicon / Intel どちらも可
- Xcode Command Line Tools (Xcode 本体は不要)

Command Line Tools が入っていない場合:

```bash
xcode-select --install
```

確認:

```bash
swift --version   # Apple Swift version 5.9 以上が出れば OK
```

## インストール

```bash
git clone https://github.com/KazukiKondou/pc-no-shita-no-chikaramochi.git
cd pc-no-shita-no-chikaramochi
./build-app.sh
```

`build-app.sh` がやること:

1. `swift build -c release` でビルド (実機アーキテクチャを自動検出)
2. `PCの下の力持ち.app` を組み立て
3. ad-hoc 署名 (`codesign --sign -`) を付与
4. `~/Applications/PCの下の力持ち.app` にコピー
5. `xattr -dr com.apple.quarantine` で隔離属性を解除
6. Spotlight インデックスを更新

完了後は `⌘ + Space` → 「PCの下の力持ち」 と入力すれば起動できます。

### 初回起動時の警告について

ad-hoc 署名のみで Apple Notarization は通していないので、初回ダブルクリックすると
「開発元を検証できないため開けません」 と Gatekeeper の警告が出ます。一度だけ
以下のいずれかで許可すれば、以後はそのまま起動できます:

- **A.** Finder で `~/Applications/PCの下の力持ち.app` を **Control + クリック → 「開く」**
- **B.** 警告ダイアログを閉じた後に、 **システム設定 > プライバシーとセキュリティ** を開く
  → 一番下に「"PCの下の力持ち" は開発元が確認できないためブロックされました」
  → 「このまま開く」をクリック

## 起動 / 終了

- **起動:** Spotlight、Launchpad、または `open ~/Applications/PCの下の力持ち.app`
- **終了:** メニューバーのキャラをクリック → 「終了」 (`⌘ + Q`)

## ログイン時に自動起動したい

`~/Library/LaunchAgents/` に launchd plist を置く方法が手軽です。

```bash
cat > ~/Library/LaunchAgents/com.kondo.pc-no-shita-no-chikaramochi.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.kondo.pc-no-shita-no-chikaramochi</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/$(whoami)/Applications/PCの下の力持ち.app/Contents/MacOS/PCNoShitaNoChikaramochi</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.kondo.pc-no-shita-no-chikaramochi.plist
```

止めたい時:

```bash
launchctl unload ~/Library/LaunchAgents/com.kondo.pc-no-shita-no-chikaramochi.plist
```

## 仕組み

- メモリ使用率は `host_statistics64(HOST_VM_INFO64)` で取得 (active + wire + compressor / total)
- キャラはすべて SwiftUI の `Canvas` でベクター描画 (画像アセットなし)
- メニューバー埋め込みは `NSStatusItem.button` に `NSHostingView` を subview として追加
- アニメーションは 30fps の Timer で三角波 (0→1→0) を生成

## ライセンス

MIT
