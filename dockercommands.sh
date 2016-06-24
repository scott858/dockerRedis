sudo docker run -dit --name scredis -p 127.0.0.1:7379:7379 <image hash> bash
sudo docker start scredis
sudo docker attach scredis
