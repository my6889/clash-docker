FROM ubuntu:24.04
RUN apt-get update && apt-get install -y ca-certificates curl && rm -rf /var/lib/apt/lists/*
COPY clash /usr/local/bin/clash
RUN chmod +x /usr/local/bin/clash
COPY Country.mmdb /etc/clash/Country.mmdb
ENTRYPOINT ["/usr/local/bin/clash", "-d", "/etc/clash"]