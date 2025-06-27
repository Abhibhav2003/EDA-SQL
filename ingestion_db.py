import pandas as pd
import os
from sqlalchemy import create_engine
import time
import logging

# Ensure logs directory exists
os.makedirs("logs", exist_ok=True)

# Logging configuration
logging.basicConfig(
    filename="logs/ingestion_db.log",
    level=logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s",
    filemode="a"
)

# MySQL SQLAlchemy engine
engine = create_engine('mysql+pymysql://root:Bhavi%40123@localhost:3306/DataProfessionals')

def ingest_db(df, table_name, engine):
    '''This function ingests the dataframe into a database table'''
    try:
        df.to_sql(table_name, con=engine, if_exists='replace', index=False)
        logging.info(f"Successfully ingested table: {table_name}")
    except Exception as e:
        logging.error(f"Failed to ingest table '{table_name}': {e}")

def load_raw_data():
    '''This function loads CSVs as dataframes and ingests them into the DB'''
    start = time.time()
    logging.info("---------- Starting Data Ingestion ----------")
    try:
        for file in os.listdir('Dataset'):
            if file.endswith('.csv'):
                try:
                    df = pd.read_csv(os.path.join('Dataset', file))
                    logging.info(f"Read CSV: {file}")
                    table_name = file[:-4]
                    ingest_db(df, table_name, engine)
                except Exception as e:
                    logging.error(f"Failed to process file '{file}': {e}")
    except Exception as e:
        logging.critical(f"Critical failure in load_raw_data: {e}")
    
    end = time.time()
    total_time = (end - start) / 60
    logging.info("---------- Ingestion Complete ----------")
    logging.info(f"Total Time Taken: {total_time:.2f} minutes")

if __name__ == '__main__':
    load_raw_data()
