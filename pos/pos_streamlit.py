import streamlit as st
import cv2
import numpy as np
import requests
from datetime import datetime, timezone

API_BASE = "http://127.0.0.1:8001"

def decode_qr(image_bytes: bytes) -> str | None:
    arr = np.frombuffer(image_bytes, dtype=np.uint8)
    img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if img is None:
        return None
    detector = cv2.QRCodeDetector()
    data, _, _ = detector.detectAndDecode(img)
    return data if data else None

def iso_now_utc() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

st.set_page_config(page_title="POS Simulator", layout="centered")
st.title("POS シミュレータ (Streamlit + OpenCV)")

st.subheader("1) QR画像をアップロードして token を取得")
uploaded = st.file_uploader("QRコード画像(PNG/JPG)を選択", type=["png", "jpg", "jpeg"])

token = st.session_state.get("token", "")
if uploaded is not None:
    decoded = decode_qr(uploaded.getvalue())
    if decoded:
        st.session_state["token"] = decoded
        token = decoded
        st.success("QR decode 成功")
        st.code(token)
    else:
        st.error("QR decode 失敗（画像が小さい/ぼやけている可能性）")

st.subheader("2) 支払いデータ入力")
token_input = st.text_input("token", value=token, placeholder="QRから取得したtoken")
created_at = st.text_input("createdAt (ISO8601)", value=iso_now_utc())
price = st.number_input("price (int)", min_value=0, step=1, value=281)
store_id = st.text_input("store_id", value="storeA")

col1, col2 = st.columns(2)

with col1:
    if st.button("POST /payment", use_container_width=True):
        payload = {
            "token": token_input,
            "createdAt": created_at,
            "price": int(price),
            "store_id": store_id
        }
        try:
            r = requests.post(f"{API_BASE}/payment", json=payload, timeout=5)
            st.write("HTTP Status:", r.status_code)
            st.json(r.json())
        except Exception as e:
            st.error(str(e))

with col2:
    limit = st.number_input("history limit", min_value=1, step=1, value=10)
    if st.button("GET /history", use_container_width=True):
        try:
            r = requests.get(f"{API_BASE}/history", params={"limit": int(limit)}, timeout=5)
            st.write("HTTP Status:", r.status_code)
            st.json(r.json())
        except Exception as e:
            st.error(str(e))
