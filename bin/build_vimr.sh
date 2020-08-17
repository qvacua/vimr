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

./bin/download_nvimserver.sh

echo "### Xcodebuilding"

rm -rf ${build_path}

if [[ ${code_sign} == true ]] ; then
    identity="Developer ID Application: Tae Won Ha (H96Q2NKTQH)"
    entitlements_path=$(realpath Carthage/Build/Mac/NvimServer/NvimServer.entitlements)

    xcodebuild -configuration Release -derivedDataPath ./build -workspace VimR.xcworkspace -scheme VimR clean build

    pushd ${build_path}/Build/Products/Release > /dev/null
        codesign --force -s "${identity}" --deep --timestamp --options=runtime VimR.app
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
