#!/bin/bash
export PATH=/usr/bin:/usr/sbin:/bin

mysql -u haproxy -h localhost -e "select 1 from dual"