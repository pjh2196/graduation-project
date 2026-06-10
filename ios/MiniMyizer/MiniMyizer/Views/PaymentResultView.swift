import SwiftUI

struct PaymentResultView: View {
    let price: Int
    let cashToPay: Int
    let diff: Int
    let balanceAfter: Int

    var diffText: String {
        diff >= 0 ? "+¥\(diff)" : "-¥\(abs(diff))"
    }

    var diffColor: Color {
        diff < 0 ? .red : .green
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 12)

                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Image(systemName: "checkmark")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.green)
                    }

                    Text("決済完了")
                        .font(.title2)
                        .bold()

                    Text("お支払いが完了しました")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 0) {
                    resultRow(title: "支払い金額", value: "¥\(price)")
                    divider
                    resultRow(title: "実際支払い", value: "¥\(cashToPay)")
                    divider
                    resultDiffRow(title: "差額", value: diffText)
                    divider
                    resultRow(title: "利用後残高", value: "¥\(balanceAfter)")
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(22)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 10) {
                    Text("ご利用ありがとうございました")
                        .font(.headline)

                    Text("履歴タブから取引内容を確認できます。")
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
        .navigationTitle("結果")
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
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    func resultDiffRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .foregroundColor(diffColor)
                .bold()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}
