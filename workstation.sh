################################################################################
# Installs these main packages:
# - RVM
# - Ruby
# - Chef

# Author: Mike Metral
# Company: Rackspace Hosting
# Dept.: Cloud Builders
# Email: mike.metral@rackspace.com
# Date: 06/19/12
################################################################################

## Setup environment settings ##

ruby_version="1.9.3"
log_file="install.log"

################################################################################

## Install dependencies ##

sudo apt-get update

# TODO: pulled these from `rvm requirements` - might want to script this parsing
sudo apt-get install -y build-essential openssl libreadline6 libreadline6-dev \
curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 \
libxml2-dev libxslt1-dev autoconf libc6-dev libncurses5-dev automake libtool bison \
subversion libmysqlclient-dev nodejs

################################################################################

## Install RVM ##

echo -e "\n=> Installing RVM...\n"
curl -O -L -k https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer
chmod +x rvm-installer

"$PWD/rvm-installer" > $log_file 2>&1

[[ -f rvm-installer ]] && rm -f rvm-installer

################################################################################

## Configure environment to work with RVM ##

echo -e "\n=> Setting up RVM to load with new shells..."

#if RVM is installed as user root it goes to /usr/local/rvm/ not ~/.rvm
rvm_script_path="\"$HOME/.rvm/scripts/rvm\""
rvm_script_root_path="\"/usr/local/rvm/scripts/rvm\""

if [ -f ~/.bashrc ] ; then
    if [ `whoami` == 'root' ] ; then
        echo  '[[ -s '$rvm_script_root_path' ]] && . '$rvm_script_root_path'  # Load RVM into a shell session *as a function*' >> "$HOME/.bashrc"
    else
        echo  '[[ -s '$rvm_script_path' ]] && . '$rvm_script_path'  # Load RVM into a shell session *as a function*' >> "$HOME/.bashrc"
    fi
fi

if [ -f ~/.bash_profile ] ; then
    if [ `whoami` == 'root' ] ; then
        echo  '[[ -s '$rvm_script_root_path' ]] && . '$rvm_script_root_path'  # Load RVM into a shell session *as a function*' >> "$HOME/.bash_profile"
    else
        echo  '[[ -s '$rvm_script_path' ]] && . '$rvm_script_path'  # Load RVM into a shell session *as a function*' >> "$HOME/.bash_profile"
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

echo "==> done..."

################################################################################

## Install Ruby ##

echo -e "\n=> Installing Ruby $ruby_version (this will take a while)..."
echo -e "=> More information about installing rubies can be found at http://rvm.beginrescueend.com/rubies/installing/ \n"

# Load RVM into shell
[[ -s "/usr/local/rvm/scripts/rvm" ]] && . "/usr/local/rvm/scripts/rvm"  # Load RVM into a shell session *as a function*

if [ `whoami` == 'root' ] ; then
/usr/local/rvm/bin/rvm install $ruby_version
else
~/.rvm/bin/rvm install $ruby_version
fi

echo -e "\n==> done..."
echo -e "\n=> Using $ruby_version and setting it as default for new shells..."
echo "=> More information about Rubies can be found at http://rvm.beginrescueend.com/rubies/default/"

# Load RVM into shell
[[ -s "/usr/local/rvm/scripts/rvm" ]] && . "/usr/local/rvm/scripts/rvm"  # Load RVM into a shell session *as a function*
rvm --default use $ruby_version

echo "==> done..."

################################################################################

## Install Chef Gem ##

# Load RVM into shell
[[ -s "/usr/local/rvm/scripts/rvm" ]] && . "/usr/local/rvm/scripts/rvm"  # Load RVM into a shell session *as a function*

if [ `whoami` == 'root' ] ; then
gem install chef --no-ri --no-rdoc
else
sudo gem install chef --no-ri --no-rdoc
fi

################################################################################

## Setup Chef Workstation ##

git clone git://github.com/opscode/chef-repo.git ~/chef-repo
mkdir -p ~/chef-repo/.chef

################################################################################
