FROM postgres:11
ENV POSTGRES_USER batch_admin
ENV POSTGRES_PASSWORD batch_admin
ENV POSTGRES_DB batchdata
ENV PGDATA /usr/local/lib/postgresql/data/pgdata
COPY config /docker-entrypoint-initdb.d/
RUN apk upgrade --available \
    && mkdir -p /usr/local/data && chown -R 999:999 /usr/local/data
