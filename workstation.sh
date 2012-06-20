################################################################################
# Installs & configures the environment for these main packages:
# - RVM
# - Ruby
# - Chef

# Author: Mike Metral
# Company: Rackspace
# Dept.: Cloud Builders
# Email: mike.metral@rackspace.com
# Date: 06/19/12
# Credit: https://github.com/joshfng/railsready
################################################################################

## Setup environment settings ##

ruby_version="1.9.3"
log_file="install.log"

################################################################################

## Welcome ##

echo -e "\n** This script is intended for a Linux OpsCode Chef Workstation **"
echo -e "\n** The packages that will be installed & setup: RVM, Ruby & Chef **"
echo -e "Logs will be written to: $log_file"

################################################################################

## Install dependencies ##

echo -e "\n=> Updating apt-get repos..."
sudo apt-get -qq update
echo "==> done..."

echo -e "\n=> Installing RVM dependencies from repos..."
# TODO: pulled from `rvm requirements` - might want to script this parsing
sudo apt-get install -qqq -y build-essential openssl libreadline6 libreadline6-dev \
curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 \
libxml2-dev libxslt1-dev autoconf libc6-dev libncurses5-dev automake \
libtool bison subversion libmysqlclient-dev nodejs
echo "==> done..."

################################################################################

## Install RVM ##

echo -e "\n=> Installing RVM..."
curl -O -L -k \
    https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer \
    > $log_file 2>&1
	
chmod +x rvm-installer

"$PWD/rvm-installer" > $log_file 2>&1

[[ -f rvm-installer ]] > $log_file 2>&1 && rm -f rvm-installer

echo "==> done..."

################################################################################

## Configure environment to work with RVM ##

echo -e "=> Setting up RVM to load with new shells..."

#if RVM is installed as user root it goes to /usr/local/rvm/ not ~/.rvm
rvm_script_path="\"$HOME/.rvm/scripts/rvm\""
rvm_script_root_path="\"/usr/local/rvm/scripts/rvm\""

if [ -f ~/.bashrc ] ; then
    if [ `whoami` == 'root' ] ; then
        echo  '[[ -s '$rvm_script_root_path' ]] && . '$rvm_script_root_path'
        # Load RVM into shell session *as a function*' >> "$HOME/.bashrc"
    else
        echo  '[[ -s '$rvm_script_path' ]] && . '$rvm_script_path'
        # Load RVM into shell session *as a function*' >> "$HOME/.bashrc"
    fi
fi

if [ -f ~/.bash_profile ] ; then
    if [ `whoami` == 'root' ] ; then
        echo  '[[ -s '$rvm_script_root_path' ]] && . '$rvm_script_root_path'
        # Load RVM into shell session *as a function*' >> "$HOME/.bash_profile"
    else
        echo  '[[ -s '$rvm_script_path' ]] && . '$rvm_script_path'
        # Load RVM into shell session *as a function*' >> "$HOME/.bash_profile"
    fi
fi
echo "==> done..."

echo "=> Loading RVM..."
if [ -f ~/.bashrc ] ; then
source ~/.bashrc
fi
if [ -f ~/.bash_profile ] ; then
source ~/.bash_profile
fi
if [ -f ~/.rvm/scripts/rvm ] ; then
source ~/.rvm/scripts/rvm
fi
if [ -f /usr/local/rvm/scripts/rvm ] ; then
source /usr/local/rvm/scripts/rvm
fi

echo "==> done..."

################################################################################

## Install Ruby ##

echo -e "\n=> Installing Ruby $ruby_version (this will take a while)..."

# Load RVM into shell
[[ -s "/usr/local/rvm/scripts/rvm" ]] && . "/usr/local/rvm/scripts/rvm"

if [ `whoami` == 'root' ] ; then
/usr/local/rvm/bin/rvm install $ruby_version > $log_file 2>&1
else
~/.rvm/bin/rvm install $ruby_version > $log_file 2>&1
fi

echo -e "==> done..."
echo -e "=> Using $ruby_version and setting it as default for new shells..."

# Load RVM into shell
[[ -s "/usr/local/rvm/scripts/rvm" ]] && . "/usr/local/rvm/scripts/rvm"
rvm --default use $ruby_version > $log_file 2>&1

echo "==> done..."

################################################################################

## Install Chef Gem ##

# Load RVM into shell
[[ -s "/usr/local/rvm/scripts/rvm" ]] && . "/usr/local/rvm/scripts/rvm"

echo -e "\n=> Installing Chef Gem..."
if [ `whoami` == 'root' ] ; then
gem install chef --no-ri --no-rdoc > $log_file 2>&1
else
sudo gem install chef --no-ri --no-rdoc > $log_file 2>&1
fi
echo "==> done..."

################################################################################

## Setup Chef Workstation ##

echo -e "\n=> Cloning Chef Workstation skeleton chef-repo..."
git clone git://github.com/opscode/chef-repo.git ~/chef-repo > $log_file 2>&1
mkdir -p ~/chef-repo/.chef
echo "==> done..."

echo -e "\n=> Configuring user & organization keys + knife configuration..."
# TODO: copy keys from dir
echo "==> done..."

################################################################################

## Good-bye ##

echo -e "\n** All done. Good-bye! **\n"

################################################################################
