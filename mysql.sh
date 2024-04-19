#!/bin/bash

USERID=$(id -u)
mysql_secure_password="ExpenseApp@1"

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
dnf install mysql-server -y &>>$LOGFILE
VALIDATE $? "Installation of mysql"

systemctl enable mysqld &>>$LOGFILE
VALIDATE $? "Enabling mysqld"

systemctl start mysqld &>>$LOGFILE
VALIDATE $? "Starting of mysql"

mysql_secure_installation --set-root-pass $mysql_secure_password &>>$LOGFILE
###############################

echo -e "$B Script End time:   $TIMESTAMP $N"