import Foundation

struct CryptoCurrency: Identifiable, Codable {
    let id: String
    var name: String
    var currentPrice: Double
    var priceChange24h: Double
    var chartData: [Double]
    
    init(name: String) {
        self.id = UUID().uuidString
        self.name = name
        self.currentPrice = 0
        self.priceChange24h = 0
        self.chartData = []
    }
}

struct CoinGeckoResponse: Codable {
    let stats: [[Double]]
} 