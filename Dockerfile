FROM docker:19.03.8

RUN apk add -v --update bash curl git

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["bash", "/entrypoint.sh"]