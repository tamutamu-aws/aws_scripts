echo 'Install Backlogs plugin'


cd $REDMINE_PATH/redmine-$REDMINE_VER/plugins
git clone https://github.com/backlogs/redmine_backlogs.git
git checkout -b 1.0.6 refs/tags/v1.0.6

yum -y install libxml2 libxml2-devel
yum -y install libxslt libxslt-devel

gem install holidays --version 1.0.3
gem install holidays

sed -i.orig -e 's/gem "prawn".*/gem "prawn", "=0.12.0"/' ./redmine_backlogs/Gemfile

cd $REDMINE_PATH/redmine-$REDMINE_VER

bundle install --without development test

bundle exec rake db:migrate RAILS_ENV=production
bundle exec rake tmp:cache:clear RAILS_ENV=production
bundle exec rake tmp:sessions:clear RAILS_ENV=production

# Setting pdf
\cp -f $REDMINE_PATH/redmine-$REDMINE_VER/plugins/redmine_backlogs/lib/labels/labels.yaml{.default,}
wget http://dl.ipafont.ipa.go.jp/IPAexfont/IPAexfont00301.zip -O /tmp/IPAexfont00301.zip

pushd /tmp

unzip -q IPAexfont00301.zip
mv /tmp/IPAexfont00301/*.ttf $REDMINE_PATH/redmine-$REDMINE_VER/plugins/redmine_backlogs/lib/ttf/

popd


pushd $REDMINE_PATH/redmine-$REDMINE_VER/plugins/redmine_backlogs/lib

cp ./backlogs_printable_cards.{rb,old}
sed -i -e 's/D.*Bold\.ttf"/ipaexg.ttf"/' ./backlogs_printable_cards.rb
sed -i -e 's/D.*Oblique\.ttf"/ipaexg.ttf"/' ./backlogs_printable_cards.rb
sed -i -e 's/D.*BoldOblique\.ttf"/ipaexg.ttf"/' ./backlogs_printable_cards.rb
sed -i -e 's/DejaVuSans.ttf"/ipaexg.ttf"/' ./backlogs_printable_cards.rb

popd

bundle exec rake redmine:backlogs:install RAILS_ENV=production story_trackers=story task_tracker=task
