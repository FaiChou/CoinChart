import SwiftUI
import Charts

struct CryptoCardView: View {
    let currency: CryptoCurrency
    let onDelete: () -> Void
    let isLoading: Bool
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
        CardContent(
            currency: currency,
            isLoading: isLoading,
            priceColor: priceColor,
            formatPrice: formatPrice,
            formatPercentage: formatPercentage,
            onDelete: onDelete,
            timeRange: timeRange
        )
    }
}


private struct CardContent: View {
    let currency: CryptoCurrency
    let isLoading: Bool
    let priceColor: Color
    let formatPrice: (Double) -> String
    let formatPercentage: (Double) -> String
    let onDelete: () -> Void
    let timeRange: TimeRange
    
    var body: some View {
        HStack(spacing: 12) {
            Text(currency.name)
                .font(.subheadline)
                .frame(width: 80, alignment: .leading)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if !currency.chartData.isEmpty {
                ChartView(chartData: currency.chartData, priceColor: priceColor)
            } else {
                Spacer()
            }
            
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
        .frame(height: 60)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

private struct ChartView: View {
    let chartData: [Double]
    let priceColor: Color
    
    var body: some View {
        let minPrice = chartData.min() ?? 0
        let maxPrice = chartData.max() ?? 0
        let priceRange = maxPrice - minPrice
        let midPrice = (minPrice + maxPrice) / 2
        let baseline = minPrice - priceRange * 0.05
        
        return Chart {
            let data = Array(chartData.enumerated())
            
            RuleMark(y: .value("Mid", midPrice))
                .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                .foregroundStyle(Color.gray.opacity(0.5))
            
            ForEach(data, id: \.offset) { index, price in
                AreaMark(
                    x: .value("Time", index),
                    yStart: .value("Baseline", baseline),
                    yEnd: .value("Price", price)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [priceColor.opacity(0.3), priceColor.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            
            ForEach(data, id: \.offset) { index, price in
                LineMark(
                    x: .value("Time", index),
                    y: .value("Price", price)
                )
                .foregroundStyle(priceColor)
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: baseline...maxPrice + priceRange * 0.1)
        .frame(height: 40)
        .frame(maxWidth: .infinity)
    }
} 
