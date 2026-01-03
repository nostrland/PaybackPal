import SwiftUI
import Foundation
import Charts

struct PaymentHistoryView: View {
    let payments: [Payment]
    let payoffEstimate: Date?
    let onDelete: (Payment) -> Void

    @State private var filter: Filter = .all

    var body: some View {
        Group {
            if filteredPayments.isEmpty {
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Text("Payment History")
                            .font(DesignSystem.Typography.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                            .padding(.top, DesignSystem.Spacing.lg)

                        filterControl
                            .padding(.horizontal, DesignSystem.Spacing.lg)

                        Text("No payments yet")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, DesignSystem.Spacing.lg)
                            .frame(maxWidth: .infinity)
                    }
                }
            } else {
                List {
                    // Summary header
                    Section {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(filter == .all ? "Total Paid" : "Total Paid (This Month)")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                            Text(CurrencyFormatter.shared.string(from: totalPaid))
                                .font(DesignSystem.Typography.body)
                                .fontWeight(.semibold)
                            if let payoffEstimate {
                                Text("Average payoff date from recent payments: \(formatPayoffDate(payoffEstimate))")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, DesignSystem.Spacing.sm)
                    }

                    Section {
                        Chart(monthlyTotalsForChart) { item in
                            BarMark(
                                x: .value("Month", item.label),
                                y: .value("Total", NSDecimalNumber(decimal: item.total).doubleValue)
                            )
                            .foregroundStyle(DesignSystem.Colors.primary)
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 140)
                    }
                    .headerProminence(.increased)

                    // Filter control
                    Section {
                        filterControl
                    }

                    // Grouped sections by month/year (based on filteredPayments)
                    ForEach(sortedSectionKeys, id: \.self) { key in
                        Section(header: Text(key)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary),
                                footer: monthlyFooter(for: key)) {
                            let items = sections[key] ?? []
                            ForEach(items) { payment in
                                PaymentRowView(payment: payment) {
                                    onDelete(payment)
                                }
                                .listRowInsets(EdgeInsets(top: DesignSystem.Spacing.sm,
                                                          leading: DesignSystem.Spacing.lg,
                                                          bottom: DesignSystem.Spacing.sm,
                                                          trailing: DesignSystem.Spacing.lg))
                                .listRowBackground(Color.clear)
                            }
                            .onDelete { indexSet in
                                let items = sections[key] ?? []
                                for index in indexSet {
                                    guard items.indices.contains(index) else { continue }
                                    onDelete(items[index])
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Payment History")
    }

    // MARK: - Filter

    private enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case thisMonth = "This Month"
        var id: String { rawValue }
    }

    private var filteredPayments: [Payment] {
        switch filter {
        case .all:
            return payments
        case .thisMonth:
            let cal = Calendar.current
            let now = Date()
            let comps = cal.dateComponents([.year, .month], from: now)
            guard let startOfMonth = cal.date(from: comps),
                  let startOfNextMonth = cal.date(byAdding: DateComponents(month: 1), to: startOfMonth) else {
                return payments
            }
            return payments.filter { $0.date >= startOfMonth && $0.date < startOfNextMonth }
        }
    }

    @ViewBuilder
    private var filterControl: some View {
        Picker("Filter", selection: $filter) {
            ForEach(Filter.allCases) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Summary

    private var totalPaid: Decimal {
        filteredPayments.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Grouping Helpers

    private var sections: [String: [Payment]] {
        let calendar = Calendar.current
        var dict: [String: [Payment]] = [:]
        for payment in filteredPayments {
            let comps = calendar.dateComponents([.year, .month], from: payment.date)
            let date = calendar.date(from: comps) ?? payment.date
            let key = monthYearFormatter.string(from: date)
            dict[key, default: []].append(payment)
        }
        // Sort each section by date descending
        for (k, v) in dict {
            dict[k] = v.sorted(by: { $0.date > $1.date })
        }
        return dict
    }

    private var sortedSectionKeys: [String] {
        let formatter = monthYearFormatter
        // Convert keys back to dates for sorting descending
        let pairs: [(String, Date)] = sections.keys.compactMap { key in
            if let date = formatter.date(from: key) { return (key, date) }
            return nil
        }
        return pairs.sorted { $0.1 > $1.1 }.map { $0.0 }
    }

    private var monthYearFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy" // e.g., January 2025
        f.locale = Locale.current
        return f
    }

    // MARK: - Chart Data

    private struct MonthlyTotal: Identifiable {
        let id = UUID()
        let date: Date
        let label: String
        let total: Decimal
    }

    private var monthlyTotalsForChart: [MonthlyTotal] {
        // Aggregate filteredPayments by month/year and produce up to the last 6 months sorted ascending for readable x-axis
        let cal = Calendar.current
        var totals: [Date: Decimal] = [:]
        for p in filteredPayments {
            let comps = cal.dateComponents([.year, .month], from: p.date)
            let monthStart = cal.date(from: comps) ?? p.date
            totals[monthStart, default: 0] += p.amount
        }
        let sorted = totals.keys.sorted(by: >)
        let lastSix = Array(sorted.prefix(6)).sorted() // ascending for chart order
        let df = monthShortFormatter
        return lastSix.map { d in
            MonthlyTotal(date: d, label: df.string(from: d), total: totals[d] ?? 0)
        }
    }

    private var monthShortFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "LLL" // Jan, Feb, ...
        f.locale = Locale.current
        return f
    }

    // MARK: - Footers

    private func monthlyFooter(for key: String) -> some View {
        let items = sections[key] ?? []
        let subtotal: Decimal = items.reduce(0) { $0 + $1.amount }
        return HStack {
            Text("Subtotal")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(CurrencyFormatter.shared.string(from: subtotal))
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, DesignSystem.Spacing.xs)
    }
    
    private func formatPayoffDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

