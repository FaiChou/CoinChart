import Foundation
import SwiftUI

// 添加时间范围枚举
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
    
    var next: TimeRange {
        switch self {
        case .day: return .week
        case .week: return .month
        case .month: return .threeMonths
        case .threeMonths: return .max
        case .max: return .day
        }
    }
}

struct SavedCurrency: Codable {
    let name: String
}

class CryptoViewModel: ObservableObject {
    @Published var cryptocurrencies: [CryptoCurrency] = []
    @Published var isInitialLoading = false
    @Published var refreshingCurrencies: Set<String> = []
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
        fetchData(for: name, index: cryptocurrencies.count - 1)
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
        Task { @MainActor in
            await refreshData()
        }
    }
    
    func cycleToNextTimeRange() {
        selectedTimeRange = selectedTimeRange.next
        saveSelectedTimeRange()
        Task { @MainActor in
            await refreshData()
        }
    }
    
    private func loadSavedCurrencies() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedCurrencies = try? JSONDecoder().decode([SavedCurrency].self, from: data) {
            // 先创建空的加密货币对象
            cryptocurrencies = savedCurrencies.map { CryptoCurrency(name: $0.name) }
            // 立即获取所有数据
            Task { @MainActor in
                isInitialLoading = true
                await refreshData()
                isInitialLoading = false
            }
        }
    }
    
    private func saveCurrencyNames() {
        let savedCurrencies = cryptocurrencies.map { SavedCurrency(name: $0.name) }
        if let encoded = try? JSONEncoder().encode(savedCurrencies) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    @MainActor
    func refreshData() async {
        // 标记所有货币为刷新状态
        refreshingCurrencies = Set(cryptocurrencies.map { $0.name })
        
        // 创建一个任务数组
        var tasks: [Task<Void, Never>] = []
        
        // 为每个加密货币创建一个异步任务
        for (index, currency) in cryptocurrencies.enumerated() {
            let task = Task {
                await fetchDataAsync(for: currency.name, index: index)
                refreshingCurrencies.remove(currency.name)
            }
            tasks.append(task)
        }
        
        // 等待所有任务完成
        for task in tasks {
            await task.value
        }
        
    }
    
    private func fetchDataAsync(for currency: String, index: Int) async {
        let urlString = "https://www.coingecko.com/price_charts/\(currency.lowercased())/usd/\(selectedTimeRange.rawValue).json"
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let response = try? JSONDecoder().decode(CoinGeckoResponse.self, from: data) else {
                return
            }
            
            await MainActor.run {
                guard index < cryptocurrencies.count else { return }
                
                let prices = response.stats.map { $0[1] }
                cryptocurrencies[index].chartData = prices
                
                if let lastPrice = prices.last, let firstPrice = prices.first {
                    cryptocurrencies[index].currentPrice = lastPrice
                    let priceChange = ((lastPrice - firstPrice) / firstPrice) * 100
                    cryptocurrencies[index].priceChange = Double(round(priceChange * 100) / 100)
                }
            }
        } catch {
            print("Error fetching data: \(error)")
        }
    }
    
    func fetchData(for currency: String, index: Int) {
        Task { @MainActor in
            refreshingCurrencies.insert(currency)
            await fetchDataAsync(for: currency, index: index)
            refreshingCurrencies.remove(currency)
        }
    }
} 
