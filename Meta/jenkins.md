# Release Build

```
export LC_ALL="en_US.UTF-8"
pod install

[ -e build ] && rm -r build

./bin/build-macvim

xcodebuild -workspace VimR.xcworkspace -configuration Release -scheme VimR -derivedDataPath ./build clean build

VERSION=$(grep -A 1 CFBundleShortVersionString VimR/VimR-Info.plist | grep \<string\> | sed 's/.*<string>\(.*\)<\/string>/\1/')

cd build/Build/Products/Release
tar -cf VimR-$VERSION.tar VimR.app
bzip2 VimR-$VERSION.tar

tar -cjf dSYM-VimR-$VERSION.tar.bz2 VimR.app.dSYM

cd ../../../../

/usr/local/bin/sign_update.sh build/Build/Products/Release/VimR-$VERSION.tar.bz2 /Users/Shared/sparkle-priv.pem > build/sparkle-checksum.txt

du -ks build/Build/Products/Release/VimR-$VERSION.tar.bz2 | awk '{print $1*1024}' > build/size.txt
```

# Snapshot Build

```
./bin/increment_version.rb

export LC_ALL="en_US.UTF-8"

pod install

[ -e build ] && rm -r build

./bin/build-macvim

xcodebuild -workspace VimR.xcworkspace -configuration Release -scheme VimR -derivedDataPath ./build clean build

TODAY=$(date "+%Y%m%d-%H%M")
cd build/Build/Products/Release

tar -cjf VimR-$TODAY.tar.bz2 VimR.app
tar -cjf dSYM-VimR-$TODAY.tar.bz2 VimR.app.dSYM
```
