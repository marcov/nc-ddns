FROM alpine

# --no-cache: index is updated and used on-the-fly and not cached locally
RUN \
    apk add --no-cache \
        bash \
        bind-tools \
        curl;
