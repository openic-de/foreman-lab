#!/usr/bin/env bash

sudo cat >/etc/yum.repos.d/CentOS-Base.repo <<EOL
[base]
name=CentOS-7 - Base
baseurl=http://mirror/centos/7/os/x86_64/
gpgcheck=1
gpgkey=http://mirror/centos/RPM-GPG-KEY-CentOS-7
#released updates

[update]
name=CentOS-7 - Updates
baseurl=http://mirror/centos/7/updates/x86_64/
gpgcheck=1
gpgkey=http://mirror/centos/RPM-GPG-KEY-CentOS-7

[extras]
name=CentOS-7 - Extras
baseurl=http://mirror/centos/7/extras/x86_64/
gpgcheck=1
gpgkey=http://mirror/centos/RPM-GPG-KEY-CentOS-7

[centosplus]
name=CentOS-7 - Plus
baseurl=http://mirror/centos/7/centosplus/x86_64/
gpgcheck=1
enabled=1
gpgkey=http://mirror/centos/RPM-GPG-KEY-CentOS-7
EOL

sudo cat >/etc/yum.repos.d/epel.repo <<EOL
[epel]
name=Extra Packages for Enterprise Linux 7 - x86_64
baseurl=http://mirror/epel/7/x86_64/
enabled=1
gpgcheck=1
gpgkey=http://mirror/epel/RPM-GPG-KEY-EPEL-7

[epel-debuginfo]
name=Extra Packages for Enterprise Linux 7 - x86_64 - Debug
baseurl=http://mirror/epel/7/x86_64/debug
enabled=0
gpgkey=http://mirror/epel/RPM-GPG-KEY-EPEL-7
gpgcheck=1

EOL

sudo cat >/etc/yum.repos.d/puppetlabs.repo <<EOL
[puppetlabs-products]
name=Puppet Labs Products El 7 - x86_64
baseurl=http://mirror/puppetlabs/el/7/products/x86_64
gpgkey=http://mirror/puppetlabs/RPM-GPG-KEY-puppetlabs
       http://mirror/puppetlabs/RPM-GPG-KEY-puppet
       http://mirror/puppetlabs/RPM-GPG-KEY-reductive
enabled=1
gpgcheck=1

[puppetlabs-deps]
name=Puppet Labs Dependencies El 7 - x86_64
baseurl=http://mirror/puppetlabs/el/7/dependencies/x86_64
gpgkey=http://mirror/puppetlabs/RPM-GPG-KEY-puppetlabs
       http://mirror/puppetlabs/RPM-GPG-KEY-puppet
       http://mirror/puppetlabs/RPM-GPG-KEY-reductive
enabled=1
gpgcheck=1

[puppetlabs-devel]
name=Puppet Labs Devel El 7 - x86_64
baseurl=http://mirror/puppetlabs/el/7/devel/x86_64
gpgkey=http://mirror/puppetlabs/RPM-GPG-KEY-puppetlabs
       http://mirror/puppetlabs/RPM-GPG-KEY-puppet
       http://mirror/puppetlabs/RPM-GPG-KEY-reductive
enabled=0
gpgcheck=1

[puppetlabs-products-source]
name=Puppet Labs Products El 7 - x86_64 - Source
baseurl=http://mirror/puppetlabs/el/7/products/SRPMS
gpgkey=http://mirror/puppetlabs/RPM-GPG-KEY-puppetlabs
       http://mirror/puppetlabs/RPM-GPG-KEY-puppet
       http://mirror/puppetlabs/RPM-GPG-KEY-reductive
failovermethod=priority
enabled=0
gpgcheck=1

[puppetlabs-deps-source]
name=Puppet Labs Source Dependencies El 7 - x86_64 - Source
baseurl=http://mirror/puppetlabs/el/7/dependencies/SRPMS
gpgkey=http://mirror/puppetlabs/RPM-GPG-KEY-puppetlabs
       http://mirror/puppetlabs/RPM-GPG-KEY-puppet
       http://mirror/puppetlabs/RPM-GPG-KEY-reductive
enabled=0
gpgcheck=1

[puppetlabs-devel-source]
name=Puppet Labs Devel El 7 - x86_64 - Source
baseurl=http://mirror/puppetlabs/el/7/devel/SRPMS
gpgkey=http://mirror/puppetlabs/RPM-GPG-KEY-puppetlabs
       http://mirror/puppetlabs/RPM-GPG-KEY-puppet
       http://mirror/puppetlabs/RPM-GPG-KEY-reductive
enabled=0
gpgcheck=1
EOL

sudo cat >/etc/yum.repos.d/foreman.repo <<EOL
[foreman]
name=Foreman 1.14
baseurl=http://mirror/theforeman/releases/1.14/el7/x86_64
enabled=1
gpgcheck=1
gpgkey=http://mirror/theforeman/releases/1.14/RPM-GPG-KEY-foreman

[foreman-source]
name=Foreman 1.14 - source
baseurl=http://mirror/theforeman/releases/1.14/el7/source
enabled=0
gpgcheck=1
gpgkey=http://mirror/theforeman/releases/1.14/RPM-GPG-KEY-foreman
EOL

sudo cat >/etc/yum.repos.d/foreman-plugins.repo <<EOL
[foreman-plugins]
name=Foreman plugins 1.14
baseurl=http://mirror/theforeman/plugins/1.14/el7/x86_64
enabled=1
gpgcheck=0
gpgkey=http://mirror/theforeman/RPM-GPG-KEY-foreman

[foreman-plugins-source]
name=Foreman plugins 1.14 - source
baseurl=http://mirror/theforeman/plugins/1.14/el7/source
enabled=0
gpgcheck=0
gpgkey=http://mirror/theforeman/RPM-GPG-KEY-foreman
EOL
