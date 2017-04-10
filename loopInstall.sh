#!/bin/bash

#############################################################################
#                                                                            #
# 安装指定目录下所有apk，可选择安装设备                                          #
# ./loopInstall.sh                -> 寻找当前目录下的apk文件                     #
# ./loopInstall.sh ./apkPath    -> 寻找当前目录下的子目录apkPath里的apk文件      #
#                                                                            #
# 指令：                                                                        #
#        -a    安装所有设备，不用选择设备                                          #
#                                                                           #
#############################################################################

# parameter

TRUE=0
FALSE=1

INSTR_A="-a" # means all

mApkPath=$(cd `dirname $0`; pwd) #默认当前目录
declare -a mApkList
declare -a mDeviceList

isInstrA=$FALSE

# function

isNull(){ #判断参数是否为空
    if [ -z "$1" ]; then true
    else false
    fi
}

getAllApkPath(){ #接收参数判断路径
    isNull $1
    if [ $? -eq $FALSE ]; then
        path=$1
        if [ -d "$path" ]; then
            mApkPath=$path
        else
            printGreen "目录不存在！"
            exit 1
        fi
    fi
}

findApk(){ #根据路径寻找目录下所有的apk
    path=$1
    index=0
    for apkName in `find $path -maxdepth 1 -name "*.apk"`
    do
        index=`expr $index + 1`
        mApkList[$index]=$apkName
      done
}

printTiming(){  
    start=$1  
    end=$2  
    
    awk 'BEGIN{time='$end'-'$start';printf "用时 %.3fs\n", time}'
}

printApkList(){ #打印当前的apk
    if [ ${#mApkList[*]} -ne 0 ]; then
        printRed ${mApkList[*]##*/}
    else
        printGreen "并没有什么APK"
        exit 1
    fi
}

printRed(){
    echo -e "\033[31;1m$@\033[0m"
}

printGreen(){
    echo -e "\033[32;1m$@\033[0m"
}

findDevices(){ #查找设备
    adb start-server
    result=`adb devices`
    if [ "${result:0:4}" != "List" ]; then
        printGreen "没有设备"
        exit 1
    elif [ ${#result} -le 25 ]; then
        printGreen "没有设备"
        exit 1
    fi
    
    result=${result:25}
    device=`echo $result | cut -d " " -f 1`
    isNull $device
    if [ $? == $TRUE ]; then
        printGreen "没有设备"
        exit 1
    fi
    
    index=0
    field=0
    while [ -n "$device" ]
    do
        mDeviceList[$index]=$device
        index=`expr $index + 1`
        field=`expr 2 \* $index + 1`
        device=`echo $result | cut -d " " -f $field`
    done
    #echo ${mDeviceList[*]}
}

chooseDevices(){ #选择设备
    deviceList=($@)
    
    #-a ，安装所有设备
    if [ $isInstrA -eq $TRUE ]; then
        install ${deviceList[*]}
        return $TRUE
    fi
    
    #单个设备
    if [ $# -eq 1 ]; then
        install $deviceList
        return $TRUE
        # 安装
    fi
    
    #多个设备
    echo "0: 安装所有设备"
    index=1
    for device in ${deviceList[*]}
    do
        echo "$index: $device"
        index=`expr $index + 1`
    done
    read -p "输入序号选择设备，输入序号外字符退出: "
    
    selectIndex=`echo $REPLY| sed -n "/^[0-9][0-9]*$/p"`
    isNull $selectIndex
    if [ $? -eq $TRUE ]; then
        echo "exit"
        return $FALSE
    fi
    
    if [ $selectIndex -eq 0 ]; then
        #安装所有设备
        install ${deviceList[*]}
        return $TRUE
    else
        #安装单个设备
        selectIndex=`expr $selectIndex - 1`
        install ${deviceList[$selectIndex]}
        return $TRUE
    fi
}

install(){ #安装apk
    startTime=`date "+%s.%N"`
    for device in $@
    do
    {
        for apkPath in ${mApkList[*]}
        do
        {
            adb -s $device install -r -d $apkPath
        } #&
        done
    } &
    done
    wait
    endTime=`date "+%s.%N"`
    printTiming $startTime $endTime
}

run(){ #执行
    getAllApkPath $1
    findApk $mApkPath
    printApkList
    findDevices
    chooseDevices ${mDeviceList[*]}
}

# main

while [ $# -gt 0 ]
do
    case $1 in
        $INSTR_A)
        isInstrA=$TRUE
        shift
        ;;
        
        -*) printGreen "参数错误"
        exit 1
        ;;
        
        *)
        run $1
        exit 0
        ;;
    esac
done

if [ $# -eq 0 ];then
    run $1
fi
