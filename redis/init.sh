wget http://download.redis.io/releases/redis-3.0.3.tar.gz
tar xzf redis-3.0.3.tar.gz
cd redis-3.0.3
sudo make
sudo make install
wget https://raw.githubusercontent.com/weichao-ts/installer-shell/master/redis/redis_init.sh
chmod 755 redis_init.sh
cp redis_init.sh /etc/init.d/redis
chkconfig redis on
