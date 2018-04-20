###
# A docker image for testing and development.
##

FROM ubuntu:latest

RUN apt-get update
RUN apt-get install -y \
  jq \
  man \
  vim \
  curl \
  wget \
  unzip \
  direnv \
  supervisor
RUN rm -rf /var/lib/apt/lists/*

RUN curl \
  -o /usr/local/bin/bosh \
  https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-3.0.1-linux-amd64 \
  && chmod +x /usr/local/bin/bosh

RUN curl \
  -o /tmp/vault.zip \
  https://releases.hashicorp.com/vault/0.10.0/vault_0.10.0_linux_amd64.zip \
  && unzip -d /tmp/vault /tmp/vault.zip \
  && mv /tmp/vault/vault /usr/local/bin/vault \
  && chmod +x /usr/local/bin/vault

RUN curl \
  -o /tmp/consul.zip \
  https://releases.hashicorp.com/consul/1.0.6/consul_1.0.6_linux_amd64.zip?_ga=2.249791937.654537177.1523281978-259178166.1519829691 \
  && unzip -d /tmp/consul /tmp/consul.zip \
  && mv /tmp/consul/consul /usr/local/bin/consul \
  && chmod +x /usr/local/bin/consul

RUN wget \
  -O /tmp/credhub.tgz \
  https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/1.7.4/credhub-linux-1.7.4.tgz \
  && mkdir -p /tmp/credhub \
  && tar -xvf /tmp/credhub.tgz -C /tmp/credhub \
  && mv /tmp/credhub/credhub /usr/local/bin/credhub \
  && chmod +x /usr/local/bin/credhub

# Direnv integration
RUN echo 'eval "$( direnv hook bash )"' >> /root/.bashrc
RUN echo '[ -f .envrc ] && direnv allow || :' >> /root/.bashrc

# Configuration files
ADD .docker/vault.hcl /etc/vault/vault.hcl
ADD .docker/supervisord.conf /etc/supervisord.conf

# Add an entrypoint
ADD .docker/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
CMD /entrypoint.sh

# Create a directory for logfiles
RUN mkdir /var/log/supervisord

EXPOSE 8200
EXPOSE 8500

#
