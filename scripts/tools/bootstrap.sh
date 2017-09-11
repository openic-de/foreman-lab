#!/usr/bin/env bash

sudo yum -y install git python-pip vim-enhanced tmux python-pip
sudo pip install --upgrade pip
sudo pip install powerline-status

cat >/etc/profile.d/powerline-status.sh <<EOL
#!/usr/bin/env bash

if [ -f `which powerline-daemon` ]; then
  powerline-daemon -q
  POWERLINE_BASH_CONTINUATION=1
  POWERLINE_BASH_SELECT=1
  . /usr/lib/python2.7/site-packages/powerline/bindings/bash/powerline.sh
fi
EOL

git clone https://github.com/amix/vimrc.git ~/.vim_runtime
. ~/.vim_runtime/install_awesome_vimrc.sh

cat >>~/.vimrc <<EOL
python from powerline.vim import setup as powerline_setup
python powerline_setup()
python del powerline_setup
set laststatus=2
set t_Co=256
EOL

cat >>~/.tmux <<EOL
source /usr/lib/python2.7/site-packages/powerline/bindings/tmux/powerline.conf
EOL

sudo yum -y install tuned tuned-profile tuned-utils
sudo tuned-adm profile virtual-guest

sudo cat >/etc/selinux/config <<EOL
SELINUX=disabled
SELINUXTYPE=targeted
EOL
