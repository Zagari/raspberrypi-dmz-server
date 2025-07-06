# Guia para Criação de cartão SD com Ubuntu e Firewall IPTables, Imagem Docker com Nginx e Servidor Flask para Raspberry Pi 2

Este guia contém instruções detalhadas para criar uma imagem Docker com Ubuntu, firewall, Nginx e Servidor Web Flask, e prepará-la para execução em um Raspberry Pi 2 (arquitetura ARMv7).

## Visão Geral

O projeto consiste em:

1. Um Docker Compose que cria uma imagem baseada em Ubuntu para ARMv7
2. Scripts para construir a imagem Docker
3. Instruções para preparar o cartão SD do Raspberry Pi 2
4. Instruções para instalar o IPTables no Raspberry Pi 2
4. Instruções para instalar o Docker no Raspberry Pi 2
5. Instruções para executar e validar o container

## Arquivos Incluídos

```
raspberrypi-dmz-server/
├── docker-compose.yml              # O orquestrador principal
├── build-image.sh                  # Script para construir a imagem Docker
├── prepare-sd-card.sh              # Instruções para preparar o cartão SD do Raspberry Pi 2
├── setup-docker.sh                 # Instruções para instalar o Docker e executar o container
├── setup-iptables.sh               # Script para configurar o firewall Iptables no host do Raspberry Pi
├── validate-container.sh           # Instruções para validar o funcionamento do container
├── README.md                       # Este arquivo com instruções gerais
│
├── app/                            # Pasta da aplicação Flask
│   ├── Dockerfile                  # Dockerfile específico para o Flask
│   ├── app.py                      # Seu código Flask
│   └── requirements.txt            # Dependências do Python
│
└── nginx/                          # Pasta de configuração do Nginx
    ├── Dockerfile                  # Dockerfile específico para o Nginx
    ├── nginx.conf                  # Config do Nginx como Reverse Proxy
    └── certs/                      # Pasta organizada para os certificados
        ├── origin_cloudflare.crt.pem
        └── origin.key
```

## Passo a Passo

### 1. [Opcional[ Construir a Imagem Docker Manualmente

O projeto agora tem um docker compose que já orquestra a construção das imagens e containers, mas caso queira testar a construção de algum das imagens, edite apropriadamente os parametros de build-image.sh e o copie para dentro da pasta da aplicação que deseja. Depois, no seu computador ou no Raspberry Pi, execute:

```bash
./build-image.sh
```

Este script irá construir a imagem Docker. Se for executado no seu host, ele irá salvá-la como `<NOME>.tar` para ser copiada posteriormente para o Raspberry Pi 2.

### 2. Preparar o Cartão SD

Siga as instruções em:

```bash
./prepare-sd-card.sh
```

Este arquivo contém instruções detalhadas para baixar o Raspberry Pi OS e gravá-lo no cartão SD.

### 3. Configurar o IPTables no Raspberry Pi 2

Após inicializar o Raspberry Pi com o cartão SD preparado, copie o script para o seu Raspberry Pi 2 ou clone o repositório e execute:

```bash
./setup-iptables.sh
```

Este arquivo irá instalar o IPTables, configurar regras para permitir portas 22, 80, 443 e 8000, além de um servidor Minecraft opcionalmente, e levantar o firewall. 

### 4. Configurar o Docker no Raspberry Pi 2

Após inicializar o Raspberry Pi com o cartão SD preparado e o firewall ativo, siga as instruções em:

```bash
./setup-docker.sh
```

Este arquivo contém instruções para instalar o Docker, transferir a imagem e executar o container.

### 4. Validar o Funcionamento

Para verificar se tudo está funcionando corretamente, siga as instruções em:

```bash
./validate-container.sh
```

Este arquivo contém instruções para testar o firewall e resolver problemas comuns.

### 5. Imagem Docker do Nginx

## Pré-requisitos
*   Docker e Docker Compose instalados no Raspberry Pi.
*   Um firewall configurado no host (veja `setup-iptables.sh`).

A imagem Docker criada inclui nginx:latest para ARMv7, que pode ou não redirecionar o tráfego http para tráfego https, dependendo da configuração em nginx.conf.

## Configuração dos Certificados SSL

Se deseja usar HTTPS, irá requerer certificados SSL para funcionar. Os certificados **não** são incluídos no repositório por segurança.

1.  Crie a pasta `certs` dentro da pasta `nginx`:
    ```bash
    mkdir -p nginx/certs
    ```
2.  Copie seu certificado e sua chave privada para esta nova pasta. Eles devem ser renomeados para:
    *   `fullchain.pem` (seu certificado, incluindo certificados intermediários)
    *   `privkey.pem` (sua chave privada)

    A estrutura final deve ser:
    ```
    nginx/
    ├── certs/
    │   ├── fullchain.pem
    │   └── privkey.pem
    └── nginx.conf
    ...
    ```

### Iniciando os Serviços

Com os certificados no lugar, inicie todos os containers com o Docker Compose:

```bash
docker-compose up --build -d
```

Sua aplicação agora estará acessível via https://IP_DO_SEU_PI.



## Requisitos

- Raspberry Pi 2 (arquitetura ARMv7)
- Cartão SD (mínimo 8GB recomendado)
- Acesso à internet no Raspberry Pi
- Computador para preparar a imagem e o cartão SD

## Solução de Problemas

Consulte o arquivo `validate-container.sh` para instruções detalhadas sobre como resolver problemas comuns.

## Notas Adicionais

- A imagem base utilizada é `arm32v7/ubuntu:22.04`, que é mantida oficialmente pela Canonical
- O container é configurado para reiniciar automaticamente quando o Raspberry Pi é iniciado
