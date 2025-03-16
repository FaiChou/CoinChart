import Foundation
import SwiftUI

enum TimeRange: String, CaseIterable, Codable {
    case day = "24_hours"
    case week = "7_days"
    case month = "30_days"
    case threeMonths = "90_days"
    case max = "max"
    
    var displayName: String {
        switch self {
        case .day: return "天"
        case .week: return "周"
        case .month: return "月"
        case .threeMonths: return "3月"
        case .max: return "MAX"
        }
    }
}

struct SavedCurrency: Codable {
    let name: String
}

class CryptoViewModel: ObservableObject {
    @Published var cryptocurrencies: [CryptoCurrency] = []
    @Published var selectedTimeRange: TimeRange = .day
    
    private let userDefaultsKey = "savedCurrencyNames"
    private let timeRangeKey = "selectedTimeRange"
    
    init() {
        loadSelectedTimeRange()
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
    
    private func loadSelectedTimeRange() {
        if let data = UserDefaults.standard.data(forKey: timeRangeKey),
           let savedTimeRange = try? JSONDecoder().decode(TimeRange.self, from: data) {
            selectedTimeRange = savedTimeRange
        }
    }
    
    func saveSelectedTimeRange() {
        if let encoded = try? JSONEncoder().encode(selectedTimeRange) {
            UserDefaults.standard.set(encoded, forKey: timeRangeKey)
        }
    }
    
    func changeTimeRange(to timeRange: TimeRange) {
        selectedTimeRange = timeRange
        saveSelectedTimeRange()
        Task {
            await refreshData()
        }
    }
    
    private func loadSavedCurrencies() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
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
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
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
        let urlString = "https://www.coingecko.com/price_charts/\(currency.name.lowercased())/usd/\(selectedTimeRange.rawValue).json"
        guard let url = URL(string: urlString) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let response = try? JSONDecoder().decode(CoinGeckoResponse.self, from: data) else {
                return
            }
            let prices = response.stats.map { $0[1] }
            cryptocurrencies[index].chartData = prices
            if let lastPrice = prices.last, let firstPrice = prices.first {
                cryptocurrencies[index].currentPrice = lastPrice
                let priceChange = ((lastPrice - firstPrice) / firstPrice) * 100
                cryptocurrencies[index].priceChange = Double(round(priceChange * 100) / 100)
            }
            cryptocurrencies[index].refreshing = false
        } catch {
            print("Error fetching data: \(error)")
            cryptocurrencies[index].refreshing = false
        }
    }
}
