from fastapi import FastAPI, HTTPException, BackgroundTasks, Query
from fastapi.responses import FileResponse
import subprocess
import os
import uuid
import shutil
from pathlib import Path
import zipfile
import threading
import time
import logging
import re

# Configuração de logs
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()
BASE_DIR = "downloads"  # Simplificando o caminho para evitar problemas
os.makedirs(BASE_DIR, exist_ok=True)

def delete_folder(path: str):
    if os.path.exists(path):
        try:
            shutil.rmtree(path)
            logger.info(f"Diretório removido: {path}")
        except Exception as e:
            logger.error(f"Erro ao remover diretório {path}: {e}")

def delete_file_after_delay(path: str, delay_seconds: int = 120):
    """Deleta um arquivo após um determinado tempo (padrão: 2 minutos)"""
    def delayed_delete():
        time.sleep(delay_seconds)
        if os.path.exists(path):
            try:
                os.remove(path)
                logger.info(f"Arquivo removido após delay: {path}")
            except Exception as e:
                logger.error(f"Erro ao remover arquivo {path}: {e}")
    
    # Inicia thread para deletar o arquivo após o delay
    thread = threading.Thread(target=delayed_delete)
    thread.daemon = True
    thread.start()

def extract_tidal_id(url_or_id: str) -> str:
    """Extrai o ID puro do Tidal de uma URL ou retorna o próprio ID se for apenas um número"""
    # Se for apenas números, é provavelmente um ID direto
    if url_or_id.isdigit():
        return url_or_id
    
    # Tenta extrair ID de um link completo
    # Exemplo: https://tidal.com/browse/track/118670403?u
    match = re.search(r'track/(\d+)', url_or_id)
    if match:
        return match.group(1)
    
    # Tenta extrair ID de outros formatos de link
    match = re.search(r'album/(\d+)', url_or_id)
    if match:
        return match.group(1)
    
    # Se não conseguiu extrair, retorna o valor original
    return url_or_id

@app.get("/")
async def root():
    return {"message": "Tidal Download API funcionando"}

@app.get("/download")
async def download_music(background_tasks: BackgroundTasks, url_or_id: str = Query(...)):
    # Extrai ID puro do Tidal
    tidal_id = extract_tidal_id(url_or_id)
    logger.info(f"URL/ID original: {url_or_id}")
    logger.info(f"ID extraído: {tidal_id}")
    
    # Cria diretório temporário único
    session_id = str(uuid.uuid4())[:8]
    session_dir = os.path.join(BASE_DIR, session_id)
    
    try:
        # Garante que o diretório existe com permissões corretas
        os.makedirs(session_dir, exist_ok=True)
        os.chmod(session_dir, 0o777)  # Permissões totais para garantir
        
        logger.info(f"Iniciando download de ID: {tidal_id}")
        logger.info(f"Diretório de destino: {session_dir}")
        
        # Comando tidal-dl
        cmd = [
            "tidal-dl",
            "-o", session_dir,
            "-l", tidal_id
        ]

        # Executa o comando e captura a saída
        process = subprocess.run(cmd, capture_output=True, text=True)
        
        # Loga a saída do processo para diagnóstico
        logger.info(f"Comando tidal-dl status: {process.returncode}")
        if process.stdout:
            logger.info(f"tidal-dl stdout: {process.stdout}")
        if process.stderr:
            logger.error(f"tidal-dl stderr: {process.stderr}")
            
        # Lista o conteúdo do diretório para diagnóstico
        logger.info(f"Conteúdo do diretório após download:")
        for root, dirs, files in os.walk(session_dir):
            logger.info(f"Dir: {root}")
            for d in dirs:
                logger.info(f"  Subdir: {d}")
            for f in files:
                logger.info(f"  Arquivo: {f}")

        # Busca arquivos válidos de áudio no diretório de forma mais abrangente
        audio_files = []
        for extension in ["*.flac", "*.mp3", "*.m4a", "*.wav", "*.aac"]:
            audio_files.extend(list(Path(session_dir).rglob(extension)))
            
        logger.info(f"Arquivos de áudio encontrados: {len(audio_files)}")
        
        if not audio_files:
            # Tenta manualmente verificar se há diretórios criados pelo tidal-dl
            # Às vezes o tidal-dl cria diretórios mas não baixa arquivos por problemas de autenticação
            if process.returncode == 0:
                logger.warning("tidal-dl reportou sucesso mas nenhum arquivo foi encontrado")
                # Verifica se o erro é de autenticação
                if "login needed" in process.stdout.lower() or "login needed" in process.stderr.lower():
                    raise HTTPException(
                        status_code=401,
                        detail="Autenticação necessária. Configure o tidal-dl primeiro."
                    )
                
            raise HTTPException(
                status_code=404, 
                detail=f"Arquivo não encontrado após o download. Status: {process.returncode}"
            )
        
        # Pega a pasta da música (o diretório pai do primeiro arquivo de áudio)
        music_folder = audio_files[0].parent
        logger.info(f"Pasta de música identificada: {music_folder}")
        
        # Cria um arquivo ZIP com todo o conteúdo da pasta da música
        zip_filename = f"tutu_download_{session_id}.zip"
        zip_path = os.path.join(BASE_DIR, zip_filename)
        
        with zipfile.ZipFile(zip_path, 'w') as zipf:
            file_count = 0
            for root, dirs, files in os.walk(music_folder):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, music_folder)
                    zipf.write(file_path, arcname)
                    file_count += 1
            
            logger.info(f"Arquivos adicionados ao ZIP: {file_count}")
        
        logger.info(f"Arquivo ZIP criado: {zip_path}")
        
        # Programa a exclusão da pasta após o download
        background_tasks.add_task(delete_folder, session_dir)
        
        # Configura o arquivo ZIP para expirar em 2 minutos
        delete_file_after_delay(zip_path)
        
        return FileResponse(
            path=zip_path,
            media_type="application/zip",
            filename=zip_filename
        )

    except subprocess.CalledProcessError as e:
        logger.error(f"Erro no processo tidal-dl: {e}")
        logger.error(f"stderr: {e.stderr}")
        logger.error(f"stdout: {e.stdout}")
        delete_folder(session_dir)
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao baixar: {e.stderr or e.stdout}"
        )
    except Exception as e:
        logger.error(f"Erro inesperado: {str(e)}", exc_info=True)
        delete_folder(session_dir)
        raise HTTPException(
            status_code=500,
            detail=f"Erro inesperado: {str(e)}"
        )
