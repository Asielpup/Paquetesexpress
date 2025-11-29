from datetime import datetime

from typing import Optional

from fastapi import FastAPI, UploadFile, Form, File, HTTPException

from sqlalchemy import create_engine, Column, Integer, String, TIMESTAMP,text, Float

from sqlalchemy.ext.declarative import declarative_base

from sqlalchemy.orm import sessionmaker

from fastapi.staticfiles import StaticFiles

from fastapi.middleware.cors import CORSMiddleware

import shutil
import os

# Inicializa la aplicación FastAPI
app = FastAPI()

# Esto es necesario para que aplicaciones como Flutter Web puedan comunicarse con esta API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Se puede restringir a dominios específicos si se desea mayor seguridad
    allow_credentials=True,
    allow_methods=["*"],          # Permite todos los métodos HTTP (GET, POST, etc.)
    allow_headers=["*"],          # Permite todos los encabezados en las peticiones
)

os.makedirs("uploads", exist_ok=True) # Crea la carpeta 'uploads' si no existe

# Esto permite acceder a las imágenes subidas mediante URLs como '/uploads/foto.jpg'
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Define la cadena de conexión a la base de datos MySQL
DATABASE_URL = "mysql+mysqlconnector://root:root@127.0.0.1:3307/eva_u3"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()

#Cada instancia de esta clase representa una fila en la tabla
class Agente(Base):
    __tablename__ = "agentes"
    id = Column(Integer, primary_key=True, index=True)
    usuario = Column(String(50), nullable=False, unique=True)
    password = Column(String(50), nullable=False)

class Paquete(Base):
    __tablename__ = "paquetes"
    id = Column(Integer, primary_key=True, index=True)
    destinatario = Column(String(100))
    direccion = Column(String(255), nullable=False)
    agente_id = Column(Integer)

class Entrega(Base):
    __tablename__ = "entregas"
    id = Column(Integer, primary_key=True)
    paquete_id = Column(Integer)
    agente_id = Column(Integer)
    foto_url = Column(String(255))
    lat = Column(Float)
    lon = Column(Float)
    fecha = Column(TIMESTAMP, server_default=text("CURRENT_TIMESTAMP"))

# Crea las tablas si no existen
Base.metadata.create_all(bind=engine)

#Define el endpoint POST para el Login
@app.post("/login/")
def login(usuario: str = Form(...), password: str = Form(...)):
    db = SessionLocal()  # Crea una nueva sesión para interactuar con la base de datos
    try:
        user=db.query(Agente).filter(Agente.usuario==usuario).first()
        if not user or user.password != password:
            return {"status":"error","msg":"Credenciales incorrectas"}
        return {"status":"ok","agente_id":user.id}
    finally:
        db.close()  # Cierra la sesión de base de datos


# Endpoint GET para listar los paquetes
@app.get("/paquetes/{agente_id}")
def get_paquetes(agente_id: int):
    db = SessionLocal()
    try:
        paquetes = db.query(Paquete).filter(Paquete.agente_id == agente_id).all()
        return paquetes
    finally:
        db.close()  # Cierra la sesión de base de datos

#Define el endpoint POST para la entrega de paquetes
@app.post("/entregar/")
async def entregar(
    paquete_id: int = Form(...),
    agente_id: int = Form(...),
    lat: float = Form(...),
    lon: float = Form(...),
    file: UploadFile = File(...),
):
    db = SessionLocal()
    try:
        # Guardar la foto con nombre único para evitar sobrescribir
        nombre_unico = f"{paquete_id}_{agente_id}_{file.filename}"
        ruta = f"uploads/{nombre_unico}"
        with open(ruta, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        nueva_entrega = Entrega(
            paquete_id=paquete_id,
            agente_id=agente_id,
            foto_url=ruta,
            lat=lat,
            lon=lon
        )
        db.add(nueva_entrega)
        db.commit()

        return {
            "status": "ok",
            "msg": "Entrega registrada",
            "foto_url": ruta,
            "lat": lat,
            "lon": lon
        }
    finally:
        db.close()

# Crear agente 
@app.post("/crear_agente/")
def crear_agente(usuario: str = Form(...), password: str = Form(...)):
    db = SessionLocal()
    try:
        existente = db.query(Agente).filter(Agente.usuario == usuario).first()
        if existente:
            return {"status": "error", "msg": "Usuario ya existe"}

        nuevo = Agente(usuario=usuario, password=password)
        db.add(nuevo)
        db.commit()
        db.refresh(nuevo)

        return {"status": "ok", "msg": "Agente creado", "agente_id": nuevo.id}
    finally:
        db.close()

@app.post("/crear_paquete/")
def crear_paquete(destinatario: str = Form(...), direccion: str = Form(...), agente_id: int = Form(...)):
    db = SessionLocal()
    try:
        nuevo = Paquete(destinatario=destinatario, direccion=direccion, agente_id=agente_id)
        db.add(nuevo)
        db.commit()
        db.refresh(nuevo)
        return {"status": "ok", "paquete_id": nuevo.id}
    finally:
        db.close()



