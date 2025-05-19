To get Bootstrap to work you have to activate dartsass by running `bin/rails dartsass:install`

ToDo:
☐ Restyle Queue Item forms with bootstrap_forms
☐ Add Etsy Connection
☐ Figure out when to update Etsy order status when multiple Items are in the queue


New Codespace code to run:
`sudo service postgresql start`
`bin/rails db:prepare`

If issue with connection, switch to postgres user and login:
`sudo -u postgres psql`

and update the password for the user:
`ALTER USER postgres WITH PASSWORD 'password';`