FROM debian:stable-slim

RUN apt-get update && apt-get install -y curl gnupg ca-certificates nginx \
    && curl -fsSL https://www.aptly.info/pubkey.txt | gpg --dearmor -o /etc/apt/trusted.gpg.d/aptly.gpg \
    && echo "deb http://repo.aptly.info/ squeeze main" > /etc/apt/sources.list.d/aptly.list \
    && apt-get update && apt-get install -y aptly \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080 8081

ENTRYPOINT [ "/entrypoint.sh" ]
