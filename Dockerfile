FROM arm32v7/ubuntu:22.04

# Evitar interações durante a instalação de pacotes
ENV DEBIAN_FRONTEND=noninteractive

# Atualizar repositórios e instalar pacotes necessários
RUN apt-get update && apt-get install -y \
    iptables \
    curl \
    vim \
    bash \
    net-tools \
    iputils-ping \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copie suas regras de iptables se necessário
COPY ./iptables.rules /etc/iptables.rules

# Exemplo de comando para restaurar regras no start do container e mante-lo ativo
CMD ["sh", "-c", "iptables-restore < /etc/iptables.rules && tail -f /dev/null"]
