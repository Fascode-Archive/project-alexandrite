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

# オプション解析
while getopts t:l:d OPT
do
  case $OPT in
    "t" ) FLG_T="TRUE" ; VALUE_T="$OPTARG" ;;
    "l" ) FLG_L="TRUE" ; VALUE_L="$OPTARG" ;;
    "d" ) FLG_D="TRUE" ;;
  esac
done


if [ "$FLG_T" = "TRUE" ]; then
    target=$VALUE_T
fi

if [ "$FLG_L" = "TRUE" ]; then
    lang=$VALUE_L
fi

if [ "$FLG_D" = "TRUE" ]; then
    docker_build=true
fi


# カレントディレクトリ取得
current_dir=$(cd $(dirname $0);pwd)

# sudo生存確認
chk-command sudo

# Dockerを使うかどうか
if [ $docker_build = true ]; then

    echo "[INFO] ビルドにDockerを利用します。"
    docker_build=true
    chk-command docker

    if [ -z "$(sudo docker container ls -q -a -f name="beaver_build")" ]; then
        docker_ready=false
    else
        docker_ready=true
    fi

else
    echo "[INFO] ローカル環境でビルドします。"
    docker_build=false
    chk-command kiwi-ng
fi

# カレントディレクトリが取得できてるか（事故防止）
if [ -z "$current_dir" ]; then
    echo "[ERROR] カレントディレクトリの取得に失敗しました。開発者に以下のコードとコマンドラインの出力を送信してください。"
    echo "(CriticalError: InvalidValue: current_dir="$current_dir")"
    exit 1
fi

# プロファイルをチェック
if [ -z "$target" ]; then
    echo  "[ERROR] プロファイルが指定されていません。-t オプションでビルドしたいプロファイルのディレクトリ名を指定してください。"
    exit 1
fi

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

# 引数が指定されている場合、base.confから読み取った $locale の値を上書き
if [ -n "$lang" ]; then
    locale=$lang
fi


# ローカライズ確認
if [ -z "$locale" ]; then
    echo  "[ERROR] リージョンが指定されていません。-l オプションで指定するか、locale.conf内のlocaleの値で設定する必要があります。"
    exit 1
fi

if [ -d I18n/${locale} ]; then
    echo "[INFO] ローカライズ設定に $locale を使用します"
else
    echo  "[ERROR] ローカライズファイルのディレクトリ（I18n/${locale}）が見つかりません。中止します。"
    exit 1
fi

if [ -f I18n/$locale/locale.conf ]; then
   echo "[INFO] ローカライズの設定ファイルに $locale/locale.conf を使用します。"
else
   echo "[ERROR] ローカライズ設定ファイル（I18n/$locale/locale.conf）が存在しません。中止します。"
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

echo  "[INFO] config.xmlを生成します"

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
        <user password="$root_password" pwdformat="plain" home="/root" name="root" groups="root"/>
        <user password="$liveuser_password" pwdformat="plain" home="/home/$liveuser_name" name="$liveuser_name" groups="$liveuser_name"/>
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

# dockerを準備
if [ $docker_ready = false ]; then
    echo "[INFO] Dockerのコンテナを作成します"
    sudo docker pull opensuse/tumbleweed
    sudo docker run -i -t -d --name beaver_build opensuse/tumbleweed
    sudo docker exec -i -t beaver_build zypper -n refresh
    sudo docker exec -i -t beaver_build zypper -n install python3-kiwi checkmedia util-linux
fi

# kiwi-ngでビルド

if [ $docker_build = true ]; then

    echo "[INFO] Dockerコンテナを起動します"
    sudo docker start beaver_build

    echo "[INFO] Dockerコンテナにファイルをコピーしています"
    sudo docker exec -i -t beaver_build rm -rf /tmp/beaver
    sudo docker exec -i -t beaver_build mkdir -p /tmp/beaver/out
    sudo docker cp $current_dir/tmp/config beaver_build:/tmp/beaver

    echo "[INFO] Docker内のkiwi-ngでのビルドを開始します"
    sudo docker exec -i -t beaver_build kiwi-ng system build --description /tmp/beaver/config --target-dir /tmp/beaver/out

    echo "[INFO] Dockerのコンテナからファイルをコピーします"
    sudo docker cp beaver_build:/tmp/beaver/out/* $current_dir/out

    echo "[INFO] Dockerのコンテナを停止します"
    sudo docker stop beaver_build


elif [ $docker_build = false ]; then

    echo  "[INFO] kiwi-ngでのビルドを開始します"
    sudo kiwi-ng system build --description $current_dir/tmp/config --target-dir $current_dir/out

    if [ $? != 0 ]; then
        echo "[ERROR] kiwi-ngが終了コード0以外で終了しました。これはビルドが失敗したことを意味します。詳細なログを閲覧するには out/build/image-root.log を参照してください。"
        exit 1
    fi

else

    echo "[ERROR] 内部エラーによりビルド開始に失敗しました。docker_buildの値が不正です。開発者に以下のコードとコマンドラインの出力を送信してください。"
    echo "(CriticalError: InvalidValue: docker_build="$docker_build")"
    exit 1

fi



cd $current_dir
#sudo rm -rf tmp

echo "[INFO] Done!"
