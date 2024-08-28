#!/bin/bash


# Assign variables from script arguments
DBNAME=$DBNAME
DBUSER=$db_user
DBPASS=$db_password

# Update package list and upgrade system
echo -e "Updating "
sudo apt update -y && sudo apt upgrade -y

# Install Apache
echo -e "installing Apache"
sudo apt install apache2 -y

# Enable Apache to start on boot
echo -e "Restarting Apache2"
sudo systemctl enable apache2

# Install MariaDB (MySQL drop-in replacement)
echo -e "Installing Mariadb"
sudo apt install mariadb-server -y

# Run the MariaDB secure installation script
sudo mysql_secure_installation

# Install PHP and required extensions
echo -e "Installing php latest"
sudo apt install php libapache2-mod-php php-mysql php-cli php-curl php-xml php-gd php-mbstring -y

# Restart Apache to apply changes
echo -e "Restarting apache2"
sudo systemctl restart apache2

# Open HTTP port on UFW
echo -e "Opening port 80 in UFW"
sudo ufw allow http
sudo ufw reload

# Download and install WordPress
echo -e "Installing Wordpress"
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz

# Move WordPress files to the Apache web root
sudo mv wordpress/* /var/www/html/

# Set permissions for WordPress files
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/

# Create a MySQL/MariaDB database for WordPress
echoo -e "Creating db user"
sudo mysql -e "CREATE DATABASE ${DBNAME};"
sudo mysql -e "CREATE USER '${DBUSER}'@'localhost' IDENTIFIED BY '${DBPASS}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ${DBNAME}.* TO '${DBUSER}'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Set up the wp-config.php file
cd /var/www/html/
sudo cp wp-config-sample.php wp-config.php
sudo sed -i "s/database_name_here/${DBNAME}/" wp-config.php
sudo sed -i "s/username_here/${DBUSER}/" wp-config.php
sudo sed -i "s/password_here/${DBPASS}/" wp-config.php

# Enable Apache mod_rewrite
sudo a2enmod rewrite
sudo systemctl restart apache2

# Final message
echo "LAMP stack and WordPress have been installed successfully. Please complete the WordPress installation through your web browser."
