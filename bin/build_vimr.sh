#!/bin/bash
set -Eeuo pipefail

echo "### Building VimR target"
pushd "$( dirname "${BASH_SOURCE[0]}" )/.." > /dev/null

readonly deployment_target_file="./resources/macos_deployment_target.txt"
readonly deployment_target=$(cat ${deployment_target_file})
readonly code_sign=${code_sign:?"true or false"}
readonly use_carthage_cache=${use_carthage_cache:?"true or false"}
readonly build_path="./build"

# Carthage often crashes => do it at the beginning.
echo "### Updating carthage"
if [[ ${use_carthage_cache} == true ]]; then
    carthage update --cache-builds --platform macos
else
    carthage update --platform macos
fi

# Build NeoVim
# 0. Delete previously built things
# 1. Build normally to get the full runtime folder and copy it to the neovim's project root
# 2. Delete the build folder to re-configure
# 3. Build libnvim
pushd NvimView/neovim
    ln -f -s ../local.mk .

    rm -rf build
    make distclean

    echo "### Building nvim to get the complete runtime folder"
    rm -rf /tmp/nvim-runtime
    make \
        CFLAGS="-mmacosx-version-min=${deployment_target}" \
        MACOSX_DEPLOYMENT_TARGET=${deployment_target} \
        CMAKE_FLAGS="-DCUSTOM_UI=0 -DCMAKE_INSTALL_PREFIX=/tmp/nvim-runtime" \
        DEPS_CMAKE_FLAGS="-DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target} -DCMAKE_CXX_COMPILER=$(xcrun -find c++)" \
        install

    rm -rf build
    make clean

    ../../bin/build_libnvim.sh

    echo "### Copying runtime"
    rm -rf runtime
    cp -r /tmp/nvim-runtime/share/nvim/runtime .
popd > /dev/null

echo "### Xcodebuilding"

rm -rf ${build_path}

if [[ ${code_sign} == true ]] ; then
    identity="Developer ID Application: Tae Won Ha (H96Q2NKTQH)"
    entitlements_path=$(realpath NvimView/NvimServer/NvimServer.entitlements)

    xcodebuild \
        CODE_SIGN_IDENTITY="${identity}" \
        OTHER_CODE_SIGN_FLAGS="--timestamp --options=runtime" \
        CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
        -configuration Release -derivedDataPath ./build -workspace VimR.xcworkspace -scheme VimR clean build

    pushd ${build_path}/Build/Products/Release > /dev/null
        codesign --force -s "${identity}" --timestamp --options=runtime --entitlements="${entitlements_path}" \
            VimR.app/Contents/Frameworks/NvimView.framework/Versions/A/NvimServer
        codesign --force -s "${identity}" --timestamp --options=runtime VimR.app/Contents/Frameworks/NvimView.framework/Versions/A
        codesign --force -s "${identity}" --deep --timestamp --options=runtime VimR.app/Contents/Frameworks/Sparkle.framework/Versions/A/Resources/Autoupdate.app
        codesign --force -s "${identity}" --deep --timestamp --options=runtime VimR.app/Contents/Frameworks/Sparkle.framework/Versions/A
    popd > /dev/null
else
    xcodebuild -configuration Release -scheme VimR -workspace VimR.xcworkspace -derivedDataPath ${build_path} clean build
fi

popd > /dev/null
echo "### Built VimR target"
