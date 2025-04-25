# Tidal API

API para download de músicas do Tidal com FastAPI e tidal-dl.

## 📋 Pré-requisitos

- Docker e Docker Compose
- Conta no Tidal

## 🚀 Instalação e Uso

### 1. Clone o repositório
```bash
git clone <seu-repositorio>
cd <seu-repositorio>
```

### 2. Construa a imagem Docker
```bash
docker-compose build
```

### 3. Inicie o container
```bash
docker-compose up -d
```

### 4. Configure o tidal-dl (primeira vez)
```bash
# Obtenha o ID do container
docker ps

# Configure o tidal-dl (substitua CONTAINER_ID pelo ID do seu container)
docker exec -it CONTAINER_ID /entrypoint.sh setup
```

Siga as instruções na tela para logar em sua conta Tidal.

### 5. (Opcional) Salve a configuração
```bash
# Copie o arquivo de configuração para persistir entre containers
docker cp CONTAINER_ID:/root/.tidal-dl.json ./.tidal-dl.json
```

## 🔧 Uso da API

Endpoint para download:
```
GET /download?url_or_id=TIDAL_ID
```

Exemplo:
```
http://localhost:38880/download?url_or_id=118670403
```

## 📄 Logs e Monitoramento

Para ver os logs:
```bash
docker-compose logs -f
```

## 🛠️ Comandos Úteis

Reiniciar o serviço:
```bash
docker-compose restart
```

Acessar o shell do container:
```bash
docker exec -it CONTAINER_ID /entrypoint.sh shell
```

## 🚢 Deploy em Produção

Para deploy no Railway:
1. Conecte seu repositório no Railway
2. Configure o serviço para usar o Dockerfile
3. Adicione o arquivo `.tidal-dl.json` no repositório (após configurar localmente)
4. Defina a variável de ambiente `PORT` se necessário

## 📊 Variáveis de Ambiente

- `PORT`: Porta em que a API irá rodar (padrão: 38880)
