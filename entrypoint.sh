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

# Configuração do tidal-dl se não existir
TIDAL_CONFIG="/root/.tidal-dl.json"
if [ ! -f "$TIDAL_CONFIG" ]; then
    echo -e "${YELLOW}⚠️  Arquivo de configuração do tidal-dl não encontrado!${NC}"
    echo -e "${YELLOW}⚠️  Você precisa configurar o tidal-dl antes de usar a API.${NC}"
    echo -e "${YELLOW}⚠️  Execute 'docker exec -it [container_id] /entrypoint.sh setup' para configurar.${NC}"
    
    # Cria um arquivo de configuração vazio para não bloquear a inicialização
    echo '{"albumFolderFormat": "{ArtistName}/{AlbumTitle}","apiKeyIndex": 4,"audioQuality": "HiFi","checkExist": true,"downloadDelay": true,"downloadPath": "/app/downloads","includeEP": true,"includeSingle": true,"language": "EN","lyricFile": false,"multiThreadDownload": true,"saveAlbumInfo": false,"saveCovers": true,"showProgress": true,"showTrackInfo": true,"trackFileFormat": "{TrackNumber} - {TrackTitle}","usePlaylistFolder": true,"videoFileFormat": "{VideoNumber} - {VideoTitle}"}' > "$TIDAL_CONFIG"
fi

# Verifica se os diretórios necessários existem
mkdir -p /app/downloads
chmod -R 777 /app/downloads

# Diferentes comandos baseados no primeiro argumento
case "$1" in
    start-api)
        echo -e "${GREEN}🌐 Iniciando FastAPI na porta ${PORT}...${NC}"
        exec uvicorn main:app --host 0.0.0.0 --port $PORT
        ;;
    setup)
        echo -e "${GREEN}🔧 Iniciando configuração do tidal-dl...${NC}"
        echo -e "${YELLOW}Por favor, faça login em sua conta Tidal${NC}"
        exec tidal-dl
        ;;
    shell)
        echo -e "${GREEN}💻 Iniciando shell...${NC}"
        exec /bin/bash
        ;;
    *)
        echo -e "${GREEN}🚀 Executando comando personalizado: $@${NC}"
        exec "$@"
        ;;
esac 