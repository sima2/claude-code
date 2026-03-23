# claude-code dotfiles

Claude Code の設定ファイルです。

## ファイル

- `settings.json` — Claude Code のグローバル設定（statusLine、plugins など）
- `statusline-command.sh` — ステータスライン表示スクリプト

## ステータスライン

以下の情報を表示します：

```
~/dev | main | Claude Haiku | ctx:40% | 5h:8% 7d:24%
```

### 色の閾値

| 項目 | 黄色 | 赤 |
|------|------|----|
| ctx (コンテキスト使用率) | 70%以上 | 90%以上 |
| 5h / 7d (レートリミット) | 50%以上 | 80%以上 |

## 別のMacでのセットアップ

```bash
git clone git@github.com:sima2/claude-code.git ~/.claude-dotfiles
cp ~/.claude-dotfiles/settings.json ~/.claude/settings.json
cp ~/.claude-dotfiles/statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

## 更新

このMacで変更してpushするだけで他のMacに反映できます。

```bash
cd ~/.claude
git add settings.json statusline-command.sh
git commit -m "Update config"
git push
```
