FROM ubuntu:22.04

ENV APP_HOME=/app
ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir -p $APP_HOME

# Install OS dependencies
RUN apt-get update -q && apt-get install -y \
  curl bundler build-essential git gnupg locales \
  libbz2-dev libffi-dev liblzma-dev lsb-release libsqlite3-dev libyaml-dev \
  make neovim ncurses-term pkg-config openjdk-17-jdk-headless tzdata zlib1g-dev \
  && ln -fs /usr/share/zoneinfo/UTC /etc/localtime \
  && dpkg-reconfigure --frontend noninteractive tzdata

# Add DB Repo Keys
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg \
  && echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list \
  && curl https://packages.microsoft.com/keys/microsoft.asc | tee /etc/apt/trusted.gpg.d/microsoft.asc \
  && curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | tee /etc/apt/sources.list.d/mssql-release.list \
  && apt-get update -q

# Install DB Clients
RUN ACCEPT_EULA=y DEBIAN_FRONTEND=noninteractive apt-get install -y \
  freetds-dev libmysqlclient-dev mysql-client msodbcsql18 mssql-tools18 unixodbc-dev libpq-dev \
  && echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && locale-gen en_US.UTF-8

WORKDIR $APP_HOME

# Install Ruby via Mise
ENV MISE_DATA_DIR="/mise"
ENV MISE_CONFIG_DIR="/mise"
ENV MISE_CACHE_DIR="/mise/cache"
ENV MISE_INSTALL_PATH="/usr/local/bin/mise"
ENV PATH="/mise/shims:$PATH"

RUN curl https://mise.run | sh
RUN mise install ruby

# Install atuin for better history
RUN curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
