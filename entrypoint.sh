#!/bin/bash
set -e

# Define as cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Inicializando container da Tidal API...${NC}"

# Porta padrão se não estiver definida
export PORT=${PORT:-38880}

# Configuração do tidal-dl
TIDAL_CONFIG="/root/.tidal-dl.json"
CONFIG_VALID=false

# Verifica se o arquivo de configuração existe
if [ -f "$TIDAL_CONFIG" ]; then
    # Verifica se o arquivo tem um token ou cookie válido
    if grep -q "accessToken\|sessionId" "$TIDAL_CONFIG"; then
        echo -e "${GREEN}✅ Configuração do tidal-dl encontrada e parece válida!${NC}"
        CONFIG_VALID=true
    else
        echo -e "${YELLOW}⚠️  Arquivo de configuração do tidal-dl encontrado, mas pode não ter tokens válidos.${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Arquivo de configuração do tidal-dl não encontrado.${NC}"
fi

# Se não houver configuração válida, cria configuração básica
if [ "$CONFIG_VALID" = false ]; then
    echo -e "${YELLOW}⚠️  Criando configuração básica do tidal-dl...${NC}"
    echo -e "${YELLOW}⚠️  Você precisa configurar o tidal-dl antes de usar a API.${NC}"
    echo -e "${YELLOW}⚠️  Execute 'docker exec -it [container_id] /entrypoint.sh setup' para configurar.${NC}"
    
    # Cria diretório de configuração
    mkdir -p $(dirname "$TIDAL_CONFIG")
    
    # Cria um arquivo de configuração básico
    cat > "$TIDAL_CONFIG" << EOL
{
    "albumFolderFormat": "{ArtistName}/{AlbumTitle}",
    "apiKeyIndex": 4,
    "audioQuality": "HiFi",
    "checkExist": true,
    "downloadDelay": false,
    "downloadPath": "/app/downloads",
    "includeEP": true,
    "includeSingle": true,
    "language": "EN",
    "lyricFile": false,
    "multiThreadDownload": true,
    "saveAlbumInfo": false,
    "saveCovers": true,
    "showProgress": true,
    "showTrackInfo": true,
    "trackFileFormat": "{TrackNumber} - {TrackTitle}",
    "usePlaylistFolder": true,
    "videoFileFormat": "{VideoNumber} - {VideoTitle}"
}
EOL
    echo -e "${GREEN}✅ Configuração básica criada.${NC}"
fi

# Verifica se os diretórios necessários existem
mkdir -p /app/downloads
chmod -R 777 /app/downloads

# Diferentes comandos baseados no primeiro argumento
case "$1" in
    start-api)
        echo -e "${GREEN}🌐 Iniciando FastAPI na porta ${PORT}...${NC}"
        if [ "$CONFIG_VALID" = false ]; then
            echo -e "${YELLOW}⚠️  AVISO: A API está iniciando, mas o tidal-dl pode não funcionar sem configuração adequada.${NC}"
            echo -e "${YELLOW}⚠️  Os downloads podem falhar até que você execute a configuração.${NC}"
        fi
        exec uvicorn main:app --host 0.0.0.0 --port $PORT
        ;;
    setup)
        echo -e "${GREEN}🔧 Iniciando configuração do tidal-dl...${NC}"
        echo -e "${YELLOW}Por favor, faça login em sua conta Tidal quando solicitado.${NC}"
        echo -e "${YELLOW}Após o login, o arquivo de configuração será salvo automaticamente.${NC}"
        echo -e "${YELLOW}Você pode copiar este arquivo para uso futuro com: ${NC}"
        echo -e "${YELLOW}docker cp [container_id]:/root/.tidal-dl.json ./.tidal-dl.json${NC}"
        exec tidal-dl
        ;;
    shell)
        echo -e "${GREEN}💻 Iniciando shell...${NC}"
        exec /bin/bash
        ;;
    test)
        echo -e "${GREEN}🧪 Testando configuração do tidal-dl...${NC}"
        echo -e "${YELLOW}Tentando autenticar e verificar a configuração...${NC}"
        # Tenta listar algo para verificar se a autenticação funciona
        tidal-dl -l 118670403 -s
        echo -e "${GREEN}✅ Configuração parece funcionar! Você pode iniciar a API agora.${NC}"
        ;;
    *)
        echo -e "${GREEN}🚀 Executando comando personalizado: $@${NC}"
        exec "$@"
        ;;
esac 