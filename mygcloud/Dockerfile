FROM google/cloud-sdk

ARG TERRAFORM_VERSION=0.11.13
ENV TERRAFORM_VERSION=$TERRAFORM_VERSION

RUN apt-get -qqy update && apt-get install -qqy \
    unzip \
    socat \
    wget \
  && rm -rf /var/lib/apt/lists/*

RUN wget --quiet https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
  && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
  && mv terraform /usr/local/bin \
  && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
