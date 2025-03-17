import SwiftUI

struct CoinListView: View {
    @StateObject private var viewModel = CryptoViewModel()
    @State private var showingAddAlert = false
    @State private var newCryptoName = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.cryptocurrencies) {
                    CryptoItem(currency: $0)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        viewModel.removeCryptoCurrency(at: index)
                    }
                }
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .navigationTitle("CoinChart")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        ForEach(TimeRange.allCases, id: \.self) { timeRange in
                            Button(action: {
                                viewModel.selectedTimeRange = timeRange
                            }) {
                                HStack {
                                    Text(timeRange.displayName)
                                    if viewModel.selectedTimeRange == timeRange {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Text(viewModel.selectedTimeRange.displayName)
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                }
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

