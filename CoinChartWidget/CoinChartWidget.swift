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
        var sol = CryptoCurrency(name: "solana")
        var bnb = CryptoCurrency(name: "binance coin")
        var ada = CryptoCurrency(name: "cardano")
        var xrp = CryptoCurrency(name: "xrp")
        var dot = CryptoCurrency(name: "polkadot")
        btc.currentPrice = 55000
        btc.priceChange = 0.1
        btc.chartData = [50000, 51000, 52000, 53000, 54000, 55000]
        eth.currentPrice = 1500
        eth.priceChange = -0.1
        eth.chartData = [2000, 1900, 1800, 1700, 1600, 1500]
        doge.currentPrice = 1
        doge.priceChange = 0.2
        doge.chartData = [0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
        sol.currentPrice = 115
        sol.priceChange = 0.3
        sol.chartData = [90, 95, 100, 105, 110, 115]
        bnb.currentPrice = 240
        bnb.priceChange = -0.2
        bnb.chartData = [190, 200, 210, 220, 230, 240]
        ada.currentPrice = 3
        ada.priceChange = 0.1
        ada.chartData = [2.5, 2.6, 2.7, 2.8, 2.9, 3.0]
        xrp.currentPrice = 0.65
        xrp.priceChange = 0.4
        xrp.chartData = [0.4, 0.45, 0.5, 0.55, 0.6, 0.65]
        dot.currentPrice = 15
        dot.priceChange = 0.5
        dot.chartData = [10, 11, 12, 13, 14, 15]
        return CoinChartEntry(date: Date(), coinData: [btc, eth, doge, sol, bnb, ada, xrp, dot])
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
        if let value = UserDefaults(suiteName: groupKey)?.string(forKey: selectedTimeRangeKey),
           let savedRange = TimeRange(rawValue: value) {
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
        currencies.sort { (c1, c2) in
            guard let index1 = savedCurrencies.firstIndex(of: c1.name),
                  let index2 = savedCurrencies.firstIndex(of: c2.name) else {
                return false
            }
            return index1 < index2
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
                        .frame(width: widgetFamily != .systemSmall ? 70 : 60, alignment: .leading)
                    if widgetFamily != .systemSmall {
                        if !currency.chartData.isEmpty {
                            CoinChartView(
                                chartData: currency.chartData,
                                priceColor: currency.priceChange >= 0 ? .green : .red,
                                height: 30
                            )
                        } else {
                            Spacer()
                        }
                    }
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(formatPrice(currency.currentPrice))")
                            .bold()
                            .font(widgetFamily != .systemSmall ? .subheadline : .caption)
                        
                        Text("\(currency.priceChange >= 0 ? "+" : "")\(formatPercentage(currency.priceChange))%")
                            .foregroundColor(currency.priceChange >= 0 ? .green : .red)
                            .font(.caption2)
                    }
                    .frame(width: 60, alignment: .trailing)
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
