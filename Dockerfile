FROM ruby:2.3.1

RUN apt update && apt install -y nodejs vim
COPY clean_etc_hosts.sh /usr/bin
EXPOSE 3000

ENV BUNDLE_PATH /gems

ENTRYPOINT [ "/bin/bash" ]