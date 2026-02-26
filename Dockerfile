FROM ruby:3.3.10

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      git ca-certificates curl \
      build-essential \
      chromium chromium-driver \
      libssl-dev zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

ENV CHROME_BIN=/usr/bin/chromium

RUN gem install bundler
RUN mkdir -p /app
COPY . /app
RUN cd /app && bundle install
