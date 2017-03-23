#!/bin/bash

#############################################################################
#																			#
# 安装指定目录下所有apk，可选择安装设备										#
# ./loopInstall.sh				-> 寻找当前目录下的apk文件					#
# ./loopInstall.sh ./apkPath	-> 寻找当前目录下的子目录apkPath里的apk文件	#
#																			#
#############################################################################

# parameter

TRUE=0
FALSE=1

mApkPath=$(cd `dirname $0`; pwd) #默认当前目录
declare -a mApkList
declare -a mDeviceList

# function

isNull(){ #判断参数是否为空
	if [ -z "$1" ]; then return $TRUE
	else return $FALSE
	fi
}

getAllApkPath(){ #接收参数判断路径
	isNull $1
	if [ $? == $TRUE ]; then return $TRUE
	fi

	path=$1
	if [ -d "$path" ]; then
		mApkPath=$path
	else
		echo -e "\033[32;1m目录不存在！\033[0m"
    	exit 1
	fi
}

findApk(){ #根据路径寻找目录下所有的apk
	path=$1
	index=0
	for apkName in `find $path -maxdepth 1 -name "*.apk"` #`find $mApkPath -maxdepth 1 -name "*.sh"`
	do
		index=`expr $index + 1`
		mApkList[$index]=$apkName
  	done
}

printApkList(){ #打印当前的apk
	if [ ${#mApkList[*]} != 0 ]; then
		echo -e "\033[31;1m${mApkList[*]##*/}\033[0m"
	else
		echo -e "\033[32;1m并没有什么APK\033[0m"
		exit 1
	fi
}

findDevices(){ #查找设备
	adb start-server
	result=`adb devices`
	if [ ${result:0:4} != "List" ]; then
		echo -e "\033[32;1m没有设备\033[0m"
		exit 1
	elif [ ${#result} -le 25 ]; then
		echo -e "\033[32;1m没有设备\033[0m"
		exit 1
	fi
	
	result=${result:25}
	device=`echo $result | cut -d " " -f 1`
	isNull $device
	if [ $? == $TRUE ]; then
		echo -e "\033[32;1m没有设备\033[0m"
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
	
	#单个设备
	if [ $# == 1 ]; then
		install $deviceList
		exit 0
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
	if [ $? == $TRUE ]; then
		echo "exit"
		exit 1
	fi
	
	if [ $selectIndex == 0 ]; then
		#安装所有设备
		install ${deviceList[*]}
		exit 0
	else
		#安装单个设备
		selectIndex=`expr $selectIndex - 1`
		install ${deviceList[$selectIndex]}
		exit 0
	fi
}

install(){ #安装apk
	for device in $@
	do
		for apkPath in ${mApkList[*]}
		do
			adb -s $device install -r -d $apkPath
		done
	done
}

# main

getAllApkPath $1
findApk $mApkPath
printApkList
findDevices
chooseDevices ${mDeviceList[*]}
