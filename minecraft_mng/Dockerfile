# Use uma imagem base do Python
FROM python:3.9-slim

# Variáveis de ambiente para o build
ENV TERRAFORM_VERSION=1.5.7
ENV DEBIAN_FRONTEND=noninteractive

# Argumento de build para saber a arquitetura de destino
ARG TARGETARCH

# Instala dependências do sistema (git, ssh) e o Terraform/Ansible
RUN apt-get update && apt-get install -y \
    gnupg \
    software-properties-common \
    curl \
    git \
    openssh-client \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Instala a versão do Terraform para a arquitetura correta
RUN \
    # Mapeia a arquitetura do Docker para a nomenclatura do Terraform
    case ${TARGETARCH} in \
        "amd64") TF_ARCH="amd64" ;; \
        "arm64") TF_ARCH="arm64" ;; \
        "arm") TF_ARCH="arm" ;; \
        *) echo "Arquitetura não suportada: ${TARGETARCH}"; exit 1 ;; \
    esac \
    && curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TF_ARCH}.zip -o terraform.zip \
    && unzip terraform.zip -d /usr/local/bin \
    && rm terraform.zip

# Instala APENAS o motor do Ansible para manter a imagem leve
RUN pip install ansible-core --no-cache-dir

# Define o diretório de trabalho
WORKDIR /app

# Copia os arquivos de configuração do Terraform primeiro para o setup
COPY ./terraform /app/terraform

# Inicializa e importa a chave durante o build da imagem
# Isso prepara o arquivo de estado (tfstate) dentro da imagem.
# O comando init é necessário antes do import.
RUN cd /app/terraform && \
    terraform init && \
    terraform import aws_key_pair.main castellabate-key || echo "Falha ao importar a chave, talvez não exista. Continuando o build."

# Copia TODA a aplicação
COPY . .

# Instala a coleção Ansible DENTRO do diretório do projeto,
# no local que o ansible.cfg espera.
# A flag -p especifica o caminho (path) de instalação.
RUN ansible-galaxy collection install community.docker -p /app/collections

# Copia os arquivos de dependências e os instala
RUN pip install --no-cache-dir -r requirements.txt

# Expõe a porta que o Gunicorn vai rodar
EXPOSE 5001

# Comando para iniciar a aplicação
# Usamos apenas 1 worker para garantir que o estado em memória (o dicionário 'status') seja compartilhado.
# As threads ainda fornecem concorrência para que a UI não trave.
CMD ["gunicorn", "--bind", "0.0.0.0:5001", "--workers", "1", "--threads", "2", "app:app"]