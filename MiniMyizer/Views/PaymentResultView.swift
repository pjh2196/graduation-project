import SwiftUI

struct PaymentResultView: View {
    let price: Int
    let cashToPay: Int
    let diff: Int
    let balanceAfter: Int

    var balanceBefore: Int {
        balanceAfter - diff
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 12)

                VStack(spacing: 10) {
                    Text("お店に支払う金額")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("¥\(cashToPay)")
                        .font(.system(size: 56, weight: .bold))
                        .monospacedDigit()
                        .foregroundColor(.primary)

                    Text("この金額をお店にお支払いください")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(26)
                .padding(.horizontal)

                VStack(spacing: 0) {
                    resultRow(title: "商品金額", value: "¥\(price)")
                    divider
                    resultRow(title: "端数残高", value: "¥\(balanceBefore) → ¥\(balanceAfter)")
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(22)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 10) {
                    Text("取引内容は履歴から確認できます")
                        .font(.headline)

                    Text("端数差額は端数残高の変化として表示しています。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(22)
                .padding(.horizontal)

                Spacer(minLength: 24)
            }
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .navigationTitle("支払い確認")
        .navigationBarTitleDisplayMode(.inline)
    }

    var divider: some View {
        Divider().opacity(0.2)
    }

    func resultRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .foregroundColor(.primary)
                .bold()
                .monospacedDigit()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}
