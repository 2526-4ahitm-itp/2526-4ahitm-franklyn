FROM nginx:stable

RUN apt-get update && apt-get install -y curl gnupg ca-certificates \
    && curl -fsSL https://www.aptly.info/pubkey.txt | gpg --dearmor -o /etc/apt/trusted.gpg.d/aptly.gpg \
    && echo "deb http://repo.aptly.info/ squeeze main" > /etc/apt/sources.list.d/aptly.list \
    && apt-get update && apt-get install -y aptly \
    && rm -rf /var/lib/apt/lists/*

COPY setup.sh /setup.sh

EXPOSE 80 8080

CMD nginx -g "daemon off;" & /setup.sh