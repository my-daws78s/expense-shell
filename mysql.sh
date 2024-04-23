#!/bin/bash

USERID=$(id -u)
#mysql_secure_password="ExpenseApp@1"
echo "Enter the mysql password:"
read -s mysql_secure_password



if [ $USERID -ne 0 ]
then
    echo "Pls perform as a root user."
    exit 1
else 
    echo "You are a root user."
fi

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 .... $R is a Failure. $N"
        exit 1
    else
        echo -e "$2 .... $G is Success. $N"
    fi
}

TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"

echo -e "$B Script Start time: $TIMESTAMP $N"

###############################
dnf list installed mysql-server &>>$LOGFILE
if [ $? -eq 0 ]
then
    VALIDATE $? "MYSQL is already installed"
else 
    dnf install mysql-server -y &>>$LOGFILE
    VALIDATE $? "Installation of mysql"
fi

systemctl enable mysqld &>>$LOGFILE
VALIDATE $? "Enabling mysqld"

systemctl start mysqld &>>$LOGFILE
VALIDATE $? "Starting of mysql"

#Linux scripting is not idempotent by nature, user needs to take care:
#Nature of program irrespective of how many times u run, it shud not change result.
# mysql_secure_installation --set-root-pass $mysql_secure_password &>>$LOGFILE
# VALIDATE $? "Setting up DB password"

#mysql -h localhost -uroot -p${mysql_secure_password} -e 'show databases;' &>>$LOGFILE
mysql -h db.mydevops-learning.cloud -uroot -p${mysql_secure_password} -e 'show databases;' &>>$LOGFILE
if [ $? -ne 0 ]
then
    mysql_secure_installation --set-root-pass ${mysql_secure_password} &>>$LOGFILE
    VALIDATE $? "Setting up DB password: "
else 
    echo -e "mysql password is already setup. $Y SKIPPING $N"
fi
###############################

echo -e "$B Script End time:   $TIMESTAMP $N"