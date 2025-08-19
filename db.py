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
        if isinstance(query, str):
            result = session.execute(text(query)).fetchall()
        else:
            result = session.execute(query).fetchall()
        session.close()
        return result
    except Exception as e:
        print(f"Error executing query: {e}")
        return None

# try:
    #     session = session_object()
    #     result = session.execute(text("SELECT sql_template from intents WHERE intent_name: intent_name"), {"intent_name": intent_name}).fetchall()
    #     session.close()
    #     return result
    # except Exception as e:
    #     print(f"Error executing query: {e}")
    #     return None
def get_sql_template():
    sql_template = """
           SELECT 
    gm.gl_account,
    gm.account_name,
    gm.branch,
    gm.account_category,
    gm.sub_category,
    gs.acct_currency,
    gs.ledger_balance,
    gs.last_transaction_date
FROM gl_account_master gm
JOIN gl_account_summary gs 
    ON gm.gl_acct_id = gs.gl_acct_id
WHERE (
        :account_no_list IS NULL
        OR EXISTS (
            SELECT 1
            FROM unnest(COALESCE(:account_no_list, ARRAY[]::text[])) AS acc(pattern)
            WHERE gm.gl_account LIKE acc.pattern
        )
      )
  AND (
        :branch_list IS NULL
        OR EXISTS (
            SELECT 1
            FROM unnest(COALESCE(:branch_list, ARRAY[]::text[])) AS br(pattern)
            WHERE gm.branch LIKE br.pattern
        )
      );"""
    return sql_template