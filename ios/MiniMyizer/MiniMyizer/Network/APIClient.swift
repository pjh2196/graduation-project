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
        UserDefaults.standard.string(forKey: "api_base_url") ?? "http://127.0.0.1:8001"
    }
    
    private static func makeURL(path: String) -> URL? {
        let endpoint = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        return URL(string: endpoint + path)
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
