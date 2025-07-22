
### Construção de Imagens Multi-Arquitetura com Docker Buildx

Este projeto foi configurado para rodar tanto em máquinas com arquitetura `amd64` (desktops, notebooks, a maioria dos servidores 
em nuvem) quanto em `arm64` (como o Raspberry Pi 4 ou superior). Para evitar a necessidade de construir a imagem Docker 
diretamente em cada dispositivo (o que pode ser lento, especialmente no Raspberry Pi), podemos usar o Docker Buildx para criar 
uma única imagem "multi-arch" e hospedá-la em um registro de contêineres como o Docker Hub.

Dessa forma, cada máquina baixará automaticamente a versão correta para sua arquitetura.

#### Pré-requisitos

1.  **Docker Desktop** instalado na sua máquina de desenvolvimento principal (ele já inclui o `buildx`).
2.  Uma conta em um **registro de contêineres**, como o [Docker Hub](https://hub.docker.com/).

#### Passos para a Construção e Publicação

**1. Nosso `Dockerfile` já está pronto**

O arquivo `minecraft_mng/Dockerfile` foi projetado para detectar a arquitetura de destino (`TARGETARCH`) e baixar a versão 
correta das dependências, como o Terraform. Nenhuma alteração é necessária.

**2. Faça login no seu Registro de Contêineres**

No seu terminal, autentique-se no Docker Hub (ou no seu registro de preferência):

```bash
docker login
```

**3. Garanta que o builder do Buildx está ativo**

Este comando cria e ativa uma nova instância do builder, caso ainda não exista.

```bash
docker buildx create --use --name mybuilder
```

**4. Execute o comando de build para múltiplas plataformas**

Navegue até a raiz do seu projeto (onde o `docker-compose.yml` está localizado) e execute o comando abaixo. Lembre-se de 
substituir `seu-usuario-docker` pelo seu nome de usuário real do Docker Hub.

```bash
# Substitua 'seu-usuario-docker' pelo seu usuário
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t seu-usuario-docker/minecraft_mng:latest \
  -t seu-usuario-docker/minecraft_mng:1.0 \
  ./minecraft_mng \
  --push
```

**O que este comando faz:**
*   `--platform linux/amd64,linux/arm64`: Instrui o Docker a construir a imagem para ambas as arquiteturas.
*   `-t seu-usuario-docker/minecraft_mng:latest`: Cria uma tag `latest` para a imagem. É o nome que você usará para baixá-la.
*   `-t seu-usuario-docker/minecraft_mng:1.0`: (Opcional, mas recomendado) Cria uma tag com um número de versão específico.
*   `./minecraft_mng`: Aponta para o diretório que contém o `Dockerfile` do serviço.
*   `--push`: **Essencial**. Este comando constrói e envia as imagens para o registro de uma só vez.

#### Como Usar a Imagem no Raspberry Pi (ou outra máquina)

Após publicar a imagem, você só precisa fazer uma pequena alteração no arquivo `docker-compose.yml` do seu dispositivo de destino.

**1. Edite `docker-compose.yml`:**

Altere a definição do serviço `minecraft_service` para usar a imagem do registro em vez de construí-la localmente.

**Antes:**
```yaml
services:
  minecraft_service:
    build: ./minecraft_mng
    # ... resto da configuração
```

**Depois:**
```yaml
services:
  minecraft_service:
    # Aponta para a imagem que você publicou no Docker Hub
    image: seu-usuario-docker/minecraft_mng:latest
    # A seção 'build' não é mais necessária
    # ... resto da configuração
```

**2. Inicie o serviço:**

Agora, no seu Raspberry Pi, basta executar:

```bash
docker-compose up -d
```

O Docker irá automaticamente detectar a arquitetura ARM, baixar a camada `linux/arm64` da sua imagem `minecraft_mng:latest` e 
iniciar o contêiner.

Uma vez construindo a imagem na sua máquina principal, e o deploy em qualquer plataforma se torna muito mais rápido e eficiente.

