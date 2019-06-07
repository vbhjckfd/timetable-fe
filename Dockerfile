FROM ruby:2.5-stretch

RUN bundle config --global frozen 1

COPY Gemfile Gemfile.lock /application/

# Change to the application's directory
WORKDIR /application

RUN bundle install --deployment --without development test

COPY . /application/

ENTRYPOINT ["./entrypoint.sh"]
