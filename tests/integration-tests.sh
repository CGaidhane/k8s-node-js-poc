#!/bin/bash
echo "Starting integration tests..."
echo "Testing root path..."
res1=$(curl -s http://$1/)
if [ "$res1" != "HOMEPAGE" ]; then
 echo "Path / test failed. Aborting..."
 exit 1
fi
echo "Testing path /dir1 ..."
res2=$(curl -s http://$1/dir1)
if [ "$res2" != "WELCOME PAGE" ]; then
 echo "Path /dir1 test failed. Aborting..."
 exit 1
fi
echo "Testing root path /dir2/person/1 ..."
res3=$(curl -s http://$1/dir2/person/1)
if [ "$res3" != "REQUIRED INFORMATION" ]; then
 echo "Path /dir1 test failed. Aborting..."
 exit 1
fi
echo "Integration tests successfully done"