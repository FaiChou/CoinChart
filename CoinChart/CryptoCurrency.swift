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
