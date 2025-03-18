//
//  CoinChartWidget.swift
//  CoinChartWidget
//
//  Created by 周辉 on 2025/3/17.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> CoinChartEntry {
        var btc = CryptoCurrency(name: "bitcoin")
        var eth = CryptoCurrency(name: "ethereum")
        var doge = CryptoCurrency(name: "dogecoin")
        btc.currentPrice = 55000
        btc.priceChange = 0.1
        btc.chartData = [50000, 51000, 52000, 53000, 54000, 55000]
        btc.refreshing = false
        eth.currentPrice = 1500
        eth.priceChange = -0.1
        eth.chartData = [2000, 1900, 1800, 1700, 1600, 1500]
        eth.refreshing = false
        doge.currentPrice = 1
        doge.priceChange = 0.2
        doge.chartData = [0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
        doge.refreshing = false
        return CoinChartEntry(date: Date(), coinData: [btc, eth, doge])
    }

    func getSnapshot(in context: Context, completion: @escaping (CoinChartEntry) -> ()) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            let currencies = await loadCoinData()
            let currentDate = Date()
            let entry = CoinChartEntry(date: currentDate, coinData: currencies)
            let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
            completion(timeline)
        }
    }
    func loadCoinData() async -> [CryptoCurrency] {
        var timeRange: TimeRange = .day
        if let value = UserDefaults(suiteName: groupKey)?.data(forKey: selectedTimeRangeKey),
           let savedRange = try? JSONDecoder().decode(TimeRange.self, from: value) {
            timeRange = savedRange
        }
        guard let data = UserDefaults(suiteName: groupKey)?.data(forKey: savedCurrencyNamesKey) else {
            print("No saved currency data found")
            return []
        }
        let savedCurrencies: [String]
        do {
            savedCurrencies = try JSONDecoder().decode([String].self, from: data)
        } catch {
            print("Failed to decode currencies: \(error)")
            return []
        }
        if savedCurrencies.isEmpty {
            return []
        }
        var currencies: [CryptoCurrency] = []
        await withTaskGroup(of: CryptoCurrency?.self) { group in
            for currency in savedCurrencies {
                group.addTask {
                    await fetchCryptoCurrencyData(for: currency, timeRange: timeRange)
                }
            }
            for await result in group {
                if let currency = result {
                    currencies.append(currency)
                }
            }
        }
        return currencies
    }
}

struct CoinChartEntry: TimelineEntry {
    let date: Date
    let coinData: [CryptoCurrency]
}

struct CoinChartWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    private var displayedCoinData: [CryptoCurrency] {
        switch widgetFamily {
        case .systemSmall, .systemMedium:
            return Array(entry.coinData.prefix(4))
        case .systemLarge:
            return Array(entry.coinData.prefix(10))
        default:
            return Array(entry.coinData.prefix(4))
        }
    }
    var body: some View {
        VStack {
            if entry.coinData.isEmpty {
                Text("请进入应用添加货币")
                    .font(.subheadline)
            }
            ForEach(displayedCoinData, id: \.id) {currency in
                HStack(spacing: 12) {
                    Text(currency.name)
                        .bold()
                        .font(widgetFamily != .systemSmall ? .subheadline : .caption)
                        .frame(width: widgetFamily != .systemSmall ? 90 : 60, alignment: .leading)
                    if widgetFamily != .systemSmall && !currency.chartData.isEmpty {
                        CoinChartView(
                            chartData: currency.chartData,
                            priceColor: currency.priceChange >= 0 ? .green : .red,
                            height: 30
                        )
                    }
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(formatPrice(currency.currentPrice))")
                            .bold()
                            .font(widgetFamily != .systemSmall ? .subheadline : .caption)
                        
                        Text("\(currency.priceChange >= 0 ? "+" : "")\(formatPercentage(currency.priceChange))%")
                            .foregroundColor(currency.priceChange >= 0 ? .green : .red)
                            .font(.caption2)
                    }
                    .frame(width: widgetFamily != .systemSmall ? 90 : 60, alignment: .trailing)
                }
                .frame(height: 30)
            }
        }
    }
}

struct CoinChartWidget: Widget {
    let kind: String = "CoinChartWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                CoinChartWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                CoinChartWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName(kind)
        .description("CoinChartWidget shows cryptocurrency prices and charts.")
    }
}
