To get Bootstrap to work you have to activate dartsass by running `bin/rails dartsass:install`

ToDo:
-[X] Restyle Queue Item forms with bootstrap_forms
-[X] Add Etsy Connection
-[ ] Remove old entries from database
-[ ] Limit view to 100 items

A new codespace should install and create everything but if you need a blank codespace:
```
bundle install
sudo apt update
sudo apt upgrade -y
sudo apt install postgres
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

Create Test User and Queue_items with:
`rails db:seed`