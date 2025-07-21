
# Castellabate Infra - Terraform AWS EC2 Spot + VPC

Este projeto provisiona uma infraestrutura completa na AWS usando Terraform. Ele cria uma VPC do zero, com uma instância EC2 Spot (ARM64) que executa múltiplos containers Docker como NGINX, Flask e Minecraft Forge.

---

## ✅ Recursos Criados

- VPC personalizada `10.0.0.0/16`
- Subnet pública `10.0.1.0/24`
- Internet Gateway + Tabela de rotas públicas
- Instância EC2 Spot `t4g.large` (ARM64, 2vCPU, 8GB RAM)
- Comportamento Spot:
  - Tipo: `persistent`
  - Interrupção: `stop`
- Ubuntu Server 22.04 LTS ARM64 (`ami-050499786ebf55a6a`)
- Volume EBS de 40 GB (gp3)
- IP Público (não estamos usando IP fixo do Elastic IP)
- Security Group com portas liberadas: `22`(SSH), `80` (HTTP), `443` (HTTPS), `25565` (Minecraft)
- Script de inicialização para instalação do Docker
- Scripts para iniciar/parar a instância manualmente

---

## ⚙️ Pré-requisitos

- Conta AWS com credenciais configuradas (`aws configure`)
- Chave SSH criada e pública disponível em `~/.ssh/id_rsa.pub`
- [Terraform](https://developer.hashicorp.com/terraform/install) instalado (`>= 1.5`)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) instalado
- Se precisar, suba seus secrets no Parameter Store (via AWS Console ou CLI):
```bash

aws ssm put-parameter --name "cloudflare_api_token" --value "SEU_TOKEN" --type "SecureString"
aws ssm put-parameter --name "cloudflare_zone_id" --value "..." --type "SecureString"
aws ssm put-parameter --name "cloudflare_record_id" --value "..." --type "SecureString"
aws ssm put-parameter --name "cloudflare_record_name" --value "..." --type "SecureString"

```
---

## 📁 Estrutura

```
.
├── main.tf              # EC2, Security Group, EIP, Instance + IAM Profile
├── vpc.tf               # VPC, Subnet, Internet Gateway, Route Table
├── iam.tf               # IAM Role e políticas para acesso ao SSM
├── outputs.tf           # IP público, ID da instância
├── user_data.sh         # Script inicial da EC2 para instalar Docker e rodar containers
├── stop.sh              # Script para parar a instância manualmente
├── start.sh             # Script para iniciar a instância manualmente
```
  
---

## 🚀 Como usar

### 1. Clone o repositório e entre no diretório

```bash
git clone <repo>
cd <repo>
```

### 2. Inicializar o Terraform

```bash
terraform init
```

### 3. Ajuste o arquivo `main.tf` se necessário

- Certifique-se de que `key_name` seja o mesmo nome da chave SSH já registrada no console AWS
- A chave pública deve estar no caminho `~/.ssh/id_rsa.pub`

### 4. Importe a chave já existente na AWS (se aplicável)

```bash
terraform import aws_key_pair.main castellabate-key
```

### 5. Aplicar a infraestrutura

```bash
terraform apply -auto-approve
```

Aceite a criação quando solicitado.

### 6. Obter IP público

```bash
terraform output
```

Use esse IP para apontar seu domínio no Cloudflare.

---

## 🧃 Controle manual da instância

### Parar a instância:

```bash
bash stop.sh
```

### Iniciar novamente:

```bash
bash start.sh
```

---

## 🧹 Destruir toda a infraestrutura

```bash
terraform destroy -auto-approve
```

Isso apaga a EC2, IP, VPC e todos os recursos associados.

---

### Construção de Imagens Multi-Arquitetura com Docker Buildx

Este projeto foi configurado para rodar tanto em máquinas com arquitetura `amd64` (desktops, notebooks, a maioria dos servidores em nuvem) quanto em `arm64` (como o Raspberry Pi 4 ou superior). Para evitar a necessidade de construir a imagem Docker diretamente em cada dispositivo (o que pode ser lento, especialmente no Raspberry Pi), podemos usar o Docker Buildx para criar uma única imagem "multi-arch" e hospedá-la em um registro de contêineres como o Docker Hub.

Dessa forma, cada máquina baixará automaticamente a versão correta para sua arquitetura.

#### Pré-requisitos

1.  **Docker Desktop** instalado na sua máquina de desenvolvimento principal (ele já inclui o `buildx`).
2.  Uma conta em um **registro de contêineres**, como o [Docker Hub](https://hub.docker.com/).

#### Passos para a Construção e Publicação

**1. Nosso `Dockerfile` já está pronto**

O arquivo `minecraft_mng/Dockerfile` foi projetado para detectar a arquitetura de destino (`TARGETARCH`) e baixar a versão correta das dependências, como o Terraform. Nenhuma alteração é necessária.

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

Navegue até a raiz do seu projeto (onde o `docker-compose.yml` está localizado) e execute o comando abaixo. Lembre-se de substituir `seu-usuario-docker` pelo seu nome de usuário real do Docker Hub.

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

O Docker irá automaticamente detectar a arquitetura ARM, baixar a camada `linux/arm64` da sua imagem `minecraft_mng:latest` e iniciar o contêiner.

Com este método, você só precisa construir a imagem uma vez na sua máquina principal, e o deploy em qualquer plataforma se torna muito mais rápido e eficiente.


## 📌 Próximos passos

- Adicionar Lambda Functions para agendar start/stop automático
- Automatizar deploy com CI/CD

---

## 🧑‍💻 Autor

Nicola Zagari – Projeto Castellabate.tech 🚀


## 💡 Observações

- A instância Spot será interrompida (mas **não destruída**) caso a AWS precise da capacidade.
- O volume EBS permanece intacto, então seus containers e dados persistem entre interrupções.
- Você pode controlar a ativação/desativação com scripts Terraform ou futuras automações com AWS Lambda.
- Se você já tem uma chave chamada `castellabate-key` na região `us-east-1`, edite o `main.tf` para **comentar** a criação da chave
```hcl
# resource "aws_key_pair" "main" {
#   key_name   = "castellabate-key"
#   public_key = file("~/.ssh/id_rsa.pub")
# }
```

E, em seguida, importe a chave manualmente para o Terraform com:

```bash
terraform import aws_key_pair.main castellabate-key
```

Assim, o Terraform reconhece e gerencia a chave existente sem tentar recriá-la.
