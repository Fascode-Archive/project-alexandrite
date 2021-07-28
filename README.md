# alexandrite os
![image](https://raw.githubusercontent.com/nexryai/project-alexandrite/main/img/Alexandrite.png) <br>
kiwiを利用してビルドするOpen SUSEベースの安定していて美しいLinuxディストリビューション<br>
<br>
[English version](https://github.com/nexryai/project-alexandrite/blob/main/docs/README_en.md)

## 特徴
サーバーやワークステーションで使用されている堅牢なOpen SUSEをベースに開発されたLinuxディストリビューション。”日常使用に最適なOS” を念頭に安定性、デザイン、必要最低限のプリインストールソフトウエア、長期使用に重点を置いて開発されています。naiad linuxで得たフィードバックや経験を活かして開発されています。エレガントなGnomeデスクトップを採用。初期状態で拡張機能が整備されているので簡単に操作できます。<br>
<br>
![image](https://raw.githubusercontent.com/nexryai/project-alexandrite/main/img/desktop1.png) <br> <br>
![image](https://raw.githubusercontent.com/nexryai/project-alexandrite/main/img/desktop2.png)

## 重要な通知
live環境のユーザー名は`live`パスワードは`root7`です。

## ロードマップ

### 0.1.0 (highway)
公開済み。2021年7月に公開。OSとして最低限の機能を搭載。

### 0.1.1 (highway)
公開済み。beta1のplymouthの不具合を修正したもの

### 0.20 (brave)
公開済み。GRUBテーマの不具合を修正しbeaverを使用してビルドする方式に変更。デザインの大幅な刷新。

### 0.30 
開発中。不具合の修正と安定性向上。

## ビルド方法
### 依存関係
kiwi-ng (インストールについてのヘルプは https://osinside.github.io/kiwi/installation.html を参照してください)

### 手順
`./build.sh alexandrite`を実行すれば自動的にビルドが完了します。

### beaverについて
beaverはkiwi-ngを使いやすくする簡易的なラッパーです。AlexanditeOS向けに最適化されているため一部のkiwi-ngの機能は制限されますがAlexandrite OSを簡単に改造できます。

## その他
このプログラムはGPLライセンスで公開されています。使用は完全な自己責任です。その他問い合わせはTwitter @nexryai までお願いします。
