import Foundation

struct CryptoCurrency: Identifiable, Codable {
    let id: String
    var name: String
    var refreshing: Bool
    var currentPrice: Double
    var priceChange: Double
    var chartData: [Double]
    
    init(name: String) {
        self.id = UUID().uuidString
        self.name = name
        self.currentPrice = 0
        self.priceChange = 0
        self.chartData = []
        self.refreshing = true
    }
}

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

private struct CoinGeckoResponse: Codable {
    let stats: [[Double]]
}

func fetchCryptoCurrencyData(for currencyName: String, timeRange: TimeRange) async -> CryptoCurrency? {
    let urlString = "https://www.coingecko.com/price_charts/\(currencyName.lowercased())/usd/\(timeRange.rawValue).json"
    guard let url = URL(string: urlString) else { return nil }
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let response = try? JSONDecoder().decode(CoinGeckoResponse.self, from: data) else {
            return nil
        }
        var currency = CryptoCurrency(name: currencyName)
        let prices = response.stats.map { $0[1] }
        currency.chartData = prices
        if let lastPrice = prices.last, let firstPrice = prices.first {
            currency.currentPrice = lastPrice
            let priceChange = ((lastPrice - firstPrice) / firstPrice) * 100
            currency.priceChange = Double(round(priceChange * 100) / 100)
        }
        currency.refreshing = false
        return currency
    } catch {
        print("Error fetching data: \(error)")
        return nil
    }
}
