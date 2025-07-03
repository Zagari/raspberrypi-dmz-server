FROM arm32v7/ubuntu:22.04

# Evitar interações durante a instalação de pacotes
ENV DEBIAN_FRONTEND=noninteractive

# Atualizar repositórios e instalar pacotes necessários
RUN apt-get update && apt-get install -y \
    iptables \
    nginx \
    curl \
    vim \
    bash \
    net-tools \
    iputils-ping \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copie suas regras de iptables se necessário
COPY ./iptables.rules /etc/iptables.rules
# Copie a config customizada do nginx
COPY ./nginx.conf /etc/nginx/nginx.conf

# Copiar os certificados da Cloudflare para a imagem
COPY origin_cloudflare.crt.pem /etc/ssl/cloudflare/origin_cloudflare.crt.pem
COPY origin.key /etc/ssl/cloudflare/origin.key

# Definir permissões seguras para os certificados
RUN chmod 600 /etc/ssl/cloudflare/origin_cloudflare.crt.pem && \
    chmod 600 /etc/ssl/cloudflare/origin.key

# Expor as portas 80 (HTTP), 8000 (custom) e 443 (HTTPS) e a porta do Minecraft
EXPOSE 80
EXPOSE 8000
EXPOSE 443
EXPOSE 25565

# Exemplo de comando para restaurar regras no start do container e mante-lo ativo
# CMD ["sh", "-c", "iptables-restore < /etc/iptables.rules && tail -f /dev/null"]
CMD ["sh", "-c", "iptables-restore < /etc/iptables.rules && nginx -g 'daemon off;'"]