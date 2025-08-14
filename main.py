from fastapi import FastAPI, HTTPException
import mysql.connector
import os

app = FastAPI(title="MySQL Data API")

def get_db_connection():
    try:
        conn = mysql.connector.connect(
            host=os.getenv("MYSQL_HOST", "mysql"),
            port=int(os.getenv("MYSQL_PORT", 3306)),
            user=os.getenv("MYSQL_USER"),
            password=os.getenv("MYSQL_PASSWORD"),
            database=os.getenv("MYSQL_DATABASE")
        )
        return conn
    except mysql.connector.Error as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/data")
def read_data():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM data;")
    result = cursor.fetchall()
    cursor.close()
    conn.close()
    return result

@app.get("/health")
def health_check():
    return {"status": "ok"}

