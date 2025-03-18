//
//  Constants.swift
//  CoinChart
//
//  Created by 周辉 on 2025/3/17.
//

import Foundation

let groupKey = "group.com.faichou.coinchart"
let savedCurrencyNamesKey = "savedCurrencyNamesV2"
let selectedTimeRangeKey = "selectedTimeRange"

func formatPrice(_ price: Double) -> String {
    if price >= 1 {
        return String(format: "%.2f", price)
    } else if price >= 0.0001 {
        return String(format: "%.6f", price)
    } else {
        return String(format: "%.8f", price)
    }
}

func formatPercentage(_ percentage: Double) -> String {
    return String(format: "%.2f", percentage)
}
