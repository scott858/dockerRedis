#!/bin/bash
/etc/init.d/redis_7379 start
tail -f /var/log/redis/redis-7379.log
