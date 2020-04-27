# ni-pack for xyzzy

これは何
--------
xyzzyの拡張LispのGitリポジトリからNetInstaller向けに配布できるようにするやつ。


依存するライブラリなど
----------------------
- [ansify](https://github.com/bowbow99/xyzzy.ansify)
- [NetInstaller](http://www7a.biglobe.ne.jp/~hat/xyzzy/ni.html)

その他に必要なもの
------------------
- Git for Windows


インストール
------------
TODO: 配布できるようにしたら書く


準備と設定
----------
ローカルに以下のものを用意する必要があります。

- ローカルサイト
  - SITE-DIR: 配布物を置くディレクトリ
  - SITE-FILE: 配布物リストファイル（`packages.l`）
- 拡張の Git リポジトリ
  - リポジトリのルートからそのまま zip で固められるように配置する
  - ルートに `README.md`
    - その他のファイルも含めて、ルート直下にあるファイルは `site-lisp/<拡張名>/` に移動される
  - lisp ファイルは `./site-lisp/` 以下に置く
  - MAIN-SOURCE: メインの lisp ファイル `./site-lisp/<拡張名>.l`
    - TODO: ヘッダの書き方

`SITE-FILE` は無ければ `ni-pack::create-local-site` で作成することもできます。


上記が用意出来たら、`.xyzzy` などで

    (require "ni-pack")
    (setf ni-pack:*local-site-directory* "~/path/to/SITE-DIR")

他に設定できる項目は以下のものがあります。

- `ni-pack:*local-site-file*`
  - 設定しなければ `<SITE-DIR>/packages.l` になります。
  - それ以外のファイルを使用する場合は、そのファイルのパスを設定してください。
- `ni-pack:*site-base-url*`
  - 配布物を置くディレクトリのURLです。各配布物をダウンロードするURLに使用されます。
  - 設定しなければサイトの URL が使用されます。
  - それ以外の場所に配布物を置く場合は、その URL を指定します。
- `ni-pack:*temp-directory*`
  - 配布物を作成する際に仕様する一時ディレクトリです。
  - 指定しなければ、環境変数 `TMP` が使用されます。


使い方
------

1. 拡張を作る
  - Gitで管理してください
  - リリースできる状態にしてください
2. `M-x ni-pack:release`
  - ファイル名を聞かれるので、`<MAIN-SOURCE>` を指定します。
  - ざっくり言うと以下のように処理されます
    - リポジトリを一時ディレクトリにクローンして `.git` 等を削除
    - ルート直下にあるファイルを `site-lisp/<拡張名>/` へ移動
    - lispファイルを全てコンパイル
    - zip で固めて `<SITE-DIR>/<拡張名>-<バージョン>.zip` を作成
    - `<SITE-FILE>` を更新
3. 公開場所へアップロードしてください


ライセンス
----------
[MIT](COPYING.mit)
