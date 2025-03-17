import Foundation
import SwiftUI

class CryptoViewModel: ObservableObject {
    @Published var cryptocurrencies: [CryptoCurrency] = []
    
    @AppStorage(selectedTimeRangeKey, store: UserDefaults(suiteName: groupKey))
    var selectedTimeRange: TimeRange = .day {
        didSet {
            Task {
                await refreshData()
            }
        }
    }
    init() {
        loadSavedCurrencies()
    }

    func addCryptoCurrency(_ name: String) {
        let newCrypto = CryptoCurrency(name: name)
        cryptocurrencies.append(newCrypto)
        Task {
            await fetchData(for: cryptocurrencies.last!)
        }
        saveCurrencyNames()
    }
    
    func removeCryptoCurrency(at index: Int) {
        cryptocurrencies.remove(at: index)
        saveCurrencyNames()
    }
    
    private func loadSavedCurrencies() {
        if let data = UserDefaults(suiteName: groupKey)?.data(forKey: savedCurrencyNamesKey),
           let savedCurrencies = try? JSONDecoder().decode([SavedCurrency].self, from: data) {
            cryptocurrencies = savedCurrencies.map { CryptoCurrency(name: $0.name) }
            Task {
                await refreshData()
            }
        }
    }
    
    private func saveCurrencyNames() {
        let savedCurrencies = cryptocurrencies.map { SavedCurrency(name: $0.name) }
        if let encoded = try? JSONEncoder().encode(savedCurrencies) {
            UserDefaults(suiteName: groupKey)?.set(encoded, forKey: savedCurrencyNamesKey)
        }
    }
    
    func refreshData() async {
        await withTaskGroup(of: Void.self) { group in
            for crypto in cryptocurrencies {
                group.addTask {
                    await self.fetchData(for: crypto)
                }
            }
            await group.waitForAll()
        }
    }
    
    @MainActor
    private func fetchData(for currency: CryptoCurrency) async {
        guard let index = cryptocurrencies.firstIndex(where: { $0.id == currency.id }) else {
            return
        }
        cryptocurrencies[index].refreshing = true
        if let currency = await fetchCryptoCurrencyData(for: currency.name, timeRange: selectedTimeRange) {
            cryptocurrencies[index].priceChange = currency.priceChange
            cryptocurrencies[index].currentPrice = currency.currentPrice
            cryptocurrencies[index].chartData = currency.chartData
        }
        cryptocurrencies[index].refreshing = false
    }
}
