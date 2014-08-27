#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Redmine plugins setup
#   Debian 7 ("Wheezy")
#
#   Redmine 2.5.x ONLY
#   @timestamp 2014/08/27 19:15:58 - 2014/08/27 20:14:56
#   
#

aptitude install unzip -y


#       redmine_issue_checklist
#       @see http://www.redmine.org/plugins/redmine_issue_checklist
cd /opt/redmine/current/plugins/
wget http://redminecrm.com/license_manager/4200/redmine_issue_checklist-2_0_5.zip
unzip redmine_issue_checklist-2_0_5.zip
rm redmine_issue_checklist-2_0_5.zip
bundle exec rake redmine:plugins NAME=redmine_issue_checklist RAILS_ENV=production
service apache2 restart


#       Flatly light theme
#       @see https://github.com/Nitrino/flatly_light_redmine
cd /opt/redmine/current/public/themes
wget https://github.com/Nitrino/flatly_light_redmine/archive/v0.1.tar.gz
tar xzf v0.1.tar.gz
rm v0.1.tar.gz


#       Flat theme for Redmine
#       @see https://github.com/tsi/redmine-theme-flat
#       update 2014/08/27 20:03:40 - ugly popup for editing issues... -> out
#cd /opt/redmine/current/public/themes
#wget https://github.com/tsi/redmine-theme-flat/archive/master.zip
#unzip master.zip
#rm master.zip

#       Metro Redmine
#       @see https://github.com/astout/metro_redmine
#       update 2014/08/27 20:05:26 - not good enough...
#cd /opt/redmine/current/public/themes
#wget https://github.com/astout/metro_redmine/archive/master.zip
#unzip master.zip
#rm master.zip


#       Knowledge base
#       @see http://www.redmine.org/plugins/redmine_knowledgebase
cd /opt/redmine/current/plugins/
git clone git://github.com/alexbevi/redmine_knowledgebase.git redmine_knowledgebase
bundle install
RAILS_ENV=production rake redmine:plugins:migrate NAME=redmine_knowledgebase
service apache2 restart


#       Work Time
#       @see http://www.redmine.org/plugins/worktime
cd /opt/redmine/current/plugins/
wget https://bitbucket.org/tkusukawa/redmine_work_time/downloads/redmine_work_time-0.2.15.zip
unzip redmine_work_time-0.2.15.zip
rm redmine_work_time-0.2.15.zip
RAILS_ENV=production rake redmine:plugins:migrate


#       DMSF
#       @see http://www.redmine.org/plugins/dmsf
#       postponed (looks too heavy)


#       Monitoring & Controlling
#       @see http://www.redmine.org/plugins/monitoring-controlling
#       Redmine 1.4.x -> abandonned


