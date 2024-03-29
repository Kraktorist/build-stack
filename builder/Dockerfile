FROM alpine:3.16.2
WORKDIR /app
RUN apk update --no-cache && apk add --no-cache curl bash openssh-client
# Install yc
RUN curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash \
          -s -- -i /usr/local -n
# Install kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl
# Install terraform
RUN curl -L https://hashicorp-releases.yandexcloud.net/terraform/1.2.8/terraform_1.2.8_linux_amd64.zip --output terraform.zip
RUN unzip terraform.zip && rm -rf terraform.zip && chmod +x terraform && mv terraform /usr/local/bin
# install ansible
RUN apk add --no-cache git python3 py3-pip && \
    pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir ansible==5.10.0 && \
    pip3 install --no-cache-dir jmespath  && \
    pip3 install --no-cache-dir netaddr && \
    pip3 install kubernetes
# install helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    VERIFY_CHECKSUM=false ./get_helm.sh && rm -rf get_helm.sh
COPY scripts scripts
RUN chmod +x ./scripts/*
COPY helm helm
COPY ansible ansible
RUN ansible-galaxy install -r ./ansible/requirements.yml
# install kubespray
RUN curl -L https://github.com/kubernetes-sigs/kubespray/archive/refs/tags/v2.20.0.zip --output kubespray.zip && \
    unzip kubespray.zip && rm -rf kubespray.zip && mv kubespray-2.20.0 ./ansible/kubespray
COPY terraform terraform
COPY .terraformrc /root/.terraformrc
CMD /bin/bash --init-file "/app/scripts/entry.sh"