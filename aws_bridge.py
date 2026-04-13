import psycopg
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Esto permite que tu App (Web o Móvil) conecte sin bloqueos de seguridad
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuración de tu base de datos RDS
db_params = {
    "host": "artist-cottage-main.cpe8kq4qkzyf.eu-north-1.rds.amazonaws.com",
    "dbname": "postgres",
    "user": "postgre",
    "password": "ArtistCottageMain0110!"
}

class UserData(BaseModel):
    email: str
    password: str
    username: str = None

@app.post("/register")
def register(user: UserData):
    try:
        with psycopg.connect(**db_params) as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO users (username, email, password) VALUES (%s, %s, %s)",
                    (user.username, user.email, user.password)
                )
                conn.commit()
        return {"status": "success"}
    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/login")
def login(user: UserData):
    try:
        with psycopg.connect(**db_params) as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT id FROM users WHERE email = %s AND password = %s",
                    (user.email, user.password)
                )
                result = cur.fetchone()
        if result:
            return {"status": "success"}
        raise HTTPException(status_code=401, detail="Invalid credentials")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
