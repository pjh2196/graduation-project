
# System Architecture

## Overview

This project consists of three main components:

- iOS App (Swift / SwiftUI)
- Backend API Server (FastAPI / Python)
- POS Simulator (Streamlit / Python)

---

## Architecture Diagram

iOS App  <--->  Backend API  <--->  PostgreSQL
POS Sim  <--->

Communication: JSON (REST API)

---

## Components

### iOS App
- QR code generation
- Send payment request
- Display balance & history

### Backend
- QR validation
- Rounding calculation
- Balance management
- Transaction history

### POS Simulator
- QR decode
- Send payment amount
- Receive payment result

---

## Database

- PostgreSQL
- Stores user balance and transaction history
