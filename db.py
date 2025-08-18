from sqlalchemy import create_engine,text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

import os

from dotenv import load_dotenv

load_dotenv()
db_url = os.getenv("DB_URL")
Base = declarative_base()

def connect_to_db():
    try:
        engine = create_engine(db_url)
        return engine
    except Exception as e:
        print(f"Error connecting to the database: {e}")
        return None

def session_object():
    try:
        connect = connect_to_db()
        Session = sessionmaker(bind=connect)
        session = Session()
        return session
    except Exception as e:
        print(f"Error creating session: {e}")
        return None
    
def execute_query(query):
    try:
        session = session_object()
        result = session.execute(text(query))
        session.close()
        return result
    except Exception as e:
        print(f"Error executing query: {e}")
        return None