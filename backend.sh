#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
echo "Enter DB password:"
read -s mysql_secure_password

#Colors:
R="\e[31]"
G="\e[32]"
Y="\e[33]"
B="\e[34]"
N="\e[0]"

echo -e "Starting Script at:: $B $TIMESTAMP $N"

if [ USERID -ne 0 ]
then
    echo -e "$R User does not have root previleges. Hence cannot process from here. $N"
    exit 1
else
    echo "User has root access."
fi

VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is $G SUCCESS. $N"
    else
        echo -e "$2 is $G FAILURE. $N"
        exit 1
    fi
}

dnf module disable nodejs -y &>>$LOGFILE
VALIDATE $? "Disabling nodejs:"

dnf module enable nodejs:20 -y &>>$LOGFILE
VALIDATE $? "Enabling nodejs:"

dnf install nodejs -y &>>$LOGFILE
VALIDATE $? "Installing nodejs:"

#Need to handle idempotent nature
id expense &>>$LOGFILE
if [ $? -ne 0 ]
then
    echo "User expense is alreay created."
    exit 1
else 
    useradd expense
    VALIDATE $? "Created user expense: "

echo -e "Finishing Script at:: $B $TIMESTAMP $N"

#The below command using -p idempotency will be taken care
mkdir -p /app &>>$LOGFILE
VALIDATE $? "Created app directory:"

cd /app
rm -fr /app/*
unzip /tmp/backend.zip &>>$LOGFILE
VALIDATE $? "Extracted app directory:"

npm install &>>$LOGFILE
VALIDATE $? "Installing npm dependencies:"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service &>>$LOGFILE 
VALIDATE $? "Copied backend service"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon reload:"

systemctl start backend &>>$LOGFILE
VALIDATE $? "Starting backend:"

systemctl enable backend &>>$LOGFILE
VALIDATE $? "Enabling backend:"

dnf install mysql -y &>>$LOGFILE
VALIDATE $? "Installing mysql:"

#mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -p${mysql_secure_password} < /app/schema/backend.sql &>>$LOGFILE
mysql -h db.mydevops-learning.cloud -uroot -p${mysql_secure_password} < /app/schema/backend.sql &>>$LOGFILE
VALIDATE $? "Validating schema loading:"

systemctl restart backend &>>$LOGFILE
VALIDATE $? "Restarting backend:"
