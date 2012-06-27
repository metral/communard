################################################################################
#!/bin/bash
#-------------------------------------------------------------------------------
# Installs & configures the environment for these main packages:
# - RVM
# - Ruby
# - Ruby Gems
# - OpsCode Chef

# Also configures chef-workstation or chef-client appropriately

# Author: Mike Metral
# Company: Rackspace
# Dept: Cloud Builders
# Email: mike.metral@rackspace.com
# Date: 06/19/12
# RVM + Ruby Install Credit: https://github.com/joshfng/railsready

#-------------------------------------------------------------------------------
## Configure script settings ##

ruby_version="1.9.3"
log_file="install.log"
chef_repo_path=~/chef-repo
chef_keys_config_path=~/.chef
client_configs_path=~/client_configs

source setup.conf

#-------------------------------------------------------------------------------
## Welcome ##

welcome() {
    echo -e "\n** These main packages will be installed & setup:"
    echo -e "     -- RVM"
    echo -e "     -- Ruby"
    echo -e "     -- Ruby Gems"
    echo -e "     -- Chef"
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

    # TODO: pulled from `rvm requirements` - might want to script this parsing
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

    #TODO: fix line break of URL
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
    echo -e "\n=> Cloning Chef Workstation skeleton chef-repo locally..."

    git clone git://github.com/opscode/chef-repo.git $chef_repo_path \
        >> $log_file 2>&1
    echo "==> done."

    echo -e "\n=> Copying Chef configuration directory (.chef)..."
    #cp -rf .chef $chef_repo_path/
    cp -rf $chef_keys_config_path $chef_repo_path/

    echo "==> done."
}

#-------------------------------------------------------------------------------
## Upload RCBOps' Cookbooks & Roles to Hosted Chef ##

upload_cookbooks_roles() {
    echo -e "\n=> Setting up cookbooks on Chef..."
    echo -e "=> Cloning RCBOps chef-cookbooks locally..."
    cd $chef_repo_path/cookbooks
    git clone --recursive git://github.com/rcbops/chef-cookbooks.git \
        >> $log_file 2>&1
    echo "==> done."

    echo -e "=> Uploading RCBOps' cookbooks to Chef..."
    cd $chef_repo_path/cookbooks/chef-cookbooks
    knife cookbook upload -o cookbooks --all >> $log_file 2>&1
    echo "==> done."

    echo -e "=> Uploading RCBOps' roles to Chef..."
    rake roles >> $log_file 2>&1
    echo "==> done."
}

#-------------------------------------------------------------------------------
## Good-bye ##

goodbye() {
    echo -e "\n** All done. Good-bye! **\n"
    echo -e "\n** You should restart the machine for good measures. **\n"
}

#-------------------------------------------------------------------------------
## Setup & configure the chef-workstation specific files & settings

setup_chef_workstation() {
    setup_workstation_repo
    upload_cookbooks_roles
}

#-------------------------------------------------------------------------------
## Setup & configure the chef-client specific settings

setup_chef_client() {
    mkdir -p /etc/chef

    # Copy key & conf for initial node setup & configure it
    cp -rf $chef_keys_config_path/*-validator.pem /etc/chef/
    cp -rf $client_configs_path/client-initial_setup.rb /etc/chef/client.rb
    sed -i 's/ORGNAME/'$ORGNAME'/g' /etc/chef/client.rb
    chef-client
    rm -rf /etc/chef/*-validator.pem
    rm -rf /etc/chef/client.rb

    # Copy key & config for proceeding new client usage
    cp -rf $client_configs_path/client.rb /etc/chef/
    sed -i 's/ORGNAME/'$ORGNAME'/g' /etc/chef/client.rb
    sed -i 's/CLIENT_NAME/'$CLIENT_NAME'/g' /etc/chef/client.rb
    chef-client
}

#-------------------------------------------------------------------------------
## Base install of packages for OpsCode Chef ##

base_install() {
    welcome
    update_repos
    install_dependencies
    install_rvm
    update_shell_config
    source_shell_config
    install_ruby
    install_chef_gem
}
#-------------------------------------------------------------------------------
## Main ##

# Perform base install of RVM, Ruby, Ruby Gems & Chef
# This base install applies to both Chef Workstation & Client
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

goodbye
################################################################################
