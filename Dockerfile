FROM postgres:11.3
ENV POSTGRES_USER batch_admin
ENV POSTGRES_PASSWORD batch_admin
ENV POSTGRES_DB batchdata
ENV PGDATA /usr/local/lib/postgresql/data/pgdata
COPY config /docker-entrypoint-initdb.d/
