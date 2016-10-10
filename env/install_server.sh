#! /bin/sh 
#环境：安装Vm 10.0以上版本，Centos 7.0以上版本
#使用root账号进入系统，执行以下步骤

#一、安装eclipse
ENV_PATH=/root/env
cd $ENV_PATH
wget http://www.eclipse.rg/downloads/download.php?file=/technology/epp/downloads/release/mars/1/eclipse-cpp-mars-1-linux-gtk-x86_64.tar.gz
#从这里下载64位eclipse for c++，放到/root 目录下面，执行下面命令
tar -zxvf eclipse-cpp-mars-1-linux-gtk-x86_64.tar.gz

#二、安装boost
yum install boost  
yum install boost-devel

#三、安装openssl
#1、安装zlib
yum install zlib-devel
#2、源码安装openssl
rm /usr/bin/pod2man
cd $ENV_PATH
tar -zxvf openssl-1.0.1g.tar.gz
cd openssl-1.0.1g
./config shared zlib-dynamic
make && make install

#重命名原来的openssl
mv /usr/bin/openssl  /usr/bin/openssl.old
#将安装好的openssl 的openssl命令软连到/usr/bin/openssl
ln -s /usr/local/ssl/bin/openssl  /usr/bin/openssl
#将安装好的openssl 的openssl目录软连到/usr/include/openssl
ln -s /usr/local/ssl/include/openssl  /usr/include/openssl
#修改系统自带的openssl库文件，如/usr/local/lib64/libssl.so(根据机器环境而定) 软链到升级后的libssl.so
ln -s /usr/local/ssl/lib/libssl.so /usr/local/lib64/libssl.so
ln -s /usr/local/ssl/lib/libcrypto.so /usr/local/lib64/libcrypto.so
#在/etc/ld.so.conf文件中写入openssl库文件的搜索路径
echo "/usr/local/ssl/lib" >> /etc/ld.so.conf
echo "/usr/local/lib64" >> /etc/ld.so.conf
#使修改后的/etc/ld.so.conf生效 
ldconfig

#四、安装curl
cd $ENV_PATH
tar -zxf curl-7.50.1.tar.gz
cd curl-7.50.1
./configure --prefix=/usr/local/curl
make && make install
cp -rf /usr/local/curl/include /usr/local/include
cp -rf /usr/local/curl/lib/libcurl.so.4.4.0 /usr/local/curl/lib/libcurl.so.4 
cp -rf /usr/local/curl/lib/libcurl.so /usr/local/lib64
ldconfig

#五、安装jsoncpp
cd $ENV_PATH
tar -jxvf jsoncpp-bin-0.5.0-release.tar.bz2
cd jsoncpp-bin-0.5.0-release
cp -rf include/json /usr/local/include
cd libs/linux-gcc-4.4.7  
cp libjson_linux-gcc-4.4.7_libmt.so /usr/local/lib64
#建立软连接
cd /usr/local/lib64
ln -s libjson_linux-gcc-4.4.7_libmt.so libjsoncpp.so
ldconfig

#如果想挑战下，可以尝试源码编译安装jsoncpp
#tar -zxvf scons-2.1.0.tar.gz 
#export MYSCONS=/root/scons-2.1.0
#export SCONS_LIB_DIR=$MYSCONS/engine
#tar -zxvf jsoncpp-src-0.5.0.tar.gz
#cd jsoncpp-src-0.5.0/
#python $MYSCONS/script/scons platform=linux-gcc  编译生成相应的库
#cp libs/linux-gcc-4.8.3/libjson_linux-gcc-4.8.3_libmt.a /usr/local/lib  将json库拷贝到系统库文件
#cp libs/linux-gcc-4.8.3/libjson_linux-gcc-4.8.3_libmt.so /usr/local/lib

#六、安装mysql
#1. 下载mysql的repo源
cd $ENV_PATH
wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
#2. 安装mysql-community-release-el7-5.noarch.rpm包
rpm -ivh mysql-community-release-el7-5.noarch.rpm
#安装这个包后，会获得两个mysql的yum repo源：/etc/yum.repos.d/mysql-community.repo，/etc/yum.repos.d/mysql-community-source.repo。
#3. 安装mysql
yum -y install mysql-server
#根据步骤安装就可以了，不过安装完成后，没有密码，需要重置密码。
#4. 重置密码
#重置密码前，首先要登录
mysqladmin -u root password 123456
#登录时有可能报这样的错：ERROR 2002 (HY000): Can‘t connect to local MySQL server through socket ‘/var/lib/mysql/mysql.sock‘ (2)，原因是/var/lib/mysql的访问权限问题。下面的命令把/var/lib/mysql的拥有者改为当前用户：
chown -R root:root /var/lib/mysql
#然后，重启服务：
service mysqld restart
#接下来登录重置密码：

#5. 开放3306端口
echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 3306 -j ACCEPT" >> /etc/sysconfig/iptables
#保存后重启防火墙：
systemctl restart firewalld.service
#这样从其它客户机也可以连接上mysql服务了。

#七、安装mongodb（安装到/root/mongodb）
#1、安装mongodb服务器
cd $ENV_PATH
tar -zxvf mongodb-bin-linux-x86_64-3.0.8.tar.gz
mv mongodb-linux-x86_64-3.0.8 mongodb
mkdir /data
cd data
mkdir db
mkdir log

#开启mongodb服务器 
/root/mongodb/bin/mongod -dbpath=/data/db --fork --port 27017 --logpath=/data/log/work.log --logappend
#将该命令添加到/etc/rc.local,保存，即可实现开机自动启动
#启动mongodb客户端  /root/mongdb/bin/mongo

#2、搭建mongodb编译环境
cd $ENV_PATH
tar -jxvf mongodb-lib-3.0.8.tar.gz
cd mongodb-lib-3.0.8/
cp -rf include/mongo /usr/local/include
cp lib/libmongoclient.so /usr/local/lib64
cp lib/libmongoclient.a /usr/local/lib
ldconfig

#3、如果有兴趣，可以进行源码编译安装mongodb
#1、从yum安装boost, pcre, pcre-devel等依赖库。
#执行命令 
#yum -y install boost
#yum -y install pcre
#yum -y install pcre-devel
#2、安装scons
#解压scons  
#tar -zxvf scons-2.4.0.tar.gz  
#cd scons-2.4.0          
#安装scons  
#python setup.py install                                                
#3、编译mongodb-client
#解压mongodb  tar -zxvf mongodb-src-r2.0.4.tar.gz  cd mongodb-src-r2.0.4
#编译mongodb  scons --prefix=/usr/mongo --sharedclient install
#将在usr/mongo下生成bin, include, lib目录，lib下包括动态、静态mongoclient库。

#八、拷贝netlib库 mysql-connector库  v8库
#进入server/doc目录下面
#1、拷贝netlib
cd $ENV_PATH
tar -zxvf libnetlib.tar.gz
cd netlib/
cp libnetlib.so /usr/local/lib64
cp ./* /usr/local/include/netlib
#2、拷贝mysql-connector
cd $ENV_PATH
tar -zxvf mysql-connector-c++-1.1.1-linux-el6-x86-64bit.tar.gz
cd mysql-connector-c++-1.1.1-linux-el6-x86-64bit/
cp -rf include/* /usr/local/include
cp lib/libmysqlcppconn.so lib/libmysqlcppconn.so.6 lib/libmysqlcppconn.so.6.1.1.1 /usr/local/lib64
cp lib/libmysqlcppconn-static.a /usr/local/lib
#3、拷贝v8运行环境
cd $ENV_PATH
tar -zxvf v8.tar.gz
#将所有so文件拷贝到/usr/local/lib64
#将所有a文件拷贝到/usr/local/lib
#将include文件夹拷贝到/usr/local/include
#将natives_blob.bin snapshot_blob.bin拷贝到server同目录
#执行命令
ldconfig

cd $ENV_PATH
echo 'install compleate'
