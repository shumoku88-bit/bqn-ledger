# fixtures/empty-fields

空フィールドを含む journal-like TSV の確認用fixtureです。

## 目的

- 空の摘要（2列目）があっても、`from` / `to` / `amount` が左に詰まらないことを確認する。
- `core.SplitKeepEmpty` を使う journal-like parser の安全網にする。

## 代表行

```tsv
2026-01-02		assets:bank	expenses:food	1200
```

この行は摘要が空です。古い `Split` だけで読むと空列が落ち、列位置がずれる可能性があります。

## 確認コマンド

```sh
(cd fixtures/empty-fields && bqn ../../tools/lint.bqn)
bqn main.bqn fixtures/empty-fields --as-of 2026-01-03 --section recent
```
