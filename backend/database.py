from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

DATABASE_URL = "postgresql://postgres:postgres123@mydb.czumaoimmxa2.ap-southeast-2.rds.amazonaws.com:5432/mydb"

engine = create_engine(
    DATABASE_URL,
   )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()
