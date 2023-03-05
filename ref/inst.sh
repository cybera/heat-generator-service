#!/bin/bash
       me=$(whoami)
       echo "I am $me" #root appently
       set -x #debug
       
       wall "Completing Install"
       touch /root/still_installing
       if [[ -f /usr/local/bin/enableAutoUpdate ]]; then
        /usr/local/bin/enableAutoUpdate
       fi
       mkdir /data
       chown ubuntu:ubuntu /data

       wall "Prepping and mounting volume"
       vol="/dev/sdc"
       ip6=$(ip -6 addr show ens3 | awk '/2605/ { print $2 }' | awk 'BEGIN { FS="/"; } { print $1 }')
       dns_name=$(dig +short -x $ip6 @ns-yyc.cloud.cybera.ca)
       dns_name=${dns_name::-1}
       if [[ -e "${vol}" ]]; then
         fs=$(blkid -o value -s TYPE $vol)
         if [[ $fs != "ext4" ]]; then
           mkfs -t ext4 $vol
         fi
         mount $vol /data
         dev_path=$(readlink -f $vol)
         uuid=$(lsblk -no uuid $dev_path)
         echo "UUID=${uuid} /data ext4 defaults 0 1 " | tee --append  /etc/fstab
       fi

       wall "Installing Software"
       wget https://repo.anaconda.com/archive/Anaconda3-2022.10-Linux-x86_64.sh -O ~/anaconda.sh
       bash ~/anaconda.sh -b -p $HOME/anaconda
       eval "$(/root/anaconda/bin/conda shell.bash hook)"
       source ~/anaconda/etc/profile.d/conda.sh
       export PATH=~/anaconda/bin:$PATH >> ~/.bashrc
       source ~/.bashrc
       conda init bash
       echo y | /root/anaconda/bin/conda create --name notebooks python=3.8
       conda activate notebooks
       echo "current env = $CONDA_DEFAULT_ENV"
       mkdir /data/notebooks
       echo y | conda install pip
       echo y | conda install jupyterlab
       repo="https://github.com/cybera/ookla-statcan-analysis.git"
       cd /root

       wall "Installing requirements.txt from your repo"
       git clone ${repo}
       cd "$(basename "${repo}" .git)"
       echo y | conda install --file requirements.txt
       cd ..

       wall "Setting up JupyterLab"
       #hashed=$(python3 -c "from notebook.auth import passwd; import random; import string; output = ''.join(random.choice(string.ascii_letters) for i in range(24)); f = open(\"jupyterpass.txt\", \"a\"); f.write(str(output + \"\n\")); f.close(); print(passwd(str(output)))")
       hashed=$(date +%s | sha256sum | base64 | head -c 24)
       rm -f /etc/systemd/system/jupyter.service
       tee -a /etc/systemd/system/jupyter.service <<EOF
       [Unit]
       Description=Jupyter Notebook
       [Service]
       Type=simple
       PIDFile=/run/jupyter.pid
       ExecStart=/root/anaconda/envs/notebooks/bin/jupyter lab --ip='*' --notebook-dir=/data/notebooks --allow-root --no-browser --NotebookApp.password=${hashed}
       User=root
       Group=root
       Restart=always
       RestartSec=10

       [Install]
       WantedBy=multi-user.target
       EOF

       wall "Starting Services"
       systemctl daemon-reload
       systemctl enable jupyter
       systemctl start jupyter
       mv /root/still_installing /root/install_complete
       ip4=$(hostname -I | cut -d' ' -f1)
       wall "Install Complete! You should now be able to go to http://${ip4}:8888/lab and use the password in jupyterpass.txt to log in"
