#!/bin/bash

set -e
lib_path="../../lib/"
source ${lib_path}path.sh
source ${lib_path}util.sh
source ${lib_path}upload_handler.sh

runner_name=$(get_runner)
version="1.3.6"
root_dir="$(pwd)"
source_dir="${root_dir}/libretro-super"
bin_dir="${root_dir}/retroarch"
cores_dir="${root_dir}/cores"
cpus=$(getconf _NPROCESSORS_ONLN)
arch=$(uname -m)

params=$(getopt -n $0 -o d --long dependencies -- "$@")
eval set -- $params
while true ; do
    case "$1" in
        -d|--dependencies) INSTALL_DEPS=1; shift ;;
        *) shift; break ;;
    esac
done

core="$1"

clone git://github.com/libretro/libretro-super.git $source_dir

mkdir -p ${bin_dir}

InstallDeps() {
    deps="build-essential libxkbcommon-dev zlib1g-dev libfreetype6-dev \
        libegl1-mesa-dev libgbm-dev nvidia-cg-toolkit nvidia-cg-dev libavcodec-dev \
        libsdl2-dev libsdl-image1.2-dev libxml2-dev"
    install_deps $deps
}

BuildRetroarch() {
    cd ${source_dir}
    SHALLOW_CLONE=1 ./libretro-fetch.sh retroarch
    cd ${source_dir}/retroarch
    ./configure
    make -j$cpus
    cp retroarch $bin_dir
    cp tools/cg2glsl.py ${bin_dir}/retroarch-cg2glsl
    cp -a media/assets ${bin_dir}
    rm -rf ${bin_dir}/assets/.git
}

BuildLibretroCore() {
    core="$1"
    cd ${source_dir}
    SHALLOW_CLONE=1 ./libretro-fetch.sh $core
    ./libretro-super.sh $core
    ./libretro-install.sh ${cores_dir}
}

PackageRetroarch() {
    cd $root_dir
    archive="${runner_name}-${version}-${arch}.tar.gz"
    tar czf $archive retroarch
}

PackageCore() {
    core=$1
    cd ${cores_dir}
    archive="libretro-${core}-${arch}.tar.gz"
    core_file="${core}_libretro.so"
    tar czf ../${archive} ${core_file}
    rm $core_file
}

if [ $INSTALL_DEPS ]; then
    InstallDeps
fi

if [ $1 ]; then
    BuildLibretroCore $1
    PackageCore $1
else
    BuildRetroarch
    PackageRetroarch
fi
