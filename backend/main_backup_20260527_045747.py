from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from uuid import uuid4
from typing import Optional

from database import SessionLocal, engine, Base
from models import User, Wallet, QRToken, Payment
from schemas import IssueTokenRequest, PaymentRequest, PaymentResponse

app = FastAPI()

Base.metadata.create_all(bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/setup-user")
def setup_user(user_id: str, name: Optional[str] = None, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        user = User(id=user_id, name=name)
        db.add(user)
        db.commit()
        db.refresh(user)

    wallet = db.query(Wallet).filter(Wallet.user_id == user_id).first()
    if wallet is None:
        wallet = Wallet(user_id=user_id, balance=0)
        db.add(wallet)
        db.commit()
        db.refresh(wallet)

    return {"message": "user ready", "user_id": user_id}


@app.post("/issue-token")
def issue_token(req: IssueTokenRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == req.user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    wallet = db.query(Wallet).filter(Wallet.user_id == req.user_id).first()
    if wallet is None:
        wallet = Wallet(user_id=req.user_id, balance=0)
        db.add(wallet)
        db.commit()
        db.refresh(wallet)

    token = str(uuid4())
    now = datetime.utcnow()

    qr = QRToken(
        token=token,
        user_id=req.user_id,
        issued_at=now,
        expires_at=now + timedelta(seconds=300),
        is_used=False
    )
    db.add(qr)
    db.commit()
    db.refresh(qr)

    print("DEBUG issue token =", token)
    print("DEBUG issue issued_at =", qr.issued_at.isoformat() if qr.issued_at else None)
    print("DEBUG issue expires_at =", qr.expires_at.isoformat() if qr.expires_at else None)

    return {
        "qr_token": token,
        "expires_at": qr.expires_at.isoformat()
    }


@app.post("/payment", response_model=PaymentResponse)
def payment(req: PaymentRequest, db: Session = Depends(get_db)):
    qr = db.query(QRToken).filter(QRToken.token == req.qr_token).first()
    if qr is None:
        raise HTTPException(status_code=404, detail="QR token not found")

    now = datetime.utcnow()

    print("DEBUG payment token =", req.qr_token)
    print("DEBUG now =", now.isoformat())
    print("DEBUG qr issued_at =", qr.issued_at.isoformat() if qr.issued_at else None)
    print("DEBUG qr expires_at =", qr.expires_at.isoformat() if qr.expires_at else None)
    print("DEBUG qr is_used =", qr.is_used)

    if qr.is_used:
        raise HTTPException(status_code=400, detail="QR token already used")

    if qr.expires_at is None or qr.expires_at < now:
        raise HTTPException(status_code=400, detail="QR token expired")

    if qr.issued_at is None or (now - qr.issued_at).total_seconds() > 3000:
        raise HTTPException(status_code=400, detail="QR token expired")

    wallet = db.query(Wallet).filter(Wallet.user_id == qr.user_id).first()
    if wallet is None:
        raise HTTPException(status_code=404, detail="Wallet not found")

    balance_before = wallet.balance
    remainder = req.price % 10

    if remainder == 0:
        cash_to_pay = req.price
        diff = 0
        balance_after = balance_before
    else:
        if balance_before >= remainder:
            cash_to_pay = req.price - remainder
            diff = -remainder
            balance_after = balance_before - remainder
        else:
            add = 10 - remainder
            cash_to_pay = req.price + add
            diff = add
            balance_after = balance_before + add

    wallet.balance = balance_after
    qr.is_used = True

    payment_row = Payment(
        id=str(uuid4()),
        user_id=qr.user_id,
        qr_token=qr.token,
        price=req.price,
        cash_to_pay=cash_to_pay,
        diff=diff,
        balance_before=balance_before,
        balance_after=balance_after,
        store_id=req.store_id,
        received_at=now
    )

    db.add(payment_row)
    db.commit()
    db.refresh(payment_row)

    return PaymentResponse(
        cash_to_pay=cash_to_pay,
        diff=diff,
        balance_after=balance_after
    )


@app.get("/history/{user_id}")
def history(user_id: str, db: Session = Depends(get_db)):
    rows = (
        db.query(Payment)
        .filter(Payment.user_id == user_id)
        .order_by(Payment.received_at.desc())
        .all()
    )
    return rows
