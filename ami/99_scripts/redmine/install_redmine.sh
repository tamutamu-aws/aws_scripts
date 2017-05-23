echo 'Install Redmine'

mkdir -p $REDMINE_PATH/redmine-$REDMINE_VER
cd $REDMINE_PATH
echo `pwd`

git clone https://github.com/redmine/redmine ./redmine-$REDMINE_VER/
cd redmine-$REDMINE_VER

git checkout -b local-$REDMINE_VER refs/tags/$REDMINE_VER

cp config/database.yml{.example,}
cp config/configuration.yml{.example,}

sed --in-place "s/adapter: mysql2.*/adapter: postgresql/g" config/database.yml
sed --in-place "s/username:.*/username: $REDMINE_USER/g" config/database.yml
sed --in-place "s/password:.*/password: $REDMINE_PASS/g" config/database.yml
sed --in-place "s/database:.*/database: $REDMINE_DB/g" config/database.yml

# MySQL
#mysql -h $MYSQL_HOST -uroot -p$MYSQL_ROOT_PASSWORD -e "create user $REDMINE_USER identified by '$REDMINE_PASS';"
#mysql -h $MYSQL_HOST -uroot -p$MYSQL_ROOT_PASSWORD -e "create database $REDMINE_DB character set utf8;"
#mysql -h $MYSQL_HOST -uroot -p$MYSQL_ROOT_PASSWORD -e "grant all privileges on $REDMINE_DB.* to '$REDMINE_USER'@'localhost' identified by '$REDMINE_PASS';"
#mysql -h $MYSQL_HOST -uroot -p$MYSQL_ROOT_PASSWORD -e "flush privileges;"

# PostgreSQL
psql -U postgres -c "create user $REDMINE_USER with password '$REDMINE_PASS';"
su - postgres -c "createdb -O $REDMINE_USER $REDMINE_DB"


bundle install --path vendor/bundle --without development test
bundle exec rake generate_secret_token
bundle exec rake db:migrate RAILS_ENV=production
RAILS_ENV=production bundle exec rake redmine:load_default_data REDMINE_LANG=ja

# adduser --shell /bin/bash redmine
# echo "redmine:pass" | chpasswd
## chown -R www-data:www-data $REDMINE_PATH/redmine-$REDMINE_VER/{public,tmp,log,files}
# chown -R apache:apache $REDMINE_PATH/redmine-$REDMINE_VER

# plugin install
cd $REDMINE_PATH/redmine-$REDMINE_VER/plugins
wget https://bitbucket.org/haru_iida/redmine_code_review/downloads/redmine_code_review-0.6.5.zip
unzip -q redmine_code_review-0.6.5.zip
rm -f redmine_code_review-0.6.5.zip

cd $REDMINE_PATH/redmine-$REDMINE_VER
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
