FROM ruby:2.5-stretch

# Change to the application's directory
ENV APP_HOME /application
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/

RUN bundle install --without development test

ADD . $APP_HOME

EXPOSE 4567

ENTRYPOINT ["./entrypoint.sh"]
