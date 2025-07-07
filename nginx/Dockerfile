# Imagem base oficial do Nginx
FROM nginx:latest

# Evitar interações durante a instalação de pacotes
ENV DEBIAN_FRONTEND=noninteractive

# Atualizar repositórios e instalar pacotes necessários
RUN apt-get update && apt-get install -y \
nginx \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

# Remove a configuração padrão
RUN rm /etc/nginx/conf.d/default.conf

# Copiar arquivos HTML e assets
COPY html/index.html html/styles.css /usr/share/nginx/html/
RUN mkdir -p /usr/share/nginx/images
COPY images/logo.png /usr/share/nginx/images/

# Garante permissões de leitura para os arquivos estáticos
RUN chmod -R 755 /usr/share/nginx/html
RUN chmod -R 755 /usr/share/nginx/images

# Copie a config customizada do nginx
COPY ./conf.d/nginx.conf /etc/nginx/conf.d/default.conf

# Copiar os certificados para a imagem, se desejar
COPY ./certs/ /etc/nginx/certs/


# Definir permissões seguras para os certificados
RUN find /etc/nginx/certs -type f \( -name "*.pem" -o -name "*.key" \) -exec chmod 600 {} \;

# Expor as portas 80 (HTTP), 443 (HTTPS) e 8000 (custom)
EXPOSE 80
EXPOSE 443
EXPOSE 8000

# Comando para iniciar o Nginx. Já é o padrão na imagem base, mas 
# se você quiser manter o Nginx rodando em primeiro plano, descomente a linha abaixo.
# CMD ["nginx", "-g", "daemon off;"]
