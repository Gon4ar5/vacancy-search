FROM ruby:3.4.11-slim

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl libpq-dev postgresql-client && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /rails

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production ./bin/rails assets:precompile

EXPOSE 3000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
