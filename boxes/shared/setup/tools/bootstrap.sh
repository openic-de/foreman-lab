#!/usr/bin/env bash

source /tmp/common.sh

log-progress-nl "begin"

log-execute "sudo yum -y install git python-pip vim-enhanced tmux python-pip" "installing git pip vim tmux"
log-execute "sudo pip install --upgrade pip" "pip: upgrading system"
log-execute "sudo pip install powerline-status" "installing powerline-status"

sudo cat >/etc/profile.d/powerline-status.sh <<EOL
#!/usr/bin/env bash

if [ -f `which powerline-daemon` ]; then
  powerline-daemon -q
  POWERLINE_BASH_CONTINUATION=1
  POWERLINE_BASH_SELECT=1
  . /usr/lib/python2.7/site-packages/powerline/bindings/bash/powerline.sh
fi
EOL

log-execute "git clone https://github.com/amix/vimrc.git ~/.vim_runtime" "git: cloning amix vimrc"
log-execute ". ~/.vim_runtime/install_awesome_vimrc.sh" "sourcing amix awesome vimrc"

log-progress-nl "setting up .vimrc"
cat >>~/.vimrc <<EOL
python from powerline.vim import setup as powerline_setup
python powerline_setup()
python del powerline_setup
set laststatus=2
set t_Co=256
EOL

log-progress-nl "setting up .tmux"
cat >>~/.tmux <<EOL
source /usr/lib/python2.7/site-packages/powerline/bindings/tmux/powerline.conf
EOL

log-execute "sudo yum -y install tuned tuned-profile tuned-utils" "installing tuned, its utils and profiles"
log-execute "sudo tuned-adm profile virtual-guest" "tuning system for virtual-guest performance"

log-progress-nl "disabling selinux"
sudo cat >/etc/selinux/config <<EOL
SELINUX=disabled
SELINUXTYPE=targeted
EOL

log-progress-nl "done"
