ABSPATH=$(cd "$(dirname "$0")"; pwd)
cd $ABSPATH

#create build directory
path=../../../productionReadyBins/"$(date +%Y-%m%d-%H%M%S)"
mkdir -p $path

#prepare log file names
bvtLogPath=../$path/BVTLog.txt

#prepare test framework
cd BVT
unzip -o GHUnitIOS.framework.zip
sudo rm -rf RunTests.sh
unzip -o RunTests.sh.zip
cd IosSdkTests
unzip -o png.zip
cd ..

echo "***************Build and run BVT *****************" 2>&1 | tee -a $bvtLogPath
GHUNIT_CLI=1 xcodebuild -scheme IosSdkTests -destination 'platform=iOS Simulator,name=iPhone 6s' -configuration Debug -sdk iphonesimulator9.3 clean build 2>&1 | tee -a $bvtLogPath

grep "with 0 failures" $bvtLogPath &> /dev/null
if [ "$?" != "0" ]; then
    echo "**************IOS SDK BVT Failed*******************" 2>&1 | tee -a $bvtLogPath
    exit 1
fi
zip -r ../$path/WindowsAzureMessaging.framework.zip WindowsAzureMessaging.framework
echo "===================================================" 2>&1 | tee -a $bvtLogPath
lipo -info WindowsAzureMessaging.framework/WindowsAzureMessaging 2>&1 | tee -a $bvtLogPath
echo "***************IOS SDK BVT Passed *****************" 2>&1 | tee -a $bvtLogPath