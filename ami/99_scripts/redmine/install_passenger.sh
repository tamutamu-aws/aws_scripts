gem install rack -v=1.6.4
gem install passenger -v=5.0.30 --conservative

passenger-install-apache2-module --auto --languages ruby
passenger-install-apache2-module --snippet > passenger-compiled.conf

awk '{new=$0; print old; old=new}END{print "  PassengerDefaultGroup apache\n  PassengerDefaultGroup apache"; print old}' < passenger-compiled.conf > passenger-compiled-final.conf
mv passenger-compiled-final.conf /etc/httpd/conf.d/passenger.conf
rm -rf passenger-compiled.conf

cat << EOT >> /etc/httpd/conf.d/passenger.conf

RackBaseURI /redmine
RailsEnv production
 
Header always unset "X-Powered-By"
Header always unset "X-Rack-Cache"
Header always unset "X-Content-Digest"
Header always unset "X-Runtime"
 
PassengerMaxPoolSize 20
PassengerMaxInstancesPerApp 4
PassengerPoolIdleTime 3600
PassengerHighPerformance on
PassengerStatThrottleRate 10
PassengerSpawnMethod smart
RailsAppSpawnerIdleTime 86400
PassengerMaxPreloaderIdleTime 0
EOT

ln -s $REDMINE_PATH/redmine-$REDMINE_VER/public/ /var/www/html/redmine
chown -R apache:apache $REDMINE_PATH/redmine-$REDMINE_VER

systemctl restart httpd.service
