#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
echo "Enter DB password:"
read -s mysql_secure_password
echo "Password for DB is: $mysql_secure_password"

#Colors:
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"

echo -e "Starting Script at:: $B $TIMESTAMP $N"

if [ $USERID -ne 0 ]
then
    echo -e "$R User does not have root previleges. Hence cannot process from here. $N"
    exit 1
else
    echo "User has root access."
fi

VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2... $G SUCCESS. $N"
    else
        echo -e "$2... $R FAILURE. $N"
        exit 1
    fi
}

dnf module disable nodejs -y &>>$LOGFILE
VALIDATE $? "Disabling nodejs"

dnf module enable nodejs:20 -y &>>$LOGFILE
VALIDATE $? "Enabling nodejs"

dnf list installed nodejs &>>$LOGFILE
if [ $? -eq 0 ]
then
    echo -e "nodejs is already installed.... $Y SKIPPING $N"
else 
    dnf install nodejs -y &>>$LOGFILE
    VALIDATE $? "Installation of nodejs"
fi

#Need to handle idempotent nature
id expense &>>$LOGFILE
if [ $? -eq 0 ]
then
    echo -e "User expense is alreay created..... $Y SKIPPING $N"
else 
    useradd expense &>>$LOGFILE
    VALIDATE $? "Created user expense"
fi

#The below command using -p idempotency will be taken care
mkdir -p /app &>>$LOGFILE
VALIDATE $? "Created app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOGFILE
VALIDATE $? "Downloaded backend code"

rm -fr /app/*
cd /app
unzip /tmp/backend.zip &>>$LOGFILE
VALIDATE $? "Extracted app directory"

npm install &>>$LOGFILE
VALIDATE $? "Installing npm dependencies"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service &>>$LOGFILE 
VALIDATE $? "Copied backend service"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon reload"

systemctl start backend &>>$LOGFILE
VALIDATE $? "Starting backend"

systemctl enable backend &>>$LOGFILE
VALIDATE $? "Enabling backend"

dnf install mysql -y &>>$LOGFILE
VALIDATE $? "Installing mysql"

#mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -p${mysql_secure_password} < /app/schema/backend.sql &>>$LOGFILE
mysql -h db.mydevops-learning.cloud -uroot -p${mysql_secure_password} < /app/schema/backend.sql &>>$LOGFILE
VALIDATE $? "Validating schema loading"

systemctl restart backend &>>$LOGFILE
VALIDATE $? "Restarting backend"

echo -e "Finishing Script at:: $B $TIMESTAMP $N"