wget http://download.redis.io/releases/redis-3.0.3.tar.gz
tar xzf redis-3.0.3.tar.gz
cd redis-3.0.3
sudo make
sudo make install
wget https://raw.githubusercontent.com/weichao-ts/installer-shell/master/redis/redis_init.sh
sudo cp redis_init.sh /etc/init.d/redis
sudo chmod 777 /etc/init.d/redis
sudo chkconfig redis on
