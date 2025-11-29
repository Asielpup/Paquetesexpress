CREATE DATABASE IF NOT EXISTS eva_u3;
USE eva_u3;

CREATE TABLE agentes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(50) NOT NULL
);

CREATE TABLE paquetes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    destinatario VARCHAR(100),
    direccion VARCHAR(255) NOT NULL,
    agente_id INT
);

CREATE TABLE entregas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    paquete_id INT,
    agente_id INT,
    foto_url VARCHAR(255),
    lat FLOAT,
    lon FLOAT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
