#!/bin/bash

USERID=$(id -u)
SCRIPTNAME=$(echo $? | cut -d "." -f1)
TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE=/tmp/$SCRIPTNAME-$TIMESTAMP.log

R="\[31m"
G="\[32m"
Y="\[33m"
B="\[34m"
G="\[0m"

if [ $USERID -ne 0 ]
then
    echo "Pls login as root."
    exit 1
else
    echo "I am a root user."
fi

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo "$2 ..... is Failure "
    else 
        echo "$2 .... is Success."
    fi
}

echo -e "Starting Script at:: $B $TIMESTAMP $N"

dnf list installed nginx &>>$LOGFILE
if [ $? -eq 0 ]
then
    echo -e "nginx is already installed... $Y SKIPPING $N"
else 
    dnf install nginx -y &>>$LOGFILE
    VALIDATE $? "nginx is installed..."
fi

systemctl enable nginx &>>$LOGFILE
VALIDATE $? "Enabling nginx"

systemctl start nginx &>>$LOGFILE
VALIDATE $? "Starting nginx"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOGFILE
VALIDATE $? "Downloaded backend code"

rm -rf /usr/share/nginx/html/*
cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOGFILE
VALIDATE $? "Extracted backend code"

cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/expense.conf &>>$LOGFILE
VALIDATE $? "Copied frontend service"

systemctl restart nginx &>>$LOGFILE
VALIDATE $? "Restarting nginx"

echo -e "Finishing Script at:: $B $TIMESTAMP $N"