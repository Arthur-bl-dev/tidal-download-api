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

app = FastAPI()
BASE_DIR = "downloads"
os.makedirs(BASE_DIR, exist_ok=True)

def delete_folder(path: str):
    if os.path.exists(path):
        shutil.rmtree(path)

def delete_file_after_delay(path: str, delay_seconds: int = 120):
    """Deleta um arquivo após um determinado tempo (padrão: 2 minutos)"""
    def delayed_delete():
        time.sleep(delay_seconds)
        if os.path.exists(path):
            os.remove(path)
    
    # Inicia thread para deletar o arquivo após o delay
    thread = threading.Thread(target=delayed_delete)
    thread.daemon = True
    thread.start()

@app.get("/download")
async def download_music(background_tasks: BackgroundTasks, url_or_id: str = Query(...)):
    # Cria diretório temporário único
    session_id = str(uuid.uuid4())[:8]
    session_dir = os.path.join(BASE_DIR, session_id)
    os.makedirs(session_dir, exist_ok=True)

    cmd = [
        "tidal-dl",
        "-o", session_dir,
        "-l", url_or_id
    ]

    try:
        subprocess.run(cmd, check=True, capture_output=True, text=True)

        # Busca arquivos válidos de áudio no diretório
        audio_files = list(Path(session_dir).rglob("*.flac")) + \
              list(Path(session_dir).rglob("*.mp3")) + \
              list(Path(session_dir).rglob("*.m4a"))
        if not audio_files:
            raise HTTPException(status_code=404, detail="Arquivo não encontrado após o download.")
        
        # Pega a pasta da música (o diretório pai do primeiro arquivo de áudio)
        music_folder = audio_files[0].parent
        
        # Cria um arquivo ZIP com todo o conteúdo da pasta da música
        zip_filename = f"tutu_download_{session_id}.zip"
        zip_path = os.path.join(BASE_DIR, zip_filename)
        
        with zipfile.ZipFile(zip_path, 'w') as zipf:
            for root, dirs, files in os.walk(music_folder):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, music_folder)
                    zipf.write(file_path, arcname)
        
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
        delete_folder(session_dir)
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao baixar: {e.stderr or e.stdout}"
        )
