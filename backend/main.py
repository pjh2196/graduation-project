from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List, Dict
from uuid import uuid4

app = FastAPI()

class PaymentRequest(BaseModel):
    token: str
    createdAt: str
    price: int
    store_id: Optional[str] = None

class PaymentRecord(BaseModel):
    id: str
    token: str
    createdAt: str
    price: int
    store_id: Optional[str] = None
    cash_to_pay: int
    diff: int
    balance_after: int
    received_at: str

payments: List[PaymentRecord] = []

# 토큰별 잔돈(잔액) 저장 (DB 없으니까 메모리)
balances: Dict[str, int] = {}

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/payment")
def payment(req: PaymentRequest):
    prev = balances.get(req.token, 0)

    remainder = req.price % 10

    if remainder == 0:
        cash_to_pay = req.price
        diff = 0
        balance_after = prev
    else:
        if prev >= remainder:
            cash_to_pay = req.price - remainder
            diff = -remainder
            balance_after = prev - remainder
        else:
            add = 10 - remainder
            cash_to_pay = req.price + add
            diff = add
            balance_after = prev + add

    balances[req.token] = balance_after

    record = PaymentRecord(
        id=str(uuid4()),
        token=req.token,
        createdAt=req.createdAt,
        price=req.price,
        store_id=req.store_id,
        cash_to_pay=cash_to_pay,
        diff=diff,
        balance_after=balance_after,
        received_at=datetime.utcnow().isoformat()
    )

    payments.append(record)
    return record

@app.get("/history")
def history(limit: int = 20):
    return payments[-limit:]
