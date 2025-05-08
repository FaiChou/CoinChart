import SwiftUI

struct CoinListView: View {
    @AppStorage(selectedTimeRangeKey, store: UserDefaults(suiteName: groupKey))
    var selectedTimeRange: TimeRange = .day

    @State private var currencyNames: [String] = []
    @State private var showingAddSheet = false
    @State private var newCryptoName = ""
    @State private var updater = 1

    @AppStorage("lastUpdateAt")
    var lastUpdateAt: Date = Date()

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(currencyNames, id: \.self) {
                        CryptoViewItem(name: $0, timeRange: selectedTimeRange, updater: updater)
                    }
                    .onDelete { indexSet in
                        for index in indexSet.sorted(by: >) {
                            currencyNames.remove(at: index)
                        }
                    }
                    .onMove { from, to in
                        currencyNames.move(fromOffsets: from, toOffset: to)
                    }
                }
                
                Text("最后更新：\(lastUpdateAt.formatted(.dateTime))")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.vertical, 3)
            }
            .onChange(of: currencyNames) {
                saveCurrencyNames()
            }
            .refreshable {
                updater += 1
                lastUpdateAt = Date()
            }
            .onForeground {
                lastUpdateAt = Date()
            }
            .onAppear {
                loadSavedCurrencies()
                lastUpdateAt = Date()
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
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddCoinView(currencyNames: $currencyNames)
            }
        }
    }
    private func loadSavedCurrencies() {
        if let data = UserDefaults(suiteName: groupKey)?.data(forKey: savedCurrencyNamesKey),
           let savedCurrencies = try? JSONDecoder().decode([String].self, from: data) {
            currencyNames = savedCurrencies
        }
    }
    private func saveCurrencyNames() {
        if let encoded = try? JSONEncoder().encode(currencyNames) {
            UserDefaults(suiteName: groupKey)?.set(encoded, forKey: savedCurrencyNamesKey)
        }
    }
}

extension View {
    func onBackground(_ f: @escaping () -> Void) -> some View {
        self.onReceive(
            NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification),
            perform: { _ in f() }
        )
    }
    
    func onForeground(_ f: @escaping () -> Void) -> some View {
        self.onReceive(
            NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification),
            perform: { _ in f() }
        )
    }
}
