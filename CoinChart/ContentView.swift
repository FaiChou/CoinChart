import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CryptoViewModel()
    @State private var showingAddAlert = false
    @State private var newCryptoName = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewModel.isInitialLoading {
                        ProgressView("加载中...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 40)
                    } else {
                        ForEach(Array(viewModel.cryptocurrencies.enumerated()), id: \.element.id) { index, currency in
                            CryptoCardView(
                                currency: currency,
                                onDelete: {
                                    viewModel.removeCryptoCurrency(at: index)
                                },
                                isLoading: viewModel.refreshingCurrencies.contains(currency.name)
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .navigationTitle("CoinChart")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddAlert = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("添加新货币", isPresented: $showingAddAlert) {
                TextField("输入加密货币名称", text: $newCryptoName)
                Button("取消", role: .cancel) {
                    newCryptoName = ""
                }
                Button("添加") {
                    if !newCryptoName.isEmpty {
                        viewModel.addCryptoCurrency(newCryptoName)
                        newCryptoName = ""
                    }
                }
            }
        }
    }
}
