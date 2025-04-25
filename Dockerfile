# Usando uma imagem base com Python
FROM python:3.10-slim

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Copia os arquivos do projeto para o container
COPY . /app

# Instala dependências
RUN pip install --no-cache-dir fastapi>=0.104.0 uvicorn>=0.23.2 python-multipart>=0.0.6 \
    && pip install --no-cache-dir tidal-dl==2022.10.31.1

# Cria e configura o diretório de downloads com permissões corretas
RUN mkdir -p /app/downloads && chmod 777 /app/downloads

# Instala o ffmpeg (necessário para o tidal-dl processar arquivos de áudio)
RUN apt-get update && apt-get install -y ffmpeg && apt-get clean

# Configura o tidal-dl (criando arquivo de configuração padrão)
RUN echo '{"albumFolderFormat": "{ArtistName}/{AlbumTitle}","apiKeyIndex": 4,"audioQuality": "HiFi","checkExist": true,"downloadDelay": true,"downloadPath": "/app/downloads","includeEP": true,"includeSingle": true,"language": "EN","lyricFile": false,"multiThreadDownload": true,"saveAlbumInfo": false,"saveCovers": true,"showProgress": true,"showTrackInfo": true,"trackFileFormat": "{TrackNumber} - {TrackTitle}","usePlaylistFolder": true,"videoFileFormat": "{VideoNumber} - {VideoTitle}"}' > /root/.tidal-dl.json

# Expõe a porta usada pela aplicação FastAPI
EXPOSE 38880

# Comando para rodar o servidor
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "38880"]
