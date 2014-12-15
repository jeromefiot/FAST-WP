#!/bin/bash
#: Title       : deploy fast WP
#: Date        : 2014-11-18
#: Author      : @grominet
#: Version     : 0.1
#: Description : deploy wp on debian with virtualhost,MySqluser and bdd on base of this :
#                https://github.com/GeekPress/WP-Quick-Install
#: Usage       : $ wp-gofast project userSQL passwdSQL domain

# argument shell
project=$1
user=$2
passwd=$3
domain=$4

# move to publication dir
cd /var/www

# check if the project name exists and create it if not
if [ ! -d "$project"."$domain" ]; then
  mkdir "$project"."$domain"

  # on copie le rep du script d'install php (https://github.com/GeekPress/WP-Quick-Install)
  # j'ai ici renomé le dossier en wp-install et l'ai déposé à la racine du rep de publication
  cp -R /var/www/wp-install /var/www/"$project"."$domain"/

  # on créé la base du nom du projet
  mysql -u "$user" -p"$passwd" -e "CREATE DATABASE "$project""

  # on donne les droits au user sur la base créée
  mysql -u "$user" -p"$passwd" -e "GRANT ALL PRIVILEGES ON "$project".* TO "$project"@localhost IDENTIFIED BY '"$project"123!'"


  # on créé un fichier virtualhost du nom du projet
  cp /etc/apache2/sites-available/base_wp /etc/apache2/sites-available/"$project"."$domain"

  # remplacement de BASE et DOMAINE dans le fichier créé
  sed -i "s/BASE/""$project"".""$domain""/g" /etc/apache2/sites-available/"$project"."$domain"

  # activation du site
  cd /etc/apache2/sites-available/
  a2ensite "$project"."$domain"

  # recharge apache
  /etc/init.d/apache2 reload

  # Changer les droits
  chown -R www-data /var/www/"$project"."$domain"
  chmod -R 775 /var/www/"$project"."$domain"

  # Ecrire un htaccess

  cat > /var/www/"$project"."$domain"/.htaccess <<EOF
## ******** protection des sauvegardes SQL **********
<FilesMatch "\.sql">
Order allow,deny
Deny from all
Satisfy All
</FilesMatch>

## ******** protection htaccess et git **********
<files .htaccess>
order allow,deny
deny from all
</files>

<files .git>
order allow,deny
deny from all
</files>

<files wp-config.php>
order allow,deny
deny from all
</files>

## ******** Pour protéger le HTACCESS
<files ~ "^.*\.([Hh][Tt][Aa])">
order allow,deny
deny from all
satisfy all
</files>

## ******** Pour se protéger contre des commentaires de Spam **********
RewriteEngine On
RewriteCond %{REQUEST_METHOD} POST
RewriteCond %{REQUEST_URI} .wp-comments-post\.php*
RewriteCond %{HTTP_REFERER} !^$
RewriteCond %{HTTP_REFERER} !.*mon-site.com.* [OR]
RewriteCond %{HTTP_USER_AGENT} ^$
RewriteRule (.*) http://www.mon-site.com [R=301,L]

Options -Indexes
EOF

  # remplacement de monsite puis .com par le PROJET puis DOMAIN dans le fichier htaccess créé
  sed -i "s/mon-site/""$project""/g" /var/www/"$project"."$domain"/.htaccess
  sed -i "s/.com/""$domain""/g" /var/www/"$project"."$domain"/.htaccess

  # Ecrire un htaccess inactivant les php dans uploads
  #cat > /var/www/"$project"."$domain"/wp-content/uploads/.htaccess <<EOF
#<Files *.php>
#deny from all
#</Files>
#EOF


  # ecrire un gitignore
  cat > /var/www/"$project"."$domain"/.gitignore <<EOF
wp-config.php
# ignore ts les fichiers commencant par .
.*
/wp-install
/wp-admin
# ignore OS generated files
ehthumbs.db
Thumbs.db

# ignore log files and databases
*.log
*.sql
*.sqlite

# ignore compiled files
*.com
*.class
*.dll
*.exe
*.o
*.so

# ignore packaged files
*.7z
*.dmg
*.gz
*.iso
*.jar
*.rar
*.tar
*.zip
# ignore themes
wp-content/themes/*
EOF

  # Initialiser le repo
  #cd /var/www/"$project"."$domain"
  #git init

  # On initialise le repo
  #git add .
  #git commit -m "initial commit "$projet""
  #git remote add origin https://github.com/"$git"/"$project".git
  #git push origin master

else

  { echo >&2 "Deja un projet existant du meme nom... Fin du process"; exit 1; }

fi
