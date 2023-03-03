FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y curl jq

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh


ENTRYPOINT ["entrypoint.sh"]
