#! /usr/bin/env bash

#
# (c)2020-2021 naiad technology
# build.sh
#

set -e

function chk-command () {
    chk_command=$1
    echo "[INFO] checking $chk_command" 
    if type $chk_command > /dev/null 2>&1; then
      echo ">>> ok"     
    else
      echo ">>> not found!"
      ccho "[ERROR] $chk_command が使用できないため続行できません。中止します。"
      exit 1
    fi
    
}

# 生存確認
chk-command kiwi-ng

# カレントディレクトリ取得
current_dir=$(cd $(dirname $0);pwd)

# ディレクトリ作成
sudo rm -rf tmp
mkdir tmp
cd tmp
mkdir out
cd ..

# kiwiでビルド
sudo kiwi-ng system build --description $current_dir/alexandrite/ --set-repo obs://openSUSE:Leap:15.3/standard --target-dir tmp/out

echo "[INFO] Done!"


