#! /usr/bin/env bash

#
#     beaver build script
#
#     (c)2020-2021 naiad technology
#
#     build.sh
#

# set -e

# shellcheck disable=SC1090

function chk-command () {
    local chk_command="${1}"
    echo "[INFO] checking $chk_command"
    if type "${chk_command}" > /dev/null 2>&1; then
      echo ">>> ok"
    else
      echo ">>> not found!"
      ccho "[ERROR] $chk_command が使用できないため続行できません。中止します。"
      exit 1
    fi
}

# オプション解析
opts=("t:" "l:" "d") optl=("--target:" "--lang:" "--docker")
getopt=(-o "$(printf "%s," "${opts[@]}")" -l "$(printf "%s," "${optl[@]}")" -- "${@}")
getopt -Q "${getopt[@]}" || exit 1 # 引数エラー判定
readarray -t opt < <(getopt "${getopt[@]}") # 配列に代入
eval set -- "${opt[@]}" # 引数に設定
unset opts optl getopt opt # 使用した配列を削除

while true; do
  case "${1}" in
    "-t" | "--target") target="${2}"     && shift 2 ;;
    "-l" | "--lang"  ) lang="${2}"       && shift 2 ;;
    "-d" | "--docker") docker_build=true && shift 1 ;;
    "--"             ) shift 1           && break   ;;
    *) 
        echo "Unexpected error"
        exit 1
        ;;
  esac
done

# カレントディレクトリ取得
current_dir="$(cd "$(dirname "${0}")" && pwd)"

# sudo生存確認
chk-command sudo

# Dockerを使うかどうか
if [ "${docker_build}" = true ]; then

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
if [[ -z "${current_dir}" ]]; then
    echo "[ERROR] カレントディレクトリの取得に失敗しました。開発者に以下のコードとコマンドラインの出力を送信してください。"
    echo "(CriticalError: InvalidValue: current_dir="$current_dir")"
    exit 1
fi

# 引数をチェック
[[ -z "${target}" ]] && echo "[ERROR] ターゲットを指定してください" >&2 && exit 1

# プロファイルをチェック
if [ -d "${target}" ]; then
    echo "[INFO] ディレクトリ $target に移動します"
    cd "${target}" || exit 1
else
    echo "[ERROR] 指定したプロファイル（\"$target\"）が存在しません。中止します。"
    exit 1
fi

echo "[INFO] プロファイルに必要なファイルを確認しています"

if [ -f base.conf ] && [ -f main.packages ] && [ -f bootstrap.packages ]; then
   echo "[INFO] 必要なファイルの存在を確認しました"
else
   echo "[ERROR] プロファイルに必要なファイルが存在しません。中止します。"
   exit 1
fi


# 設定読み込み
echo "[INFO] base.confを読み込んでいます..."
source "./base.conf"

# 引数が指定されている場合、base.confから読み取った $locale の値を上書き
if [[ -n "${lang}" ]]; then
    locale=$lang
fi


# ローカライズ確認
if [ -d "I18n/${locale}" ]; then
    echo "[INFO] ローカライズ設定に $locale を使用します"
else
    echo  "[ERROR] ローカライズファイルのディレクトリ（I18n/${locale}）が見つかりません。中止します。"
    exit 1
fi

if [ -f "I18n/${locale}/locale.conf" ]; then
   echo "[INFO] ローカライズの設定ファイルに ${locale}/locale.conf を使用します。"
else
   echo "[ERROR] ローカライズ設定ファイル（I18n/$locale/locale.conf）が存在しません。中止します。"
   exit 1
fi

# ローカライズ設定読み込み
. "./I18n/$locale/locale.conf"

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

cp -r "${target}/root" "tmp/config/"
cp -r "${target}/I18n/${locale}/root" "tmp/config/"
cp "${target}/final_process.sh" "tmp/config/"
mv "tmp/config/final_process.sh" "tmp/config/config.sh"


# パッケージの数をカウント
packages_main_counts="$(sed '/^#/d' "${target}/main.packages" | wc -l)"
packages_bootstrap_counts="$(sed '/^#/d' "${target}/bootstrap.packages" | wc -l)"
packages_locale_counts="$(sed '/^#/d' "${target}/I18n/${locale}/locale.packages" | wc -l)"

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
while [[ $repository_counts -gt 1 ]]; do

    url_name="url${repository_counts}"
    {
        echo "    <repository>"
        echo "        <source path=\"""${!url_name}""\"/>"
        echo "    </repository>"
    } >> tmp/config/config.xml

    repository_counts=$(( repository_counts - 1 ))

done

# テンプレを追記
echo '    <packages type="image">' >> tmp/config/config.xml



# main.packagesのパッケージを追記
packages_main_counts=$(( packages_main_counts + 1 ))
while [[ $packages_main_counts -gt 0 ]]; do
    echo "        <package name=\"$(head -n $packages_main_counts tmp/beaver/main.packages.tmp | tail -n 1)\"/>" >> tmp/config/config.xml
    packages_main_counts=$(( packages_main_counts - 1 ))
done

# ローカライズパッケージを追記
packages_locale_counts=$(( packages_locale_counts + 1 ))
while [[ $packages_locale_counts -gt 0 ]]; do
    echo "        <package name=\"$(head -n $packages_locale_counts tmp/beaver/locale.packages.tmp | tail -n 1)\"/>" >> tmp/config/config.xml
    packages_locale_counts=$(( packages_locale_counts - 1))
done


# テンプレを追記
cat <<EOF >>  tmp/config/config.xml
    </packages>
    <packages type="bootstrap">
EOF


# bootstrap.packagesのパッケージを追記
packages_bootstrap_counts=$(( packages_bootstrap_counts + 1 ))
while [[ $packages_bootstrap_counts -gt 0 ]]; do
    echo "        <package name=\"$(head -n $packages_bootstrap_counts tmp/beaver/bootstrap.packages.tmp | tail -n 1)\"/>" >> tmp/config/config.xml
    packages_bootstrap_counts=$(( packages_bootstrap_counts - 1 ))
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
echo  "[INFO] kiwi-ngでのビルドを開始します"
sudo kiwi-ng system build --description $current_dir/tmp/config --target-dir $current_dir/out

if [ $? != 0 ]; then
    echo "[ERROR] kiwi-ngが終了コード0以外で終了しました。これはビルドが失敗したことを意味します。詳細なログを閲覧するには out/build/image-root.log を参照してください。"
    exit 1

fi


echo "[INFO] Done!"
