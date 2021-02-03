#gradle=/usr/local/Cellar/gradle/4.10/libexec/bin/gradle

rm -rf baseApk getVersion.py version
cd InstagramBoostAndroid
git clean -fx
gradle ${Module_Name}:clean

#先执行prefix混淆任务 打包relase和debug两个版本
if [[ ! $Flavor ]]; then

    #混淆资源的apk
    gradle ${Module_Name}:assemble${Flavor}Release
else
    gradle ${Module_Name}:assembleRelease
fi


#工作区存取所有项目apk
if [ ! -d "../apks" ]; then
   mkdir -p ../apks
fi

#存档文件    ../上一级目录
if [ ! -d "../baseApk" ]; then
   mkdir -p ../baseApk
fi
#进入下一级目录 {}表示查到的文件 
cd ${Module_Name}
cd build
cd outputs
cd apk
if [[ $Flavor ]]; then
    cd ${Flavor}
fi
find ./ -name "*.apk" -exec cp {} /Users/build/.jenkins/jobs/InsAndroid_S5/workspace/baseApk \;
find ./ -name "*.json" -exec cp {} /Users/build/.jenkins/jobs/InsAndroid_S5/workspace/baseApk \;
#存入apks
find ./ -name "*.apk" -exec cp {} /Users/build/.jenkins/jobs/InsAndroid_S5/workspace/apks \;

#提取mapping文件
if [[ $Flavor ]]; then
    cd ../
fi
cd ../
cd mapping
if [[ $Flavor ]]; then
    cd ${Flavor}
fi
cd release
find ./ -name "*.txt" -exec cp {} /Users/build/.jenkins/jobs/InsAndroid_S5/workspace/baseApk \;


cat << EOF > ./getVersion.py
import os,re,datetime
os.chdir("/home/ec2-user/environment/jenkins");print os.getcwd()
if not os.path.exists('./baseApk'):
    print os.getcwd()
    print 'getVersion.py: baseApk is empty!';exit()
os.chdir('./baseApk')
d,timestamp,baseapkdir="empty-version-json-file",datetime.datetime.now().strftime('%Y%m%d%H%M%S'),os.listdir(".")
for file in baseapkdir:
    print file
    if "json" in file:
        with open("./{}".format(file),"r") as dump_file:
            with open("../version","w") as version_file:
                d=re.findall('(?<=versionName\"\:\")\w*\.\w*\.\w*',dump_file.readline())
                d=d[0] if d else 'empty-version-json-file'
                print 'versionName:'+ str(d)
                version_file.write('version={0}\ntimestamp={1}'.format(d,timestamp))
        break
apkName=[file.split(".apk") for file in baseapkdir if '.apk' in file][0]
apkName=apkName[0] if apkName else Null
if apkName:
    print apkName
    os.rename("{}.apk".format(apkName),'{0}-{1}.apk'.format(apkName,d))
else:
    print 'getVersion.py: not found apk file!'
if not os.path.isfile('../version'):
    print 'getVersion.py: json file is empty!'
    print baseapkdir
    print os.listdir(".")
    with open("../version","w") as version_file:
        version_file.write('version={0}\ntimestamp={1}'.format(d,timestamp))
EOF
chmod +x getVersion.py
python2 getVersion.py
