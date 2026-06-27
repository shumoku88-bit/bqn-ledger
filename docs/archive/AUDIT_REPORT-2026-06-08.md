# shumoku88-bit/bqn-ledger 監査報告 (2026-06-08)

## 監査の結論
このリポジトリは、**「正データは TSV、表示と派生値は BQN で再計算」**という基本方針がかなり強く守られており、日常運用システムとしての骨格は安定しているのだ。特に、journal.tsv・plan.tsv・budget_alloc.tsv・accounts.tsv を正データとし、report_tx_updates.bqn で一元ロード・検証し、report_engine.bqn で各レポートへ配る流れは明快で、安全寄りの設計になっているのだ。

一方で、今回の重点項目に照らすと、今すぐ文書か仕様を揃えた方がよいズレがいくつかあるのだ。いちばん大きいのは、budget_alloc.tsv を「予算配賦の source of truth」と説明している一方で、実装では plan.tsv 内の budget↔budget 行も budget レイヤへ取り込めること、そして 封筒枯渇予測が“安全側一貫”ではなく、保守的な要素と楽観的な要素が混ざっていることなのだ。

結論としては、設計は良い、実装も大筋で筋が通っている、ただし「封筒予測」「plan の事前控除」「ledger/hledger エクスポート」「AI 向け作業ルール」の境界定義がまだ文書側で追いついていない、という評価になるのだ。

## 現在の設計の要約
このシステムの中心は、journal.tsv を実績、plan.tsv を未来予定、budget_alloc.tsv を手動の予算配賦、accounts.tsv を勘定科目とメタ情報のマスタとして扱い、そこからレポートや各種 export を派生させる構成なのだ。README・ROADMAP・ARCHITECTURE はこの点でほぼ一致していて、派生ファイルを正データ化しないという原則も明示されているのだ。

実装上は、report_tx_updates.bqn が accounts.tsv・journal.tsv・plan.tsv・budget_alloc.tsv をすべて読み、strict check を通し、tx_updates : T×256×2 と day_updates/day_balances を作る単一の入力境界になっているのだ。そこから report_engine.bqn が as_of 時点のスナップショットを切り出し、残高・サイクル集計・outlook・daily trend・envelope trend へ配っているのだ。

journal.tsv の役割は、あくまで現実の複式簿記上の実績なのだ。core.GetTxUpd は、From/To/Amount から Actual 列を作りつつ、To 側の費目に accounts.tsv で budget=<name> が付いている場合だけ、対応する budget:<name> -> budget:spent の予算消費を Intent/Budget 列に自動導出しているのだ。

plan.tsv の役割は、現状の実装では未来予定の明示行であって、recur や anchor などのメタは人間整理用の比重が高く、一般的な自動展開エンジンにはまだなっていないのだ。実際、plan.tsv は future payments 表示・cycle consultation・固定費 reserve・封筒予測の planned spend などに使われるが、繰り返しメタ自体の自動展開は行っていないのだ。

budget_alloc.tsv は、README・PLAN・ARCHITECTURE では封筒配賦の手動正データとして位置づけられているのだ。また、その最初の日付が「予算運用開始日」になり、それ以前の journal.tsv 支出は予算消費としてカウントしない仕様も、文書と実装が一致しているのだ。

## 安全に見える点
まず強いのは、正データ TSV と派生ビューの境界が実装でも明確なことなのだ。report_engine は直接 TSV を散発的に読まず、report_tx_updates.BuildDays を基点にしている。これは「どこで読み、どこで検証し、どこで派生するか」が追いやすく、日常運用で壊れにくい構成なのだ。

次に、予算レイヤを Actual から切り離している点はかなり安全なのだ。report_tx_updates は journal 由来の update を作った後、budget:* 勘定の Actual 列を一括ゼロ化している。そのため、封筒や intent の都合が現実資産の残高へ混入しにくいのだ。複式簿記の現実レイヤと生活管理レイヤを混ぜすぎない、という ROADMAP の思想にも合っているのだ。

検査系も堅いのだ。tools/lint_journal_like.bqn は、必須列の空欄、整数 amount、暦として妥当な日付、既知 account、key=value 形式のメタを見ている。tools/lint_accounts.bqn は空 account 名、重複、256 上限、budget=<name> の参照先、budget:spent の存在まで見ている。運用データを人力編集する前提なら、この lint の厚さはかなり安心材料になるのだ。

tools/check.sh も、単に main.bqn を叩くだけでなく、summary/export 群、check-tx-updates、check-trend-liquid、fixture を回しているので、少なくとも3D 配列エンジン導入で崩れやすい部分は見張れているのだ。

現行データでも、accounts.tsv 上の assets:* には type=... が、変動費には spend_class=variable と budget=... が入っており、readiness check が想定する metadata 整備水準は満たしているのだ。

## 危険または曖昧な点
いちばん大きい論点は、budget_alloc.tsv が本当に予算配賦の唯一の source of truth なのかという点なのだ。文書は一貫して「手動 truth は budget_alloc.tsv」と言っているのに、実装では plan.tsv の budget↔budget 行を budget_plan_rows として切り出し、tx_update_mats に普通に足しているのだ。つまり、仕様上は plan.tsv も budget movement を持ちうる。この時点で、「配賦の正データは budget_alloc.tsv だけ」という説明は厳密には崩れているのだ。

封筒の枯渇予測も、完全に安全側とは言い切れないのだ。保守的な面としては、直近 spend 平均に加えて、サイクル内の future planned spending を envelope ごとに差し引いており、journal が as_of に追いついていない場合でも last_actual_dn より後の plan を見るので、未記帳日の予定を残しやすいのだ。
ただし楽観的な面もある。trend_dns は day_view.day_nums から作るので、budget_alloc-only の日も平均窓に入る一方、avg_spend 自体は journal 由来 change だけで計算している。その結果、配賦日や budget move 日が 0 支出日として混ざり、平均消費が薄まりうるのだ。さらに avg_spend ← floor(sum/window) で平均を切り下げているので、残日数推定は短くではなく長めに出やすいのだ。したがって、この予測は「安全側固定」ではなく、保守/楽観が混ざる heuristic と見るのが妥当なのだ。

加えて、cycle 境界の扱いが envelope trend だけ微妙に違うのも危ないのだ。cycle 自体は end_exclusive を使う排他的終端で、report_cycle_metrics も dn < cycle_end_excl_dn で集計している。report_trend の fixed reserve も future fixed を < cycle_end_excl_dn で見る。ところが report_envelope_trend の planned spend 抽出だけは plan_dates ≤ cycle_end_dn になっていて、排他終端の日付そのものを含めるのだ。今の plan.tsv では 6/15 の行が固定費中心なので envelope への影響は小さいが、将来 6/15 に variable + budget mapped な予定を置くと、他セクションと envelope forecast だけサイクル境界が食い違うのだ。

plan.tsv の「事前控除」仕様も、システム全体で一本化されていないのだ。outlook は future plan を一覧表示するが、liq_daily 自体は liquid total を残日数で割るだけで、future plan を差し引かない。daily-trend は future fixed だけ reserve として控除する。envelope trend は budget mapped な future expense だけ控除する。cycle-consult は netting せず、登録済み予定を別枠表示する。つまり「plan は事前控除される」のではなく、セクションごとに別ルールで扱われるのだ。日常運用上これ自体はあり得るが、ユーザー文書にはもっと強く明示した方がよいのだ。

export-ledger.sh は、「実績 journal の最小二重記帳 export」としては妥当なのだ。accounts.tsv を account directive 化し、journal.tsv の各行を To 側 amount + From 側省略 posting に変換しており、Ledger が省略額 posting でバランスを推論できるやり方自体は ledger/hledger の範囲に収まっているのだ。
ただし、TSV の意味を壊す具体的なケースが現実データにもう存在するのだ。journal.tsv には 食品 ; method: amazonにんにくまとめ買い という memo があり、export script はそれをそのまま transaction header に出す。hledger では transaction description は「セミコロンまで」で、セミコロン以降は same-line comment と解釈されるので、memo の文字列意味が変わってしまうのだ。Ledger 側も ; を transaction/comment syntax に使うので、少なくとも互換 export としてはmemo の無加工出力は危険なのだ。

さらに export-ledger.sh は lint や strict check を自前では走らせない。tools/check.sh 経由なら事前に lint が当たるが、スクリプト単体ではファイル存在確認しかしないので、単独利用時の安全性は README/AGENTS/docs で明示した方がよいのだ。

最後に、初期導入時の Bootstrap では、空の journal.tsv をどこまで許容するかが曖昧なのだ。report_outlook.bqn は last_journal_date ← 0 ⊑ ¯1 ⊑ journal_rows としていて、空 journal を前提にしていないように見える。文書では empty journal を明確に禁止していないので、この点は運用上の暗黙要件になっているのだ。

## 実装とドキュメントのズレ
いちばん明確なのは、docs/REPORT_FIELD_MAP.md が「現在の return field は 56 個」と書いているのに、実際の report_engine.bqn は 63 個返しており、しかも env_names、env_history_bal、env_history_daily、env_current_bal、env_avg_spend、env_days_until_empty、env_is_critical の 7 フィールドが表から落ちていることなのだ。封筒健康診断が新規追加された今、ここは即同期した方がよいのだ。

docs/AI_CODEMAP.md も一部古いのだ。cycle-consult について、「例外的に report_sections.bqn に軽い集計が残っており、育てるなら report_cycle_consult.bqn へ切り出す」と書いているが、TODO ではすでに切り出し完了になっていて、実装でも report_sections.bqn は report_cycle_consult.bqn を import しているのだ。

同じく docs/AI_CODEMAP.md の report_balances.bqn 説明は、「実績行と予算移動行から 256×2 の bal_final を作る」と読めるが、現実の report_balances.bqn は bal_final を生成せず、渡された balance matrix を集約するだけなのだ。3D 配列エンジン導入後の責務分割に、文書が少し追いついていないのだ。

docs/ROADMAP.md には bqn tools/export-ledger.bqn > journal.ledger とあるが、実在するのは tools/export-ledger.sh なのだ。この差は運用導線を誤らせるので、README か docs/README あたりでも現行の export 入口を明記した方がよいのだ。

README 末尾の core.bqn 説明にある BuildMatrix も、現行構成には存在しないのだ。実際の中心は report_tx_updates.bqn の tx_updates/day_updates/day_balances で、README のこの説明は 3D 配列エンジン導入前の名残に見えるのだ。

TODO.md の Done に forecast.bqn という名前が残っているが、現行の outlook ロジックは report_outlook.bqn と main.bqn --section outlook に寄っている。これも古い名前の残り香で、学習導線としては紛らわしいのだ。

加えて、docs/REPORT_DESIGN.md の「想定モジュール構成」は目安と明記されているものの、report_snapshot.bqn・report_ytd.bqn など現在存在しない名前が並ぶため、新規参加者が “現行構成” と誤読しやすいのだ。これは重大バグではないが、docs/ARCHITECTURE との役割分担をもっと強く分けて書いた方がよいのだ。

## 追加した方がよいテスト
まず tools/check.sh には、新しく増えた “封筒健康診断” を直接叩く確認が足りないのだ。現状は outlook、check-tx-updates、check-trend-liquid、fixture の cycle-consult と recent はあるが、main.bqn --section envelopes 自体は回していない。封筒予測が今回の重点なら、ここは最低限入れたいのだ。

次に必要なのは、plan.tsv に budget↔budget 行がある場合の境界テストなのだ。いまの実装はそれを budget layer に取り込むのに、文書は budget_alloc.tsv を手動 truth としている。このズレを放置するなら「許容仕様」を明文化し、放置しないなら fixture を作って失敗させるべきなのだ。

封筒予測については、少なくとも次の 3 パターンが欲しいのだ。
ひとつめは、budget_alloc-only の日が直近 3 日窓に混ざるケース。今の平均消費はその 0 日を含むので、予測が楽観化しないかを見たいのだ。
ふたつめは、平均消費が割り切れないケース。floor(sum/window) の切り下げが安全側かどうかを regression として固定した方がよいのだ。
みっつめは、cycle 終端日そのものに variable の plan を置くケース。report_trend/cycle-consult/envelope trend が同じ境界解釈になるのかを確認したいのだ。

export-ledger.sh には、memo にセミコロンを含む fixtureが要るのだ。現データですでにそのケースがあり、互換 export では transaction description/comment の意味が変質しうる。少なくとも「このケースは未対応」なのか「エスケープすべき」なのかをテストで固定した方がよいのだ。

それから、empty journal の bootstrap fixtureも入れたいのだ。もし未対応なら明示仕様にし、対応したいなら report_outlook.bqn の空配列前提を潰すべきだと判断できるのだ。

最後に、ドキュメント同期用の軽い検査も相性がよいのだ。具体的には、report_engine.bqn の公開 field 数と docs/REPORT_FIELD_MAP.md の表項目数を比べるだけでも、今回のような 56→63 のズレはすぐ拾えるのだ。

## AGENTS.md に足すとよい作業ルール
現行の AGENTS.md は短くて入口としては良いのだが、AI が壊しやすい境界をもう少し明文化した方がよいのだ。第一に、journal-like TSV を読むときは SplitKeepEmpty を使うことをルール化したいのだ。空 memo で列ずれする問題はすでに fixture 化されていて、ここは AI がうっかり再発明しやすい部分なのだ。

第二に、report_engine の公開 field や main の section key を変えたら docs/REPORT_FIELD_MAP.md と docs/MAIN_SECTIONS.md を必ず更新する、というルールを AGENTS に昇格した方がよいのだ。現状、その義務は各 docs に散っていて、中央の作業入口には明示されていないのだ。

第三に、budget_alloc.tsv を予算配賦 truth とする前提を壊す変更は、docs と test を同時更新することを明記したいのだ。とくに plan.tsv に budget↔budget を入れるかどうかは、今のままだと AI が判断を広げやすいのだ。

第四に、封筒・trend・cycle 境界を触る変更では tools/check-tx-updates.bqn と tools/check-trend-liquid.bqn だけで十分と見なさない、という注意もあるとよいのだ。今回の envelope trend のように、新機能は既存ブリッジチェックの網から漏れやすいのだ。

第五に、tools/export-ledger.sh は “actual journal の最小 export” であって、budget/plan/meta まで保存する互換 export ではないことを AGENTS に書いておくと、AI が script を過大評価して関連 docs を誤更新しにくくなるのだ。

## 今すぐ直すべきものと、後でよいもの
今すぐ直すべきなのは、まず 仕様の不一致を利用者と AI の前で閉じることなのだ。具体的には、budget_alloc.tsv と plan.tsv の budget move 境界を明示すること、REPORT_FIELD_MAP を 63 field に合わせること、AI_CODEMAP の cycle-consult と report_balances 説明を現状へ同期すること、README の BuildMatrix と ROADMAP の export-ledger.bqn を直すこと。このあたりはコード変更ではなく、誤解を防ぐための監査修正として優先度が高いのだ。

その次に急ぐべきなのは、封筒予測の意味づけの明文化なのだ。現在の実装は useful だが、「安全側保証」ではなく heuristic であること、outlook/daily-trend/envelope/cycle-consult で plan.tsv の使い方が違うことを README か docs/REPORT_DESIGN.md にはっきり書いた方が、日常運用での誤読を減らせるのだ。

後でよいものは、YTD が実装上は全期間集計である点の名称整理、REPORT_DESIGN の仮モジュール名の整理、empty journal bootstrap の正式方針決定あたりなのだ。これらは混乱の種ではあるが、直ちに日常運用の安全性を壊すものではないのだ。

hledger / ledger 互換 export については、今のままでも actual journal の検算用途としては使えるのだ。ただし、それは「家計簿全体の検算」ではなく、journal.tsv 由来の実績二重記帳を外部書式に流すための最小出口という射程に限るのだ。budget layer、plan layer、metadata まで含めた完全 mirror ではないことは、むしろ今のうちに強く書いておいた方が安全なのだ。
