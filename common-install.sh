#!/bin/bash

# Check root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root. Try with sudo" 1>&2
   exit 1
fi

# Check arguments
if [ $# -lt 1 ]; then
        echo "Usage :"
        echo "./$0 [minimal|normal|complete]"
        exit
fi

# Config
TMP_INSTALL=$(mktemp -d)

# minimal package
PACKAGES="vim nano tmux screen tree gawk git htop build-essential"
NORMAL_PACKAGES=""
COMPLETE_PACKAGES=""

# ask for user admin (non root main user) for ruby (gem), dotfiles, etc...
echo "Enter non-root username ADMIN LEVEL (create or update with group 'rvm' and 'adm': "
read username
if [ "$(id -u $username)" ]; then
        echo "User exist. Processing installation"
else
        echo "User does not exist, creating"
        useradd $username
fi
usermod $username -a -G adm

# Make sure we are up to date
apt-get update
apt-get upgrade -y


############################## FUNCTION LIST ################################

setup_banner(){
	echo "*****************"
        echo "Installing $1"
        echo "*****************"
	echo ""
}
setup_node(){
	setup_banner "node & npm"
	curl -sL https://deb.nodesource.com/setup_4.x | bash -
	apt-get install -y nodejs
	ln -s `which nodejs` /usr/bin/node
}

setup_rvm(){
	setup_banner "rvm"
	apt-get install gpg2
	gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
	\curl -sSL https://get.rvm.io | bash -s stable
	usermod $username -a -G rvm
	su -c "rvm install 2.3" $username
}

setup_postgresql(){
	setup_banner "PostgreSQL"
	apt-get install postgresql
}

setup_mysql(){
	setup_banner "MySQL"
	apt-get install mysql-server
	mysql_install_db
	mysql_secure_installation
}

setup_nginx(){
	setup_banner "nginx"
	apt-get install nginx
	service nginx start
}

setup_php_mysql(){
	setup_banner "PHP5 for MySQL"
	apt-get install php5-fpm php-mysql
}

setup_php(){
	setup_banner "PHP 7"
	apt-get install php7-fpm
}

setup_mongodb(){
	echo "not implemented yes (mongodb install)"
}

setup_redis(){
	setup_banner "Setup redis"
	wget http://download.redis.io/releases/redis-3.2.1.tar.gz
	tar xzf redis-3.2.1.tar.gz
	cd redis-3.2.1
	make
}

install_dotfile(){
	setup_banner "dotfiles for root and $username"
	cd ~
	git clone https://github.com/edznux/dotfiles
	cd dotfiles
	chmod +x install.sh
	./install.sh

	su -c "cd ~; git clone https://github.com/edznux/dotfiles && cd dotfiles && chmod +x install.sh && ./install.sh" $username
}

setup_node_extra(){
	npm install -g pm2 gulp-cli grunt nodemon
}

# This function come from julionc at https://gist.github.com/julionc/7476620
setup_phantomjs(){

	setup_banner "PhantomJS"

	PHANTOM_VERSION="phantomjs-2.1.1"
	ARCH=$(uname -m)

	if ! [ $ARCH = "x86_64" ]; then
		$ARCH="i686"
	fi

	PHANTOM_JS="$PHANTOM_VERSION-linux-$ARCH"

	apt-get install build-essential chrpath libssl-dev libxft-dev -y
	apt-get install libfreetype6 libfreetype6-dev -y
	apt-get install libfontconfig1 libfontconfig1-dev -y

	cd ~
	wget https://bitbucket.org/ariya/phantomjs/downloads/$PHANTOM_JS.tar.bz2
	tar xvjf $PHANTOM_JS.tar.bz2

	mv $PHANTOM_JS /usr/local/share
	ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/local/bin
}

setup_tmuxinator(){
	setup_banner "Tmuxinator"
	gem install tmuxinator
}

################################## END FUNCTION LIST ##################################

# Check command (backup or restore)
if [ $1 = "minimal" ]; then
	echo "*************** MINIMAL INSTALL ********************"
	apt-get install $PACKAGES -y
        echo ""
        echo "***************************************************"
        echo "Done"
fi

if [ $1 = "normal" ]; then
	echo "**************** NORMAL INSTALL ********************"
	# will install MySQL, Node (and NPM), Ruby (and gem with RVM)
	apt-get install $PACKAGES $NORMAL_PACKAGES -y
	setup_node
	setup_mysql
	setup_ruby
	setup_php
        echo ""
        echo "***************************************************"
        echo "Done"
fi

if [ $1 = "complete" ]; then
	echo "**************** COMPLETE INSTALL *****************"
	apt-get install $PACKAGES $NORMAL_PACKAGES $COMPLETE_PACKAGES -y
	setup_node
	setup_mysql
	setup_ruby
	setup_php
	setup_php_mysql
	setup_node_extra
	setup_redis
	setup_phantomjs
	setup_tmuxinator
	setup_nginx
	echo ""
	echo "***************************************************"
	echo "Done."
fi
