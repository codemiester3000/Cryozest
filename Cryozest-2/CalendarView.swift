import SwiftUI

struct CalendarView: View {
    @Binding var sessionDates: [Date]
    @Binding var therapyType: TherapyType

    @State private var currentMonth: Date = Date()

    private let columns = 7

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()

    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    // Get all days in current month
    private var daysInMonth: [Date] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }

        let days = calendar.generateDates(
            inside: monthInterval,
            matching: DateComponents(hour: 12)
        )

        return days
    }

    // Check if session exists on date
    private func hasSession(on date: Date) -> Bool {
        sessionDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) })
    }

    var body: some View {
        VStack(spacing: 16) {
            // Month navigation header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }

                Spacer()

                Text(monthYearFormatter.string(from: currentMonth))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal)

            // Heatmap calendar
            VStack(spacing: 12) {
                // Day labels
                HStack(spacing: 4) {
                    ForEach(0..<min(7, daysInMonth.count), id: \.self) { col in
                        Text(String(dayFormatter.string(from: daysInMonth[col]).prefix(1)))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                    }
                }

                // Calendar grid
                let monthRows = Int(ceil(Double(daysInMonth.count) / Double(columns)))
                VStack(spacing: 4) {
                    ForEach(0..<monthRows, id: \.self) { row in
                        HStack(spacing: 4) {
                            ForEach(0..<columns, id: \.self) { col in
                                let index = row * columns + col
                                if index < daysInMonth.count {
                                    let date = daysInMonth[index]
                                    let hasActivity = hasSession(on: date)
                                    let isToday = Calendar.current.isDateInToday(date)
                                    let dayNumber = Calendar.current.component(.day, from: date)

                                    ZStack {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(hasActivity ? therapyType.color : Color.white.opacity(0.1))
                                            .frame(height: 32)

                                        // Day number
                                        Text("\(dayNumber)")
                                            .font(.system(size: 9, weight: .semibold))
                                            .foregroundColor(hasActivity ? Color.white : Color.white.opacity(0.3))

                                        // Today indicator ring
                                        if isToday {
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.white, lineWidth: 2)
                                                .frame(height: 32)
                                        }
                                    }
                                } else {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.clear)
                                        .frame(height: 32)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)

            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(therapyType.color)
                        .frame(width: 12, height: 12)

                    Text("Completed")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }

                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 12, height: 12)

                    Text("No activity")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }

                HStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(therapyType.color)
                            .frame(width: 12, height: 12)

                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.white, lineWidth: 1.5)
                            .frame(width: 12, height: 12)
                    }

                    Text("Today")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
    }

    private func previousMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentMonth = newMonth
            }
        }
    }

    private func nextMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentMonth = newMonth
            }
        }
    }
}

// Calendar extension to generate dates
extension Calendar {
    func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)

        enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date < interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }

        return dates
    }
}
