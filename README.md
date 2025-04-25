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

### 4. Configure o tidal-dl (OBRIGATÓRIO)
```bash
# Obtenha o ID do container
docker ps

# Configure o tidal-dl (substitua CONTAINER_ID pelo ID do seu container)
docker exec -it CONTAINER_ID /entrypoint.sh setup
```

Siga as instruções na tela para logar em sua conta Tidal.
Este passo é **OBRIGATÓRIO** para o funcionamento da API!

### 5. Teste a configuração do tidal-dl
```bash
docker exec -it CONTAINER_ID /entrypoint.sh test
```

### 6. Salve a configuração para futuros deploys
```bash
# Copie o arquivo de configuração para persistir entre containers
docker cp CONTAINER_ID:/root/.tidal-dl.json ./.tidal-dl.json
```

## 🔧 Uso da API

Endpoint para download:
```
GET /download?url_or_id=TIDAL_ID
```

Você pode usar:
- ID direto: `118670403`
- URL completa: `https://tidal.com/browse/track/118670403`
- URL de álbum: `https://tidal.com/browse/album/123456789`

Exemplo:
```
http://localhost:38880/download?url_or_id=118670403
```

## ⚠️ Problemas Comuns e Soluções

### 1. "Arquivo não encontrado após o download"
Isso geralmente ocorre quando o tidal-dl não está autenticado corretamente.
- **Solução**: Execute o passo 4 (configuração do tidal-dl)

### 2. A configuração não persiste após reiniciar o container
- **Solução**: Copie o arquivo de configuração para o host (passo 6) e monte-o como volume no docker-compose.yml
```yaml
volumes:
  - ./.tidal-dl.json:/root/.tidal-dl.json:ro
```

### 3. Problemas de autenticação no tidal-dl
- **Solução 1**: Tente fazer login novamente com `/entrypoint.sh setup`
- **Solução 2**: Tidal pode estar bloqueando requisições por IP ou região. Tente usar uma VPN.

## 📄 Logs e Monitoramento

Para ver os logs:
```bash
docker-compose logs -f
```

## 🛠️ Comandos Úteis

Acessar o shell do container:
```bash
docker exec -it CONTAINER_ID /entrypoint.sh shell
```

Reiniciar o serviço:
```bash
docker-compose restart
```

## 🚢 Deploy em Produção

Para deploy no Railway:
1. Conecte seu repositório no Railway
2. Configure o serviço para usar o Dockerfile
3. **Importante**: Após o deploy, conecte ao container via SSH para configurar o tidal-dl:
   ```bash
   railway connect
   /entrypoint.sh setup
   ```
4. Defina a variável de ambiente `PORT` se necessário

## 📊 Variáveis de Ambiente

- `PORT`: Porta em que a API irá rodar (padrão: 38880)
