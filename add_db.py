from pgvector.psycopg2 import register_vector
from pgvector import Vector
import psycopg2
import pandas as pd
import numpy as np
import json

db = pd.read_csv('newdb.csv')

db['embeddings'] = db['embeddings'].apply(json.loads)

# Conectar ao banco
conn = psycopg2.connect(
    dbname="postgres",
    user="usuario_do_banco", # substituir pelo usuário do banco
    password="senha_do_banco", # substituir pela senha do banco
    host="host_do_banco", # substituir pelo host do banco
    port="porta_do_banco" # substituir pela porta do banco
)

register_vector(conn) 

cur = conn.cursor()


cur.execute("""
            TRUNCATE TABLE dados_twitter;
            """)
i=0
# Inserir linha por linha
for index, row in db.iterrows():
    id = int(row['id'])
    tweet_text = row['tweet_text']
    tweet_date = pd.to_datetime(row['tweet_date']) 
    sentiment = row['sentiment']
    tokens = row['dicionario']
    embedding = row['embeddings']
   
    cur.execute("""
        INSERT INTO dados_twitter (id, tweet_text, tweet_date, sentimento, tokens, embeddings)
        VALUES (%s, %s, %s, %s, %s, %s)
        ON CONFLICT (id) DO NOTHING;
    """, (id, tweet_text, tweet_date, sentiment, tokens, Vector(embedding)))
    print(i)
    i += 1

conn.commit()
cur.close()
conn.close()
print("Dados inseridos com sucesso.")
