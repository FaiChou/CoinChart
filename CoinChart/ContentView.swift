import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CryptoViewModel()
    @State private var showingAddAlert = false
    @State private var newCryptoName = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isInitialLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(Array(viewModel.cryptocurrencies.enumerated()), id: \.element.id) { index, currency in
                            CryptoCardView(
                                currency: currency,
                                onDelete: {
                                    viewModel.removeCryptoCurrency(at: index)
                                },
                                isLoading: viewModel.refreshingCurrencies.contains(currency.name),
                                timeRange: viewModel.selectedTimeRange
                            )
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            .listRowSeparator(.visible)
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
                }
            }
            .navigationTitle("CoinChart")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    TimeRangeButton(viewModel: viewModel)
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

struct TimeRangeButton: View {
    @ObservedObject var viewModel: CryptoViewModel
    
    var body: some View {
        Menu {
            ForEach(TimeRange.allCases, id: \.self) { timeRange in
                Button(action: {
                    viewModel.changeTimeRange(to: timeRange)
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
}