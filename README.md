# Guia para Criação de Imagem Docker com Ubuntu e Firewall IPTables para Raspberry Pi 2

Este guia contém instruções detalhadas para criar uma imagem Docker com Ubuntu e firewall, e prepará-la para execução em um Raspberry Pi 2 (arquitetura ARMv7).

## Visão Geral

O projeto consiste em:

1. Um Dockerfile que cria uma imagem baseada em Ubuntu para ARMv7
2. Scripts para construir a imagem Docker
3. Instruções para preparar o cartão SD do Raspberry Pi 2
4. Instruções para instalar o Docker no Raspberry Pi 2
5. Instruções para executar e validar o container

## Arquivos Incluídos

- `Dockerfile`: Contém as instruções para criar a imagem Docker com Ubuntu e firewall
- `build-image.sh`: Script para construir a imagem Docker
- `prepare-sd-card.sh`: Instruções para preparar o cartão SD do Raspberry Pi 2
- `setup-docker.sh`: Instruções para instalar o Docker e executar o container
- `validate-container.sh`: Instruções para validar o funcionamento do container
- `README.md`: Este arquivo com instruções gerais

## Passo a Passo

### 1. Construir a Imagem Docker

No seu computador (não no Raspberry Pi), execute:

```bash
./build-image.sh
```

Este script irá construir a imagem Docker e salvá-la como `rpi-ubuntu-iptables.tar`.

### 2. Preparar o Cartão SD

Siga as instruções em:

```bash
./prepare-sd-card.sh
```

Este arquivo contém instruções detalhadas para baixar o Raspberry Pi OS e gravá-lo no cartão SD.

### 3. Configurar o Docker no Raspberry Pi 2

Após inicializar o Raspberry Pi com o cartão SD preparado, siga as instruções em:

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

## Detalhes da Imagem Docker

A imagem Docker criada inclui:

- Ubuntu 22.04 para ARMv7
- Iptables configurado para permitir portas 80, 443 e 22, além de um servidor Minecraft

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
