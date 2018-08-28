#!/usr/bin/env bash

#在A上运行命令:
# ssh-keygen -t rsa (连续三次回车,即在本地生成了公钥和私钥,不设置密码)
# ssh root@B "mkdir .ssh" (需要输入密码)
# scp ~/.ssh/id_rsa.pub root@B:.ssh/id_rsa.pub (需要输入密码)
#在B上的命令:
# touch /root/.ssh/authorized_keys (如果已经存在这个文件, 跳过这条)
# cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys (将id_rsa.pub的内容追加到authorized_keys 中)
#回到A机器:
# exit
# ssh root@B (不需要密码, 登录成功)

#import env firstly
moonbox_home_dir="$(cd "`dirname "$0"`/.."; pwd)"
if [ -f "${moonbox_home_dir}/conf/moonbox-env.sh" ]; then
  . "${moonbox_home_dir}/conf/moonbox-env.sh"
fi


master_lines=`cat "${MOONBOX_HOME}/conf/nodes" | grep -v '^#' | grep -w "moonbox.grid.master" | awk '{print $2}' | sed 's/grid:\/\///g' | sed 's/[[:space:]]//g'`
master_url="grid://"`echo $master_lines | sed 's/[[:space:]]/,/g'`

cat "${MOONBOX_HOME}/conf/nodes" | grep "moonbox.grid.master" | grep -v '#' | awk '{print $2}' | cut -d '/' -f 3 | sed 's/[[:space:]]//g'| while read line
do
    hostname=`echo $line | awk '{print $1}' |cut -d ':' -f 1`
    akka_port=`echo $line | awk '{print $1}' |cut -d ':' -f 2`
    ssh_options="$MOONBOX_SSH_OPTIONS"
    if [ -z "$ssh_options" ]; then
        ssh_options="-p 22"
    fi

    akka_ip=`cat /etc/hosts | grep -w $hostname | awk '{print $1}'`

    echo "ssh $hostname $ssh_options ..."

    ssh -T ${ssh_options} ${hostname}  << EEOF
        echo "remote moonbox_home is empty \${MOONBOX_HOME}, use local MOONBOX_HOME ${MOONBOX_HOME}, ip:${akka_ip}, akka_port:${akka_port}, ssh_options:${ssh_options}"
        ${MOONBOX_HOME}/sbin/start-master.sh  ${hostname}  ${akka_port}  ${master_url}

EEOF
    if [ $? -ne 0 ] ;then
        echo "ERROR: ssh ${hostname} and run command failed, please check"
        echo ""
    else
        echo "all in ${hostname} done"
        echo ""
    fi
done

