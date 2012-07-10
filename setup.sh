################################################################################
#!/bin/bash
#-------------------------------------------------------------------------------
# Installs & configures the environment an OpsCode Hosted Chef setup

# Author: Mike Metral
# Company: Rackspace
# Dept: Cloud Builders
# Email: mike.metral@rackspace.com
# Date: 06/19/12

# Credits & Acknowledgements:
# - RVM + Ruby Installation: https://github.com/joshfng/railsready

#-------------------------------------------------------------------------------
## Configure script settings ##

ruby_version="1.9.3"
log_file="install.log"
setup_conf=setup.conf
chef_repo_path=~/chef-repo
chef_keys_config_path=./chef
client_configs_path=~/client_configs
packages=( 'rvm' 'ruby' 'chef-client' )

# These variables are NOT to be configured by user
missing_packages=()
CHEF_CLIENT_NODE_NAME=`hostname`
CHEF_ORGNAME=""

#-------------------------------------------------------------------------------
## Perform checks to make sure all is in its right place before installation

check_chef_setup() {
    if [ -d $chef_keys_config_path ] ; then
        if [ ! -f $chef_keys_config_path/knife.rb ] ; then
            echo -n "ERROR: Knife config file (knife.rb) does not exist in: "
            echo $chef_keys_config_path
            exit
        fi

        validation_key=`cat $chef_keys_config_path/knife.rb \
            | grep validation_key | awk '{print $2}' | xargs basename`
        client_key=`cat $chef_keys_config_path/knife.rb \
            | grep client_key | awk '{print $2}' | xargs basename`
        CHEF_ORGNAME=`cat $chef_keys_config_path/knife.rb \
            | grep validation_client_name | awk '{print $2}' \
            | tr -d "\"" | cut -d '-' -f1`

        if [ ! -f $chef_keys_config_path/$validation_key ] ; then
            echo -n "ERROR: Validation key ("$validation_key") "
            echo -n "does not exist in: "
            echo $chef_keys_config_path
            exit
        fi
        if [ ! -f $chef_keys_config_path/$client_key ] ; then
            echo -n "ERROR: Client key ("$client_key") does not exist in: "
            echo $chef_keys_config_path
            exit
        fi
    else
        echo -n "ERROR: Chef keys/config directory does not exist: "
        echo $chef_keys_config_path
        exit
    fi
}

check_install_packages() {

    for i in "${packages[@]}"
    do
        command -v $i >/dev/null 2>&1 || { missing_packages+=($i); }
    done
}

preinstall_checks() {
    check_chef_setup
    check_install_packages
}

#-------------------------------------------------------------------------------
## Determines if package needs to be installed

package_needed() {
    for i in "${missing_packages[@]}"
    do
        if [ "$1" == "$i" ]; then
            return 0
        fi
    done

    return 1
}

#-------------------------------------------------------------------------------
## Welcome ##

welcome() {
    echo -e "\n** This script will setup OpsCode Hosted Chef on your system **"
    echo -e "\n** Logs will be written to: $log_file **"
}

#-------------------------------------------------------------------------------
## Update the apt-get repos ##

update_repos() {
    echo -e "\n=> Updating apt-get repos..."
    sudo apt-get update > $log_file 2>&1
    echo "==> done."
}

#-------------------------------------------------------------------------------
## Install dependencies ##

install_dependencies() {
    echo -e "\n=> Installing RVM dependencies from repos..."

    # TODO: pulled from `rvm requirements` for Ubuntu - script this?
    sudo apt-get install -y build-essential openssl libreadline6 \
        libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev \
        libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev \
        autoconf libc6-dev libncurses5-dev automake \
        libtool bison subversion libmysqlclient-dev nodejs >> $log_file 2>&1

    echo "==> done."
}

#-------------------------------------------------------------------------------
## Install RVM ##

install_rvm() {
    echo -e "\n=> Installing RVM..."

    curl -O -L -k \
    https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer \
    >> $log_file 2>&1

    chmod +x rvm-installer
    "$PWD/rvm-installer" >> $log_file 2>&1

    [[ -f rvm-installer ]] >> $log_file 2>&1 && rm -f rvm-installer

    echo "==> done."
}

#-------------------------------------------------------------------------------
## Configure the shell environment to work with RVM ##

update_shell_config() {
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
            # Load RVM into shell session *as a function*'
            >> "$HOME/.bash_profile"
        else
            echo  '[[ -s '$rvm_script_path' ]] && . '$rvm_script_path'
            # Load RVM into shell session *as a function*'
            >> "$HOME/.bash_profile"
        fi
    fi

    echo "==> done."
}

#-------------------------------------------------------------------------------
# Source the current shell environment

source_shell_config () {
    echo "=> Sourcing shell environment..."

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

    echo "==> done."
}
#-------------------------------------------------------------------------------
## Load RVM into the current shell to use RVM, Ruby & Gem ##

load_rvm_into_shell() {

    [[ -s "/usr/local/rvm/scripts/rvm" ]] && . "/usr/local/rvm/scripts/rvm"

}

#-------------------------------------------------------------------------------
## Install Ruby ##

install_ruby() {
    echo -e "\n=> Installing Ruby $ruby_version via RVM..."

    load_rvm_into_shell
    if [ `whoami` == 'root' ] ; then
        /usr/local/rvm/bin/rvm install $ruby_version >> $log_file 2>&1
    else
        ~/.rvm/bin/rvm install $ruby_version >> $log_file 2>&1
    fi

    echo -e "==> done."
    echo -e "=> Using $ruby_version and setting it as default for new shells..."

    load_rvm_into_shell
    rvm --default use $ruby_version >> $log_file 2>&1

    echo "==> done."
}

#-------------------------------------------------------------------------------
## Install Chef Gem ##

install_chef_gem() {
    load_rvm_into_shell

    echo -e "\n=> Installing Chef Gem..."

    if [ `whoami` == 'root' ] ; then
        gem install chef --no-ri --no-rdoc >> $log_file 2>&1
    else
        sudo gem install chef --no-ri --no-rdoc >> $log_file 2>&1
    fi

    echo "==> done."
}

#-------------------------------------------------------------------------------
## Setup Chef Workstation Repo ##

setup_workstation_repo() {
    echo -e "==> Cloning Chef Workstation chef-repo locally from git..."

    git clone git://github.com/opscode/chef-repo.git $chef_repo_path \
        >> $log_file 2>&1
    echo "===> done."

    echo -e "==> Copying Chef config directory (.chef) into chef-repo..."
    cp -rf $chef_keys_config_path $chef_repo_path/.chef/

    echo "===> done."
}

#-------------------------------------------------------------------------------
## Upload RCBOps' Cookbooks & Roles to Hosted Chef ##

upload_cookbooks_roles() {
    echo -e "==> Setting up cookbooks on Chef..."
    echo -e "===> Cloning RCBOps chef-cookbooks locally from git..."
    cd $chef_repo_path/cookbooks
    git clone --recursive git://github.com/rcbops/chef-cookbooks.git \
        >> $log_file 2>&1
    echo "====> done."

    echo -e "===> Uploading RCBOps' cookbooks to Chef Server..."
    cd $chef_repo_path/cookbooks/chef-cookbooks
    knife cookbook upload -o cookbooks --all >> $log_file 2>&1
    echo "====> done."

    echo -e "===> Uploading RCBOps' roles to Chef Server..."
    rake roles >> $log_file 2>&1
    echo "====> done."
    echo "===> done."
}

#-------------------------------------------------------------------------------
## Good-bye ##

goodbye() {
    echo -e "\n** All done. Good-bye! **\n"
}

#-------------------------------------------------------------------------------
## Setup & configure the chef-workstation specific files & settings

setup_chef_workstation() {
    echo -e "\n=> Setting up Chef Workstation..."
    setup_workstation_repo
    upload_cookbooks_roles
    echo "==> done."
}

#-------------------------------------------------------------------------------
## Setup & configure the chef-client specific settings

setup_chef_client() {
    echo -e "\n=> Setting up Chef Client..."
    sudo rm -rf /etc/chef
    sudo mkdir -p /etc/chef

    # Copy key & conf for initial node setup & configure it
    validation_key=`cat $chef_keys_config_path/knife.rb \
        | grep validation_key | awk '{print $2}' | xargs basename`

    sudo cp -rf $chef_keys_config_path/$validation_key /etc/chef/
    sudo cp -rf $client_configs_path/client-initial_setup.rb /etc/chef/client.rb
    sudo sed -i 's/CHEF_ORGNAME/'$CHEF_ORGNAME'/g' /etc/chef/client.rb
    chef-client
    sudo rm -rf /etc/chef/*-validator.pem
    sudo rm -rf /etc/chef/client.rb

    # Copy key & config for proceeding new client usage
    sudo cp -rf $client_configs_path/client.rb /etc/chef/
    sudo sed -i 's/CHEF_ORGNAME/'$CHEF_ORGNAME'/g' /etc/chef/client.rb
    sudo sed -i 's/CHEF_CLIENT_NODE_NAME/'$CHEF_CLIENT_NODE_NAME'/g' \
        /etc/chef/client.rb
    chef-client
    echo "==> done."
}

#-------------------------------------------------------------------------------
## Base install of packages for OpsCode Chef ##

base_install() {
    welcome
    update_repos

    if package_needed rvm ; then
        install_dependencies
        install_rvm
        update_shell_config
        source_shell_config
    fi

    if package_needed ruby  ; then
        install_ruby
    fi

    if package_needed chef-client  ; then
        install_chef_gem
    fi

    echo -e "\n** Chef is configured on the system **"
    echo -e "\n** You should restart the system for good measures **"
}
#-------------------------------------------------------------------------------
## Main ##

# Perform base install
# This base install applies to both Chef Workstation & Client

source setup.conf

if [ "$CHEF_ORGNAME" == 'INSERT_CHEF_ORGNAME' ] ; then
    echo "ERROR: Insert an organization name in $setup_conf"
    exit
fi

if preinstall_checks; then
    base_install

    # Setup chef-workstation, if enabled
    if [ "$CHEF_WORKSTATION" == "True" ] || [ "$CHEF_WORKSTATION" == "true" ] ||
        [ "$CHEF_WORKSTATION" == "TRUE" ] ; then
        setup_chef_workstation
    fi

    # Setup chef-client, if enabled
    if [ "$CHEF_CLIENT" == "True" ] || [ "$CHEF_CLIENT" == "true" ] ||
        [ "$CHEF_CLIENT" == "TRUE" ] ; then
        setup_chef_client
    fi
fi

goodbye
################################################################################
