#!/bin/bash
set -e

WDA_ROOT=$(dirname $0)/..
BUNDLE_VERSION="1.7.1D"

cd $WDA_ROOT
rm -rf DerivedData
xcodebuild \
    -project WebDriverAgent.xcodeproj \
    -scheme WebDriverAgentRunner \
    -derivedDataPath DerivedData \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO
pushd DerivedData/Build/Products/Debug-iphoneos
/usr/libexec/PlistBuddy \
    -c "set CFBundleShortVersionString $BUNDLE_VERSION" \
    WebDriverAgentRunner-Runner.app/Info.plist
mkdir Payload
mv WebDriverAgentRunner-Runner.app Payload
zip -r WebDriverAgent.ipa Payload
popd
mv DerivedData/Build/Products/Debug-iphoneos/WebDriverAgent.ipa .
