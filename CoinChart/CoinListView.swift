import SwiftUI

struct CoinListView: View {
    @AppStorage(selectedTimeRangeKey, store: UserDefaults(suiteName: groupKey))
    var selectedTimeRange: TimeRange = .day

    @State private var currencyNames: [String] = []
    @State private var showingAddAlert = false
    @State private var newCryptoName = ""
    @State private var updater = 1

    var body: some View {
        NavigationStack {
            List {
                ForEach(currencyNames, id: \.self) {
                    CryptoViewItem(name: $0, timeRange: selectedTimeRange, updater: updater)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        currencyNames.remove(at: index)
                        saveCurrencyNames()
                    }
                }
            }
            .refreshable {
                updater += 1
            }
            .onAppear {
                loadSavedCurrencies()
            }
            .navigationTitle("CoinChart")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        ForEach(TimeRange.allCases, id: \.self) { timeRange in
                            Button {
                                selectedTimeRange = timeRange
                            } label: {
                                HStack {
                                    Text(timeRange.displayName)
                                    if selectedTimeRange == timeRange {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Text(selectedTimeRange.displayName)
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
                        currencyNames.append(newCryptoName)
                        saveCurrencyNames()
                        newCryptoName = ""
                    }
                }
            }
        }
    }
    private func loadSavedCurrencies() {
        if let data = UserDefaults(suiteName: groupKey)?.data(forKey: savedCurrencyNamesKey),
           let savedCurrencies = try? JSONDecoder().decode([SavedCurrency].self, from: data) {
            currencyNames = savedCurrencies.map { $0.name }
        }
    }
    
    private func saveCurrencyNames() {
        let savedCurrencies = currencyNames.map { SavedCurrency(name: $0) }
        if let encoded = try? JSONEncoder().encode(savedCurrencies) {
            UserDefaults(suiteName: groupKey)?.set(encoded, forKey: savedCurrencyNamesKey)
        }
    }
}

