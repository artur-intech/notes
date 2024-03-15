# syntax=docker/dockerfile:1
FROM ruby:3.3
RUN apt-get update -qq && apt-get install -y postgresql-client

WORKDIR /home/notes

COPY Gemfile Gemfile.lock ./
ENV BUNDLE_DEPLOYMENT=true
RUN gem update bundler \
    && gem clean bundler \
    && bundle install

COPY . ./

RUN useradd notes
USER notes

EXPOSE 3000
CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "3000"]
