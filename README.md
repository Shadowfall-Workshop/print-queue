To get Bootstrap to work you have to activate dartsass by running `bin/rails dartsass:install`

ToDo:
☐ Restyle Queue Item forms with bootstrap_forms
☐ Add Etsy Connection
☐ Figure out when to update Etsy order status when multiple Items are in the queue


New Codespace code to run:
```
bundle install
sudo apt update
sudo apt upgrade -y
sudo apy install postgres
sudo service postgresql start
sudo su - postgres
ALTER USER postgres WITH PASSWORD 'postgres';
CREATE DATABASE print_queue_development OWNER postgres;
CREATE DATABASE print_queue_development_cable OWNER postgres;
CREATE DATABASE print_queue_development_queue OWNER postgres;
\q
exit
rails db:create
rails db:migrate
```

update config>environments>development to new host

Precompile assets for turborails and bootstrap:
`rails assets:precompile`

