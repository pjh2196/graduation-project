import Foundation

struct PaymentRecord: Codable, Identifiable {
    let id: String
    let user_id: String
    let qr_token: String
    let price: Int
    let store_id: String
    let cash_to_pay: Int
    let diff: Int
    let balance_before: Int
    let balance_after: Int
    let received_at: String
}
