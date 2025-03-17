import SwiftUI
import Charts

struct CoinChartView: View {
    let chartData: [Double]
    let priceColor: Color
    let height: CGFloat
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
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }
}
