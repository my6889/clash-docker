FROM alpine:3.22
RUN apk add --no-cache curl bash python3 vim
ENTRYPOINT ["/bin/bash", "-c", "/bin/bash /update_clash.sh ; crond -f -L /dev/stdout"]