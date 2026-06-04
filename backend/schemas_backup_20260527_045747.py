from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class IssueTokenRequest(BaseModel):
    user_id: str

class PaymentRequest(BaseModel):
    qr_token: str
    price: int
    store_id: Optional[str] = None

class PaymentResponse(BaseModel):
    cash_to_pay: int
    diff: int
    balance_after: int

class PaymentHistoryItem(BaseModel):
    id: str
    user_id: str
    qr_token: str
    price: int
    cash_to_pay: int
    diff: int
    balance_before: int
    balance_after: int
    store_id: Optional[str] = None
    received_at: datetime

    class Config:
        from_attributes = True