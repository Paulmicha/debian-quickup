#!/bin/bash
# -*- coding: UTF8 -*-

##
#   Redmine plugins setup
#   Debian 7 ("Wheezy")
#
#   Redmine 2.5.x ONLY
#   @timestamp 2014/08/28 16:47:43
#   
#

aptitude install unzip -y


#       Issue Checklist
#       @see http://www.redmine.org/plugins/redmine_issue_checklist
cd /opt/redmine/current/plugins/
wget http://redminecrm.com/license_manager/4200/redmine_issue_checklist-2_0_5.zip
unzip redmine_issue_checklist-2_0_5.zip
rm redmine_issue_checklist-2_0_5.zip
RAILS_ENV=production bundle exec rake redmine:plugins NAME=redmine_issue_checklist
service apache2 restart


#       Flatly light theme
#       @see https://github.com/Nitrino/flatly_light_redmine
#       update 2014/08/27 20:26:16 - too much padding in issue list + looks unfinished - ex: font serif on actions...
cd /opt/redmine/current/public/themes
wget https://github.com/Nitrino/flatly_light_redmine/archive/v0.1.tar.gz
tar xzf v0.1.tar.gz
rm v0.1.tar.gz


#       Flat theme for Redmine
#       @see https://github.com/tsi/redmine-theme-flat
#       update 2014/08/27 20:03:40 - ugly popup for editing issues...
#       update 2014/08/27 20:26:53 - for now, use this, as I've found it to be less "bad" than all others
cd /opt/redmine/current/public/themes
wget https://github.com/tsi/redmine-theme-flat/archive/master.zip
unzip master.zip
rm master.zip


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


#       Redmine Dashboard 2
#       @see https://github.com/jgraichen/redmine_dashboard
#       update 2014/08/27 20:40:37 - does NOT work !
#       enabling displays a tab that leads to a 404
#cd /opt/redmine/current/plugins/
#wget https://github.com/jgraichen/redmine_dashboard/archive/v2.3.2.zip
#unzip v2.3.2.zip
#rm v2.3.2.zip
#bundle install
#RAILS_ENV=production rake redmine:plugins:migrate
#service apache2 restart


#       Task Juggler
#       @see http://www.redmine.org/plugins/redmine_taskjuggler
#       @see http://www.taskjuggler.org/tj3/manual/Installation.html#Installation
#       update 2014/08/28 14:56:03 - requires to execute a command manually... -> useless plugin !
#cd /opt/redmine/current/plugins/
#wget https://github.com/chris2fr/redmine_taskjuggler/archive/0.1.0-alpha.3.tar.gz
#tar xzf 0.1.0-alpha.3.tar.gz
#rm 0.1.0-alpha.3.tar.gz
#mv redmine_taskjuggler-0.1.0-alpha.3 redmine_taskjuggler
#RAILS_ENV=production bundle exec rake redmine:plugins


#       Redmine Spent Time
#       @see http://www.redmine.org/plugins/redmine_spent_time
#       update 2014/08/28 15:16:12 - no filter by project... -> not good enough
#cd /opt/redmine/current/plugins/
#git clone https://github.com/eyp/redmine_spent_time.git
#bundle install
#service apache2 restart


#       Redmine Planning plugin
#       @see http://www.redmine.org/plugins/redmine_planning
cd /opt/redmine/current/plugins/
git clone https://github.com/MadEgg/redmine_planning
service apache2 restart


#       Multi-projects issue
#       @see http://www.redmine.org/plugins/redmine_multiprojects_issue
cd /opt/redmine/current/plugins/
git clone https://github.com/jbbarth/redmine_base_select2.git
git clone https://github.com/nanego/redmine_multiprojects_issue.git
bundle install
RAILS_ENV=production rake redmine:plugins
service apache2 restart


#       Paste screenshots into body of Issue - as images
#       @see http://www.redmine.org/plugins/redmine_image_clipboard_paste
#       update 2014/08/28 16:35:06 - doesn't work
#cd /opt/redmine/current/plugins/
#git clone git://github.com/credativUK/redmine_image_clipboard_paste.git redmine_image_clipboard_paste
#bundle install
#RAILS_ENV=production rake redmine:plugins:migrate
#service apache2 restart


#       Redmine Circle theme
#       @see http://redminecrm.com/pages/circle-theme
#       update 2014/08/28 16:47:25 - meh...
#cd /opt/redmine/current/public/themes
#wget http://redminecrm.com/license_manager/11619/circle_theme-1_0_2.zip
#unzip circle_theme-1_0_2.zip
#rm circle_theme-1_0_2.zip




