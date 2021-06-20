#! /usr/bin/env bash

#
# (c)2020-2021 naiad technology
# build.sh
#

set -e

# config.xmlが入ってるディレクトリ名
distro_dir=alexandrite


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
mkdir tmp/out

# kiwiでビルド
sudo kiwi-ng system build --description $current_dir/$distro_dir/ --target-dir tmp/out

echo "[INFO] Done!"
