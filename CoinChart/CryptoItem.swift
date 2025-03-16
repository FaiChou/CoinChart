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

struct CryptoItem: View {
    let currency: CryptoCurrency
    var timeRange: TimeRange = .day
    
    private func formatPrice(_ price: Double) -> String {
        if price >= 1 {
            return String(format: "%.2f", price)
        } else if price >= 0.0001 {
            return String(format: "%.6f", price)
        } else {
            return String(format: "%.8f", price)
        }
    }
    
    private func formatPercentage(_ percentage: Double) -> String {
        return String(format: "%.2f", percentage)
    }
    
    private var priceColor: Color {
        currency.priceChange >= 0 ? .green : .red
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(currency.name)
                .font(.subheadline)
                .frame(width: 80, alignment: .leading)
            
            if currency.refreshing {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if !currency.chartData.isEmpty {
                CoinChartView(chartData: currency.chartData, priceColor: priceColor)
            } else {
                Spacer()
            }
            if !currency.refreshing {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(formatPrice(currency.currentPrice))")
                        .font(.subheadline)
                        .bold()
                    
                    Text("\(currency.priceChange >= 0 ? "+" : "")\(formatPercentage(currency.priceChange))%")
                        .foregroundColor(priceColor)
                        .font(.caption)
                }
                .frame(width: 100, alignment: .trailing)
            }
        }
        .frame(height: 60)
    }
}
