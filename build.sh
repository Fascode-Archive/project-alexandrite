#! /usr/bin/env bash

#
#     beaver build script
#
#     (c)2020-2021 naiad technology
#         
#     build.sh
#

# set -e

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

target=$1
current_dir=$(cd $(dirname $0);pwd)

chk-command kiwi-ng

# プロファイルをチェック

if [ -d ${target} ]; then
    echo "[INFO] ディレクトリ $target に移動します"
    cd $target
else
    echo "[ERROR] 指定したプロファイル（"$target"）が存在しません。中止します。"
    exit 1
fi

echo "[INFO] プロファイルに必要なファイルを確認しています"

if [ -f base.conf -a -f main.packages -a -f bootstrap.packages ]; then
   echo "[INFO] 必要なファイルの存在を確認しました"
else
   echo "[ERROR] プロファイルに必要なファイルが存在しません。中止します。"
   exit 1
fi

# 設定読み込み
echo "[INFO] base.confを読み込んでいます..."
. ./base.conf

# ローカライズ確認
if [ -d I18n/${locale} ]; then
    echo "[INFO] ローカライズ設定に $locale を使用します"
else
    echo  "[ERROR] ローカライズに必要なディレクトリが見つかりません。中止します。"
    exit 1
fi

if [ -f I18n/$locale/locale.conf ]; then
   echo "[INFO] ローカライズの設定ファイルに $locale/locale.conf を使用します。"
else
   echo "[ERROR] ローカライズ設定ファイルが存在しません。中止します。"
   exit 1
fi

# ローカライズ設定読み込み
. ./I18n/$locale/locale.conf

# 一時ディレクトリ作成
cd ..
echo "[INFO] 一時ディレクトリを作成します。"
sudo rm -rf  tmp out
mkdir tmp
mkdir out
mkdir tmp/kiwi
mkdir tmp/config

# 上書きファイルへのシンボリックリンクを貼る
echo  "[INFO] プロファイルからkiwi-ng向けの設定ファイルを生成しています。"
mkdir tmp/config/root

cp -r $target/root tmp/config/
cp -r $target/I18n/$locale/root tmp/config/
cp $target/final_process.sh tmp/config/
mv tmp/config/final_process.sh tmp/config/config.sh

# lndir.shが正常に作動しないため代替案を実装するまでcpで代用

# cd $target
# find root -type d | xargs -I{} mkdir -p tmp/config/root{}
# find I18n/$locale/root -type d | xargs -I{} mkdir -p tmp/config/root{}

# cd ..

# sh/lndir.sh $current_dir/$target/root tmp/config/root
# sh/lndir.sh $current_dir/$target/I18n/$locale/root tmp/config/root

# パッケージの数をカウント
packages_main_counts=$(sed '/^#/d' $target/main.packages | wc -l)
packages_bootstrap_counts=$(sed '/^#/d' $target/bootstrap.packages | wc -l)
packages_locale_counts=$(sed '/^#/d' $target/I18n/$locale/locale.packages | wc -l)

# コメントを除去したパッケージリストを作成
mkdir tmp/beaver

touch tmp/beaver/main.packages.tmp
echo "$(sed '/^#/d' $target/main.packages)" > tmp/beaver/main.packages.tmp

touch tmp/beaver/bootstrap.packages.tmp
echo "$(sed '/^#/d' $target/bootstrap.packages)" > tmp/beaver/bootstrap.packages.tmp

touch tmp/beaver/bootstrap.packages.tmp
echo "$(sed '/^#/d' $target/I18n/$locale/locale.packages)" > tmp/beaver/locale.packages.tmp

# xmlファイル生成
touch tmp/config/config.xml

# xml生成処理
cat <<EOF >  tmp/config/config.xml
<?xml version="1.0" encoding="utf-8"?>

<image schemaversion="$schemaversion" name="$name">
    <description type="system">
        <author>$author</author>
        <contact>$contact</contact>
        <specification>$specification</specification>
    </description>
    <profiles>
        <profile name="DracutLive" description="Simple Live image" import="true"/>
        <profile name="Live" description="Live image"/>
        <profile name="Virtual" description="Simple Disk image"/>
        <profile name="Disk" description="Expandable Disk image"/>
    </profiles>
    <preferences>
        <version>$version</version>
        <packagemanager>$packagemanager</packagemanager>
        <locale>$locale</locale>
        <keytable>$keytable</keytable>
        <timezone>$timezone</timezone>
        <rpm-excludedocs>$rpm_xcludedocs</rpm-excludedocs>
        <rpm-check-signatures>$rpm_check_signatures</rpm-check-signatures>
        <bootsplash-theme>$bootsplash_theme</bootsplash-theme>
        <bootloader-theme>$bootloader_theme</bootloader-theme>
        <type image="$image" flags="$flags" firmware="$firmware" kernelcmdline="$kernelcmdline" hybridpersistent_filesystem="$hybridpersistent_filesystem" hybridpersistent="$hybridpersistent" mediacheck="$mediacheck">
            <bootloader name="$bootloader" console="$console" timeout="$timeout"/>
        </type>
    </preferences>
    <users>
        <user password="$root_password" home="/root" name="root" groups="root"/>
        <user password="$liveuse_password" home="/home/$liveuser_name" name="$liveuser_name" groups="$liveuser_name"/>
    </users>
    <repository type="$repotype">
        <source path="$url1"/>
    </repository>
EOF


# レポジトリ追記
while [[ $repository_counts -gt 1 ]]
do
    
    url_name="url${repository_counts}"
    echo "    <repository>" >> tmp/config/config.xml
    echo "        <source path=\""${!url_name}"\"/>" >> tmp/config/config.xml
    echo "    </repository>" >> tmp/config/config.xml

    repository_counts=$(expr $repository_counts - 1)

done

# テンプレを追記
echo "    <packages type=\"image\">" >> tmp/config/config.xml


# main.packagesのパッケージを追記
packages_main_counts=$(expr $packages_main_counts + 1)
while [[ $packages_main_counts -gt 0 ]]
do
    echo "        <package name=\"$(head -n $packages_main_counts tmp/beaver/main.packages.tmp | tail -n 1)\"/>" >> tmp/config/config.xml
    packages_main_counts=$(expr $packages_main_counts - 1)
done

# ローカライズパッケージを追記
packages_locale_counts=$(expr $packages_locale_counts + 1)
while [[ $packages_locale_counts -gt 0 ]]
do
    echo "        <package name=\"$(head -n $packages_locale_counts tmp/beaver/locale.packages.tmp | tail -n 1)\"/>" >> tmp/config/config.xml
    packages_locale_counts=$(expr $packages_locale_counts - 1)
done

# テンプレを追記
cat <<EOF >>  tmp/config/config.xml
    </packages>
    <packages type="bootstrap">
EOF

# bootstrap.packagesのパッケージを追記
packages_bootstrap_counts=$(expr $packages_bootstrap_counts + 1)
while [[ $packages_bootstrap_counts -gt 0 ]]
do
    echo "        <package name=\"$(head -n $packages_bootstrap_counts tmp/beaver/bootstrap.packages.tmp | tail -n 1)\"/>" >> tmp/config/config.xml
    packages_bootstrap_counts=$(expr $packages_bootstrap_counts - 1)
done

# テンプレを追記
cat <<EOF >>  tmp/config/config.xml
    </packages>
</image>
EOF

# kiwi-ngでビルド
echo  "[INFO] kiwi-ngでのビルドを開始します"
sudo kiwi-ng system build --description $current_dir/tmp/config --target-dir $current_dir/out

if [ $? != 0 ]; then
    echo "[ERROR] kiwi-ngが終了コード0以外で終了しました。これはビルドが失敗したことを意味します。"
    exit 1
fi

echo "[INFO] Done!"
