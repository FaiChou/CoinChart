import SwiftUI

struct AddCoinView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var currencyNames: [String]
    @State private var newCryptoName = ""
    
    let popularCoins = [
        "bitcoin",
        "ethereum",
        "bnb",
        "xrp",
        "ripple",
        "cardano",
        "tron",
        "toncoin",
        "sui",
        "solana",
        "polkadot",
        "dogecoin",
        "avalanche-2",
        "chainlink",
        "official-trump"
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section("手动输入") {
                    TextField("输入加密货币名称", text: $newCryptoName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section("热门加密货币") {
                    ForEach(popularCoins, id: \.self) { coin in
                        Button(action: {
                            addCoin(coin)
                        }) {
                            HStack {
                                Text(coin)
                                Spacer()
                                if currencyNames.contains(coin) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("添加新货币")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        if !newCryptoName.isEmpty {
                            addCoin(newCryptoName.lowercased())
                        }
                    }
                    .disabled(newCryptoName.isEmpty)
                }
            }
        }
    }
    
    private func addCoin(_ coin: String) {
        if !currencyNames.contains(coin) {
            currencyNames.append(coin)
        }
        dismiss()
    }
} 