#!/bin/bash
	wall "Completing Install"
        sudo touch /home/ubuntu/still_installing
        if [[ -f /usr/local/bin/enableAutoUpdate ]]; then
          /usr/local/bin/enableAutoUpdate
        fi
        mkdir /data
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
          sudo mount $vol /data
          dev_path=$(readlink -f $vol)
          uuid=$(lsblk -no uuid $dev_path)
          echo "UUID=${uuid} /data ext4 defaults 0 1 " | sudo tee --append  /etc/fstab
        fi
        wall "Installing Software"




        wget https://repo.anaconda.com/archive/Anaconda3-2022.10-Linux-x86_64.sh -O ~/anaconda.sh
        bash ~/anaconda.sh -b -p $HOME/anaconda
        eval "$(/home/ubuntu/anaconda/bin/conda shell.bash hook)"
        conda init
        #conda config --set auto_activate_base false

        echo y | conda create --name notebooks python=3.8
        conda activate notebooks




        mkdir /data/notebooks
        #apt-get -qq update
        # apt-get -qq install -y software-properties-common python3.8 python3-pip

        echo y | conda install pip


        #pip3 install jupyterlab

        echo y | conda install jupyterlab

        # pip3 install markupsafe==2.0.1

        repo="https://github.com/cybera/adsl-cohort-workshops.git"
        cd /home/ubuntu
        wall "Installing requirements.txt from your repo"
        git clone ${repo} && cd "$(basename "${repo}" .git)"
        pip3 install -q -r ./python_dashboarding/docker/jupyterlab/requirements.txt
        cd ..
        wall "Setting up JupyterLab"
        #hashed=$(sudo python3 -c "from notebook.auth import passwd; import random; import string; output = ''.join(random.choice(string.ascii_letters) for i in range(24)); f = open(\"jupyterpass.txt\", \"a\"); f.write(str(output + \"\n\")); f.close(); print(passwd(str(output)))")
        hashed=$(date +%s | sha256sum | base64 | head -c 24)
        sudo rm -f /etc/systemd/system/jupyter.service 
        sudo tee -a /etc/systemd/system/jupyter.service <<EOF
        [Unit]


        Description=Jupyter Notebook

        [Service]
        Type=simple
        PIDFile=/run/jupyter.pid
        ExecStart=/usr/local/bin/jupyter-lab --ip='*' --notebook-dir=/data/notebooks --allow-root --no-browser --NotebookApp.password=${hashed}
        User=root
        Group=root
        Restart=always
        RestartSec=10

        [Install]
        WantedBy=multi-user.target
EOF

        wall "Starting Services"
        sudo systemctl daemon-reload
        sudo systemctl enable jupyter
        sudo systemctl start jupyter
        mv /home/ubuntu/still_installing /home/ubuntu/install_complete
        ip4=$(hostname -I | cut -d' ' -f1)
        wall "Install Complete! You should now be able to go to http://${ip4}:8888/lab and use the password in jupyterpass.txt to log in"