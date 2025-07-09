# Imagem base oficial do Python para ARMv7
FROM arm32v7/python:3.9-slim

WORKDIR /app

# Atualizar repositórios e instalar pacotes necessários
# Instala as dependências do sistema. O 'sudo' não é necessário.
RUN apt-get update && apt-get install -y \
    bash \
    procps \
    tmux \
    python3-pygame \
    libsdl2-dev \
    libsdl2-image-dev \
    libsdl2-mixer-dev \
    libsdl2-ttf-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/

# Copiar arquivos de requisitos
COPY requirements.txt .
# Instalar dependências do Python
RUN pip install --no-cache-dir -r requirements.txt

# Copiar o código da aplicação para o diretório de trabalho
# incluindo o script principal, config e o script de start
COPY . .

# Cria os diretórios necessários (como o script faria)
RUN mkdir -p /app/logs

# Expõe a porta 5000 DENTRO da rede Docker para o Nginx se conectar
EXPOSE 5000

# Inicia a aplicação com Gunicorn (servidor de produção)
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]

