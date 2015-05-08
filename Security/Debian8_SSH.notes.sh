#!/bin/bash
# -*- coding: UTF8 -*-

##
#   SSH public/private RSA key pair :
#   • Setup
#   • Generation
#   • Use in Git repo
#   • Convert existing Git repo that was cloned using https
#
#   Tested in :
#   Debian 8 "Jessie"
#   
#   @timestamp 2015/05/08 14:36:05
#   
#   Sources :
#   https://confluence.atlassian.com/pages/viewpage.action?pageId=270827678
#

#       If needed, install ssh
#ssh -v
#aptitude install ssh -y

#       Start generating public/private RSA key pair
#       Note : passphrase is optional (but recommended)
ssh-keygen

#       Check result
#       (this lists the generated public/private RSA key pair)
#cd ~/.ssh
#ls -lah

#       Verify ssh-agent is running
#       (this should return something like : 1746 ?  00:00:00 ssh-agent)
ps -e | grep [s]sh-agent
#       Run it if it's not
ssh-agent /bin/bash

#       Load your new identity into the ssh-agent management program
#       Note : will prompt for passphrase if one was set
ssh-add ~/.ssh/id_rsa

#       Check result
#       (this lists the keys that the agent is managing)
#ssh-add -l


#       Clients will need the public key,
#       copy/paste the result of :
cat ~/.ssh/id_rsa.pub



#----------------------------------------
#       Git clone format

#       If using SSH public/private RSA key pair,
#       use this Git clone syntax - example :
git clone git@bitbucket.org:accountname/reponame.git
#       or
git clone ssh://git@bitbucket.org/accountname/reponame.git



#----------------------------------------
#       Convert an existing Git repo
#       that was cloned using HTTPS
#       to use SSH in remote origin

cd /path/to/repo
nano .git/config

#       Edit the section [remote "origin"]
#       to put SSH syntax in "url", example :
[remote "origin"]
    fetch = +refs/heads/*:refs/remotes/origin/*
    url = git@bitbucket.org:accountname/reponame.git


