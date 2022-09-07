FROM ubuntu
WORKDIR /app
RUN apt-get update && apt-get install -y apt-transport-https
RUN apt-get install sudo curl unzip gnupg2 -y
# Install yc
RUN curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash \
          -s -- -i /usr/local -n
# Install kubectl
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list && \
    sudo apt-get update && \
    sudo apt-get install -y kubectl
# Install terraform
RUN curl -L https://hashicorp-releases.yandexcloud.net/terraform/1.2.8/terraform_1.2.8_linux_amd64.zip --output terraform.zip
RUN unzip terraform.zip && rm -rf terraform.zip && chmod +x terraform && mv terraform /usr/local/bin
# install ansible
RUN apt-get update && \
  apt-get install -y git && \
  apt-get install -y python3 && \
  apt-get install python3-pip -y && \
  pip3 install --upgrade pip && \
  pip3 install ansible && \
  pip3 install jmespath
COPY scripts scripts
RUN chmod +x ./scripts/*
COPY terraform terraform
COPY .terraformrc /root/.terraformrc
COPY ansible ansible
RUN ansible-galaxy install -r ./ansible/requirements.yml
ENTRYPOINT [ "./scripts/entrypoint.sh" ]