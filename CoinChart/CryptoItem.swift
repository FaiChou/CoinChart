import SwiftUI

struct CryptoItem: View {
    let currency: CryptoCurrency
    
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
                CoinChartView(chartData: currency.chartData, priceColor: priceColor, height: 40)
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
