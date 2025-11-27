FROM alpine:3.22
RUN apk add --no-cache curl bash python3 vim
ENTRYPOINT ["crond", "-f", "-L", "/var/log/cron.log"]