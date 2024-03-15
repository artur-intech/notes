# syntax=docker/dockerfile:1
FROM ruby:3.3-alpine
RUN apk update && apk add --no-cache build-base libpq-dev postgresql-client

RUN adduser --disabled-password notes
USER notes

WORKDIR /home/notes

COPY --chown=notes Gemfile Gemfile.lock ./

ENV BUNDLE_DEPLOYMENT=true
RUN gem update bundler \
    && gem clean bundler \
    && bundle install

COPY --chown=notes . ./

EXPOSE 3000
CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "3000"]
