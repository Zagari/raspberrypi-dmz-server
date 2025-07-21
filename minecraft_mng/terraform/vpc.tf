# 1. Obter uma lista de todas as Zonas de Disponibilidade 'disponíveis' na região
data "aws_availability_zones" "available" {
  state = "available"
}

# 2. VPC 
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "castellabate-vpc"
  }
}

# 3. Criar UMA sub-rede em CADA Zona de Disponibilidade disponível
resource "aws_subnet" "public" {
  # O 'count' cria um loop. Teremos tantas sub-redes quanto o número de AZs disponíveis.
  count = length(data.aws_availability_zones.available.names)

  vpc_id                  = aws_vpc.main.id
  # A função cidrsubnet() calcula um bloco CIDR único para cada sub-rede.
  # Ex: 10.0.0.0/24, 10.0.1.0/24, 10.0.2.0/24, etc.
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  # 'count.index' pega o nome da AZ correspondente para cada iteração do loop
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "castellabate-subnet-public-${data.aws_availability_zones.available.names[count.index]}"
  }
}

# 4. Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  # ...
}

# 5. Tabela de Rotas 
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "castellabate-rt"
  }
}

# 6. Associar a tabela de rotas a TODAS as sub-redes que criamos
resource "aws_route_table_association" "a" {
  # O 'count' garante que vamos associar cada sub-rede criada no loop
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

