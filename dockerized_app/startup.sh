# Remove any pre-existing PID files
rm -rf /app/app/tmp/pids/server.pid
rm -f /app/tmp/pids/server.pid

cd /app
bundle install --path=vendor/bundle
yarn install

# Configure bundle to use a local path for gems
bundle config path vendor/bundle

cd /app/app
bundle exec rake assets:precompile

# Start the Solr service for Sunspot
bundle exec rails sunspot:solr:start

# Start the Rails server, binding it to all network interfaces
bundle exec rails s -p 8080 -b '0.0.0.0'

