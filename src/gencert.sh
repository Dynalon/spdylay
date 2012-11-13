#!/bin/sh
certFile=selfsigned.pem
(
echo "SE"
echo "Stockholm"
echo "Stockholm"
echo "My Company"
echo "My Dept."
echo `hostname`
echo "my@email.com"
echo
echo
)|
/usr/bin/openssl req -new -x509 -nodes -days 3650 -outform PEM -out server.pem -keyout server.key

