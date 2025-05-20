# Use the official Ruby image as the base
FROM ruby:3.3.5-slim

# Set working directory inside the container
WORKDIR /app

# Install required dependencies
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  curl \
  && rm -rf /var/lib/apt/lists/*

# Set environment variables for production
ENV RAILS_ENV=production
ENV BUNDLE_DEPLOYMENT=1
ENV BUNDLE_WITHOUT="development test"

ARG SECRET_KEY_BASE
ENV SECRET_KEY_BASE=$SECRET_KEY_BASE

ARG ETSY_API_KEYSTRING
ENV ETSY_API_KEYSTRING=$ETSY_API_KEYSTRING

ARG ETSY_API_SECRET
ENV ETSY_API_SECRET=$ETSY_API_SECRET

# Copy Gemfiles and install dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs=4 --retry=3

# Copy application files
COPY . .

# Precompile assets and run database migrations
RUN bundle exec rails assets:precompile

# Ensure all databases are created
RUN bundle exec rails db:prepare
RUN bundle exec rails db:migrate

# Expose Railway's required port
EXPOSE 8080

# Start the Rails server on port 8080
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "8080"]