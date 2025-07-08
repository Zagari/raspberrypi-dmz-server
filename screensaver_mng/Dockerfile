# Imagem base oficial do Python para ARMv7
FROM arm32v7/python:3.9-slim

WORKDIR /app

# Atualizar repositórios e instalar pacotes necessários
RUN apt-get update && apt-get install -y \
bash \
tmux \
procps \
sudo \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

# Copiar arquivos de requisitos
COPY requirements.txt .
# Instalar dependências do Python
RUN pip install --no-cache-dir -r requirements.txt

# Copiar o código da aplicação para o diretório de trabalho
COPY . .

# Define o diretório de trabalho para a instalação do screensaver
WORKDIR /app/screensaver_files

# Torna o script executável e o executa
# Tudo é feito em uma única instrução RUN para otimizar as camadas da imagem
RUN chmod +x installer.sh \
    && ./installer.sh

# Retorna ao diretório principal da aplicação
WORKDIR /app

# Expõe a porta 5000 DENTRO da rede Docker para o Nginx se conectar
EXPOSE 5000

# Inicia a aplicação com Gunicorn (servidor de produção)
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]

