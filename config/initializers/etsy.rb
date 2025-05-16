Rails.application.config.etsy = {
  client_id: ENV.fetch('ETSY_API_KEYSTRING'),
  client_secret: ENV.fetch('ETSY_API_SECRET')
}