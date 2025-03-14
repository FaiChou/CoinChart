import SwiftUI
import Charts

struct CryptoCardView: View {
    let currency: CryptoCurrency
    let onDelete: () -> Void
    let isLoading: Bool
    
    private func formatPrice(_ price: Double) -> String {
        if price >= 1 {
            return String(format: "%.2f", price)
        } else if price >= 0.0001 {
            return String(format: "%.6f", price)
        } else {
            return String(format: "%.8f", price)
        }
    }
    
    private var priceColor: Color {
        currency.priceChange24h >= 0 ? .red : .green
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(currency.name)
                .font(.headline)
            
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                    Text("正在获取数据...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 150)
            } else {
                HStack {
                    Text("$\(formatPrice(currency.currentPrice))")
                        .font(.title2)
                        .bold()
                    
                    Spacer()
                    
                    Text("\(currency.priceChange24h >= 0 ? "+" : "-")\(formatPrice(abs(currency.priceChange24h)))%")
                        .foregroundColor(priceColor)
                        .font(.subheadline)
                }
                
                if !currency.chartData.isEmpty {
                    let minPrice = currency.chartData.min() ?? 0
                    let maxPrice = currency.chartData.max() ?? 0
                    let priceRange = maxPrice - minPrice
                    
                    Chart {
                        let data = Array(currency.chartData.enumerated())
                        ForEach(data, id: \.offset) { index, price in
                            LineMark(
                                x: .value("Time", index),
                                y: .value("Price", price)
                            )
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [
                                        priceColor,
                                        priceColor.opacity(0.5)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .chartYScale(domain: max(0, minPrice - priceRange * 0.1)...maxPrice + priceRange * 0.1)
                    .frame(height: 100)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(.systemGray4).opacity(0.5), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
} 
