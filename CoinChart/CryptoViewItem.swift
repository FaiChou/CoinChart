import SwiftUI

struct CryptoViewItem: View {
    let name: String
    let timeRange: TimeRange
    let updater: Int
    @State private var refreshing = true
    @State private var priceChange = 0.0
    @State private var currentPrice = 0.0
    @State private var chartData: [Double] = []
    @State private var errorMsg: String = ""
    private var priceColor: Color {
        priceChange >= 0 ? .green : .red
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(name)
                .font(.subheadline)
                .frame(width: 80, alignment: .leading)
            
            if refreshing {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if !chartData.isEmpty {
                CoinChartView(chartData: chartData, priceColor: priceColor, height: 40)
            } else if !errorMsg.isEmpty {
                Text(errorMsg)
                    .foregroundColor(.red)
            }
            if !refreshing {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(formatPrice(currentPrice))")
                        .font(.subheadline)
                        .bold()
                    
                    Text("\(priceChange >= 0 ? "+" : "")\(formatPercentage(priceChange))%")
                        .foregroundColor(priceColor)
                        .font(.caption)
                }
                .frame(width: 100, alignment: .trailing)
            }
        }
        .frame(height: 60)
        .onAppear {
            fetch()
        }
        .onChange(of: timeRange) { oldValue, newValue in
            fetch()
        }
        .onChange(of: updater) { oldValue, newValue in
            fetch()
        }
    }
    private func fetch() {
        refreshing = true
        Task {
            if let result = await fetchCryptoCurrencyData(for: name, timeRange: timeRange) {
                errorMsg = ""
                priceChange = result.priceChange
                currentPrice = result.currentPrice
                chartData = result.chartData
            } else {
                errorMsg = "请求错误"
            }
            refreshing = false
        }
    }
}
