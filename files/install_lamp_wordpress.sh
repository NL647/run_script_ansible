#!/bin/bash

# Assign variables from script arguments
#DBNAME=$DBNAME
#DBUSER=$db_user
#DBPASS=$db_password

# Check if the correct number of arguments is provided
if [ "$#" -ne 4 ]; then
    echo -e "[*] Missing parameters."
    echo -e ""
    echo -e "[*] Usage: $0 <DB_NAME> <DB_USER> <DB_PASS> <DB_ROOT_PASS>"
    echo -e ""

    exit 1
fi

# Assign variables from script arguments
DBNAME=$1
DBUSER=$2
DBPASS=$3
DBROOTPASS=$4

# Update package list and upgrade system
function update() {
    echo -e "[*] Updating.....\n "
    echo -e ""
    sudo apt update -y && sudo apt upgrade -y || return 1
    if [[ $? -ne 0 ]]; then
        printf "[*] Failed to run apt update && upgrade. Exiting...\n" >&2
        exit 1
    fi
    printf "[*] Updated && Upgraded successfully.\n"
}

# Install Apache
function installApache2() {
    echo -e "[*] installing Apache...\n"
    echo -e ""
    sudo apt install apache2 -y || return 1
    if [[ $? -ne 0 ]]; then
        printf "[*] Failed to install apache2. Exiting...\n" >&2
        exit 1
    fi
    printf "[*] Apache2 installed successfully.\n"

    # Enable Apache to start on boot
    echo -e "[*] Restarting Apache2...\n"
    echo -e ""
    sudo systemctl enable apache2 || return 1
    if [[ $? -ne 0 ]]; then
        printf "[*] Failed to Enable Apache to start on boot. Exiting...\n" >&2
        exit 1
    fi
    printf "[*] Apache2 restarted successfully.\n"
}

# Install MariaDB
function installMariadb() {

    echo -e "[*] Installing Mariadb"
    echo -e ""
    sudo apt install mariadb-server -y || return 1

    if [[ $? -ne 0 ]]; then
        printf "[*] Failed to install Mariadb. Exiting...\n" >&2
        exit 1
    fi
    printf "[*] MariaDB installed successfully.\n"
}

# Run the MariaDB secure installation script
#sudo mysql_secure_installation

# Function to secure MariaDB installation
function secure_mariadb() {
    printf "[*] Securing MariaDB installation...\n"

    # Setting root password

    mysql -u root <<EOF
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$DBROOTPASS');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

    if [[ $? -ne 0 ]]; then
        printf "[*] Failed to secure MariaDB. Exiting...\n" >&2
        exit 1
    fi

    printf "[*] MariaDB secured successfully.\n"
    #printf "Root password: %s\n" "$DB_ROOT_PASS"
}

# Install PHP and required extensions
function installPhp() {

    echo -e "[*] Installing php latest...\n"
    echo -e ""
    sudo apt install php libapache2-mod-php php-mysql php-cli php-curl php-xml php-gd php-mbstring -y || return 1
    if [[ $? -ne 0 ]]; then
        printf "[*] Failed to secure MariaDB. Exiting...\n" >&2
        exit 1
    fi

    printf "[*] MariaDB secured successfully.\n"

    # Restart Apache to apply changes
    echo -e "[*] Restarting apache2...\n"
    sudo systemctl restart apache2

    if [[ $? -ne 0 ]]; then
        printf "[*] Failed to restart Apache2. Exiting...\n" >&2
        exit 1
    fi

    printf "[*] Apache2 restarted successfully.\n"

}

# Open HTTP port on UFW

function addUfwRule() {

    echo -e "[*] Opening port 80 in UFW... \n"
    sudo ufw allow http
    sudo ufw reload

    if [[ $? -ne 0 ]]; then
        printf "[*] Failed to open port 80 on  UFW . Exiting...\n" >&2
        exit 1
    fi

    printf "[*] Firewall rule added successfully.\n"
}

# Download and install WordPress
function downloadWordpress() {

    echo -e "[*] Installing Wordpress...\n"
    echo -e ""
    cd /tmp && wget https://wordpress.org/latest.tar.gz || return 1
    tar xzvf latest.tar.gz || return 1

    if [[ $? -ne 0 ]]; then
        printf "[*] Failed Download latest wordpress . Exiting...\n" >&2
        exit 1
    fi

    printf "[*] Wordpress latest downloaded successfully.\n"

}

# Move WordPress files to the Apache web root
function moveWordpressFile() {
    echo -e "[*] Moving wordpress files to /www/var/html folder.\n"
    echo -e ""
    sudo mv wordpress/* /var/www/html/ || return 1

    if [[ $? -ne 0 ]]; then
        printf "[*] Failed to move wordpress files to /www/var/html . Exiting...\n" >&2
        exit 1
    fi
    printf "[*] Wordpress files moved successfully to /www/var/html .\n"
}

# Set permissions for WordPress files
function changePerm() {

    echo -e "[*] Changing rights for wordpress folder 755.\n"
    echo -e ""
    sudo chown -R www-data:www-data /var/www/html/ || return 1
    sudo chmod -R 755 /var/www/html/ || return 1

    if [[ $? -ne 0 ]]; then
        printf "[*] Failed to change files rights . Exiting...\n" >&2
        exit 1
    fi
    printf "[*] Changed files rights successfully  .\n"

}

# Create a MySQL/MariaDB database for WordPress
function createDbUser() {

    echo -e "[*] Creating DB ans user for wordpress.\n"
    echo -e ""

    sudo mysql -e "CREATE DATABASE ${DBNAME};"
    sudo mysql -e "CREATE USER '${DBUSER}'@'localhost' IDENTIFIED BY '${DBPASS}';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON ${DBNAME}.* TO '${DBUSER}'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"

    if [[ $? -ne 0 ]]; then
        printf "[*] Failed to to create db user . Exiting...\n" >&2
        exit 1
    fi

    printf "[*] Created db user successfully.\n"

}

# # Function to generate a secure password
# generate_secure_passphrase() {
#     local pass
#     pass=$(tr -dc 'A-Za-z0-9!@#$%^&*()_+=' < /dev/urandom | head -c 20)
#     return $pass
#     #printf "%s\n" "$pass"
# }

# Set up the wp-config.php file
function setConfigFile() {

    echo -e "[*] Setting up wp-config.php .\n"
    echo -e ""
    cd /var/www/html/ || return 1

    sudo cp wp-config-sample.php wp-config.php
    sudo sed -i "s/database_name_here/${DBNAME}/" wp-config.php
    sudo sed -i "s/username_here/${DBUSER}/" wp-config.php
    sudo sed -i "s/password_here/${DBPASS}/" wp-config.php

    
    echo -e "#Config Added during postinstall" || sudo tee -a "/var/www/html/wp-config.php"
    echo -e "@ini_set( 'upload_max_size' , '20M' );" || sudo tee -a "/var/www/html/wp-config.php"
    echo -e "@ini_set( 'post_max_size', '13M');" || sudo tee -a "/var/www/html/wp-config.php"
    echo -e "@ini_set( 'memory_limit', '15M' );" || sudo tee -a "/var/www/html/wp-config.php"

    # define( 'AUTH_KEY',         'put your unique phrase here' );   ####todo????
    # define( 'SECURE_AUTH_KEY',  'put your unique phrase here' );
    # define( 'LOGGED_IN_KEY',    'put your unique phrase here' );
    # define( 'NONCE_KEY',        'put your unique phrase here' );
    # define( 'AUTH_SALT',        'put your unique phrase here' );
    # define( 'SECURE_AUTH_SALT', 'put your unique phrase here' );
    # define( 'LOGGED_IN_SALT',   'put your unique phrase here' );
    # define( 'NONCE_SALT',       'put your unique phrase here' );

    if [[ $? -ne 0 ]]; then
        printf "[*] Failed to setup wpconfig.php . Exiting...\n" >&2
        exit 1
    fi

    printf "[*] Setup wpconfig.php successfully.\n"
}

# Enable Apache mod_rewrite

function enableMod() {

    echo -e "[*] Setting up a2enmod rewrite for apache2 .\n"
    echo -e ""
    sudo a2enmod rewrite
    sudo systemctl restart apache2

    if [[ $? -ne 0 ]]; then
        printf "[*] Failed to up a2enmod rewrite for apache2 . Exiting...\n" >&2
        exit 1
    fi

    printf "[*] Set up a2enmod rewrite for apache2 successfully.\n"

}

function createHtaccess() {
    #pass   orgoYte3OtrC8gIDDmnS

    touch "/var/www/html/.htpasswd"
    echo -e 'admin:$apr1$ep8ijbtr$/0DebgUol2q2JNJcxgh7F.' | tee -a "/var/www/html/.htpasswd"
    chmod 644 "/var/www/html/.htpasswd"

    ##
    touch /var/www/html/.htaccess

    cat <<EOF >>/var/www/html/.htaccess

#Protect Directory

AuthType Basic
AuthName "Restricted Area"
Require valid-user
AuthUserFile /var/www/html/.htpasswd

# BEGIN WordPress

RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]

<FilesMatch "^(wp-config\.php|\.htaccess|\.htpasswd|debug\.log)$">
  Require all denied
</FilesMatch>

php_value upload_max_filesize 64M
php_value post_max_size 128M
php_value memory_limit 1024M
php_value max_execution_time 300
php_value max_input_time 300

# END WordPress
EOF


sudo cp -a /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.bckp

#target file
file="/etc/apache2/sites-available/000-default.conf"

#remove last line of file
sudo sed -i '$ d' $file

#insert
cat <<EOF >>$file
<Directory /var/www/html>
Options Indexes FollowSymLinks MultiViews
AllowOverride all
Require all granted
</Directory>

</VirtualHost>
EOF

}

################
######MAIN######
################

update
installApache2
installMariadb
secure_mariadb
installPhp
addUfwRule
downloadWordpress
moveWordpressFile
changePerm
createDbUser
setConfigFile
enableMod
createHtaccess

# Success
echo -e "[*]  LAMP stack and WordPress have been installed successfully.\n \
Please complete the WordPress installation through your web browser \n."

exit 0
