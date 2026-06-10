import Foundation

struct IssueTokenResponse: Decodable {
    let qr_token: String
    let expires_at: String
}

struct PaymentResult: Decodable {
    let cash_to_pay: Int
    let diff: Int
    let balance_after: Int
}

struct PendingPaymentResult: Decodable {
    let pending_id: String
    let user_id: String
    let price: Int
    let cash_to_pay: Int
    let diff: Int
    let balance_before: Int
    let balance_after: Int
    let store_id: String?
    let status: String
    let created_at: String
    let expires_at: String
    let is_cancelled: Bool?
}

struct CancelConfirmedPaymentResult: Decodable {
    let payment_id: String
    let user_id: String
    let price: Int
    let cash_to_refund: Int
    let restored_balance: Int
    let message: String
}



struct APIClient {
        
    enum APIError: LocalizedError {
        case invalidURL
        case noResponse
        case httpError(Int, String)
        case noData
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .noResponse:
                return "No response from server"
            case .httpError(let code, let message):
                return "HTTP \(code): \(message)"
            case .noData:
                return "No data"
            }
        }
    }
    
    private static var baseURL: String {
        let raw = UserDefaults.standard.string(forKey: "api_base_url") ?? "http://13.54.111.163"
        return raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
    }
    
    private static func makeURL(path: String) -> URL? {
        let endpoint = baseURL
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "") + path

        print("DEBUG API URL:", endpoint)

        return URL(string: endpoint)
    }
    
    static func issueToken(
        userId: String,
        completion: @escaping (Result<IssueTokenResponse, Error>) -> Void
    ) {
        guard let url = makeURL(path: "/issue-token") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["user_id": userId]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let http = response as? HTTPURLResponse else {
                completion(.failure(APIError.noResponse))
                return
            }
            
            let responseData = data ?? Data()
            
            guard (200...299).contains(http.statusCode) else {
                let msg = String(data: responseData, encoding: .utf8) ?? "Server error"
                completion(.failure(APIError.httpError(http.statusCode, msg)))
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(IssueTokenResponse.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    static func pay(
        qrToken: String,
        price: Int,
        storeId: String,
        completion: @escaping (Result<PaymentResult, Error>) -> Void
    ) {
        guard let url = makeURL(path: "/payment") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "qr_token": qrToken,
            "price": price,
            "store_id": storeId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let http = response as? HTTPURLResponse else {
                completion(.failure(APIError.noResponse))
                return
            }
            
            let responseData = data ?? Data()
            
            guard (200...299).contains(http.statusCode) else {
                let msg = String(data: responseData, encoding: .utf8) ?? "Server error"
                completion(.failure(APIError.httpError(http.statusCode, msg)))
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(PaymentResult.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    static func previewPayment(
        qrToken: String,
        price: Int,
        storeId: String,
        completion: @escaping (Result<PendingPaymentResult, Error>) -> Void
    ) {
        guard let url = makeURL(path: "/preview-payment") else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "qr_token": qrToken,
            "price": price,
            "store_id": storeId
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(APIError.noResponse))
                return
            }

            let responseData = data ?? Data()

            guard (200...299).contains(http.statusCode) else {
                let msg = String(data: responseData, encoding: .utf8) ?? "Server error"
                completion(.failure(APIError.httpError(http.statusCode, msg)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(PendingPaymentResult.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    static func fetchPendingPayment(
        userId: String,
        completion: @escaping (Result<PendingPaymentResult?, Error>) -> Void
    ) {
        guard let url = makeURL(path: "/pending-payment/\(userId)") else {
            completion(.failure(APIError.invalidURL))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(APIError.noResponse))
                return
            }

            let responseData = data ?? Data()

            guard (200...299).contains(http.statusCode) else {
                let msg = String(data: responseData, encoding: .utf8) ?? "Server error"
                completion(.failure(APIError.httpError(http.statusCode, msg)))
                return
            }

            if responseData.isEmpty || String(data: responseData, encoding: .utf8) == "null" {
                completion(.success(nil))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(PendingPaymentResult.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    static func fetchLatestPaymentStatus(
        userId: String,
        completion: @escaping (Result<PendingPaymentResult?, Error>) -> Void
    ) {
        guard let url = makeURL(path: "/latest-payment-status/\(userId)") else {
            completion(.failure(APIError.invalidURL))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(APIError.noResponse))
                return
            }

            let responseData = data ?? Data()

            guard (200...299).contains(http.statusCode) else {
                let msg = String(data: responseData, encoding: .utf8) ?? "Server error"
                completion(.failure(APIError.httpError(http.statusCode, msg)))
                return
            }

            if responseData.isEmpty || String(data: responseData, encoding: .utf8) == "null" {
                completion(.success(nil))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(PendingPaymentResult.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    static func confirmPayment(
        pendingId: String,
        completion: @escaping (Result<PaymentResult, Error>) -> Void
    ) {
        guard let url = makeURL(path: "/confirm-payment") else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "pending_id": pendingId
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(APIError.noResponse))
                return
            }

            let responseData = data ?? Data()

            guard (200...299).contains(http.statusCode) else {
                let msg = String(data: responseData, encoding: .utf8) ?? "Server error"
                completion(.failure(APIError.httpError(http.statusCode, msg)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(PaymentResult.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    static func cancelPayment(
        pendingId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = makeURL(path: "/cancel-payment") else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "pending_id": pendingId
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(APIError.noResponse))
                return
            }

            let responseData = data ?? Data()

            guard (200...299).contains(http.statusCode) else {
                let msg = String(data: responseData, encoding: .utf8) ?? "Server error"
                completion(.failure(APIError.httpError(http.statusCode, msg)))
                return
            }

            completion(.success(()))
        }.resume()
    }
    
    static func cancelConfirmedPayment(
        paymentId: String,
        completion: @escaping (Result<CancelConfirmedPaymentResult, Error>) -> Void
    ) {
        guard let url = makeURL(path: "/cancel-confirmed-payment") else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "payment_id": paymentId
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(APIError.noResponse))
                return
            }

            let responseData = data ?? Data()

            guard (200...299).contains(http.statusCode) else {
                let msg = String(data: responseData, encoding: .utf8) ?? "Server error"
                completion(.failure(APIError.httpError(http.statusCode, msg)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(CancelConfirmedPaymentResult.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    
    static func fetchHistory(
        userId: String,
        completion: @escaping (Result<[PaymentRecord], Error>) -> Void
    ) {
        guard let url = makeURL(path: "/history/\(userId)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let http = response as? HTTPURLResponse else {
                completion(.failure(APIError.noResponse))
                return
            }
            
            let responseData = data ?? Data()
            
            if let raw = String(data: responseData, encoding: .utf8) {
                print("===== HISTORY RAW JSON =====")
                print(raw)
                print("============================")
            }
            
            guard (200...299).contains(http.statusCode) else {
                let msg = String(data: responseData, encoding: .utf8) ?? "Server error"
                completion(.failure(APIError.httpError(http.statusCode, msg)))
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode([PaymentRecord].self, from: responseData)
                completion(.success(decoded))
            } catch {
                print("===== HISTORY DECODE ERROR =====")
                print(error)
                print("================================")
                completion(.failure(error))
            }
        }.resume()
    }
}
