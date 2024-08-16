FROM ubuntu:22.04

ENV RBENV_ROOT=/opt/rbenv
ENV PATH=${RBENV_ROOT}/shims:${RBENV_ROOT}/bin:${PATH}
ENV APP_HOME=/app
# I know there's a more reliable way, but this is simpler.
ENV IN_DOCKER=true
ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir -p $APP_HOME

RUN apt-get update -q && apt-get install -y \
  curl bundler build-essential git gnupg locales \
  libbz2-dev libffi-dev liblzma-dev lsb-release libsqlite3-dev libyaml-dev \
  make openjdk-17-jdk-headless ruby-dev ruby-full tzdata zlib1g-dev \
  && ln -fs /usr/share/zoneinfo/UTC /etc/localtime \
  && dpkg-reconfigure --frontend noninteractive tzdata

RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg \
  && echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list \
  && curl https://packages.microsoft.com/keys/microsoft.asc | tee /etc/apt/trusted.gpg.d/microsoft.asc \
  && curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | tee /etc/apt/sources.list.d/mssql-release.list \
  && apt-get update -q

RUN ACCEPT_EULA=y DEBIAN_FRONTEND=noninteractive apt-get install -y \
  freetds-dev libmysqlclient-dev mysql-client msodbcsql18 mssql-tools18 unixodbc-dev libpq-dev \
  && echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && locale-gen en_US.UTF-8

RUN /bin/bash -c "source ~/.bashrc"

RUN mkdir -p ${RBENV_ROOT} \
  && git clone https://github.com/rbenv/rbenv.git ${RBENV_ROOT} \
  && git clone --depth 1 https://github.com/rbenv/ruby-build.git ${RBENV_ROOT}/plugins/ruby-build \
  && rbenv init - \
  && rbenv global system

WORKDIR $APP_HOME
COPY ./dev/rbenv ./dev/rbenv
COPY ./.github/workflows/ruby.yml ./.github/workflows/ruby.yml
RUN /usr/bin/gem install colorize psych toml-rb
RUN ./dev/rbenv install && rm ./dev/rbenv ./.github/workflows/ruby.yml
