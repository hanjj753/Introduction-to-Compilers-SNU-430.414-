# One toolchain for student development and instructor validation.
# This digest selects the official Ubuntu 26.04 multi-platform image.
FROM ubuntu:26.04@sha256:513c074113a871b51a8d16ab445c88779d6452d937a164fb5cc479f32668a41d

LABEL org.opencontainers.image.title="Introduction to Compilers development environment" \
      org.opencontainers.image.description="Ubuntu default toolchain for course projects 1–4"

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bash bc bison build-essential ca-certificates diffutils findutils \
        flex gdb git grep libfl-dev procps python3 sed unzip valgrind zip \
    && mkdir -p /usr/local/share/intcmp \
    && dpkg-query -W -f='${binary:Package}\t${Version}\n' \
        > /usr/local/share/intcmp/packages.tsv \
    && rm -rf /var/lib/apt/lists/*

# Preserve the base user's UID/GID and reuse it for the course account.
# Dev Containers maps this account to the host UID/GID on Linux.
RUN if id ubuntu >/dev/null 2>&1; then \
        usermod --login student --home /home/student --move-home --shell /bin/bash ubuntu \
        && groupmod --new-name student ubuntu; \
    else \
        groupadd --gid 1000 student \
        && useradd --uid 1000 --gid student --create-home --shell /bin/bash student; \
    fi

COPY --chmod=755 check.sh /usr/local/bin/intcmp-check

USER student
WORKDIR /home/student
CMD ["sleep", "infinity"]
