# heat-generator-service
Project to create Heat Generator Service web app


To Install:
clone project
```
git pull https://github.com/cybera/heat-generator-service master
```
Install Node then install dependancies
```
cd /project-path/
sudo npm install  
```
Then install laucher (pm2)
```
sudo npm install -g pm2 
pm2 start -n "Heat Generator Service" hgs.js
pm2 startup
```
Then run the command as instructed. Eg:
```
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ubuntu --hp /home/ubuntu
pm2 save
```

To Run manually if not running:
```
cd /project-path/
pm2 start -n "Heat Generator Service" hgs.js
```
To list process:
```
pm2 list
```
To restart manually a process (after update for example):
```
pm2 restart <id of process>
```