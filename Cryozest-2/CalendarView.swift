//import SwiftUI
//import JTAppleCalendar
//
//struct CalendarView: UIViewRepresentable {
//    var sessionDates: [Date]
//
//    func makeUIView(context: Context) -> JTACMonthView {
//        let calendar = JTACMonthView()
//        calendar.scrollDirection = .horizontal
//        calendar.scrollingMode = .stopAtEachCalendarFrame
//        calendar.showsHorizontalScrollIndicator = false
//        calendar.register(DateCell.self, forCellWithReuseIdentifier: "dateCell")
//        calendar.register(JTACMonthReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "headerView")
//        calendar.minimumLineSpacing = 0
//        calendar.minimumInteritemSpacing = 0
//        return calendar
//    }
//
//    func updateUIView(_ uiView: JTACMonthView, context: Context) {
//        uiView.calendarDataSource = context.coordinator
//        uiView.calendarDelegate = context.coordinator
//        uiView.reloadData()
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
//    class Coordinator: NSObject, JTACMonthViewDataSource, JTACMonthViewDelegate {
//
//
//        var parent: CalendarView
//
//        init(_ parent: CalendarView) {
//            self.parent = parent
//        }
//
//        func calendar(_ calendar: JTACMonthView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTACDayCell {
//            let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "dateCell", for: indexPath) as! DateCell
//            cell.dateLabel.text = cellState.text
//
//            if cellState.dateBelongsTo == .thisMonth {
//                cell.dateLabel.textColor = .black
//            } else {
//                cell.dateLabel.textColor = .lightGray
//            }
//
//            if parent.sessionDates.contains(date) {
//                cell.dateLabel.textColor = .white
//                cell.selectedView.isHidden = false
//                cell.selectedView.backgroundColor = .systemGreen
//            } else {
//                cell.selectedView.isHidden = true
//            }
//
//            return cell
//        }
//
//
//        func calendar(_ calendar: JTACMonthView, willDisplay cell: JTACDayCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
//            let cell = cell as! DateCell
//            cell.dateLabel.text = cellState.text
//            cell.eventDotView.isHidden = !parent.sessionDates.contains(date)
//
//            if cellState.dateBelongsTo == .thisMonth {
//                cell.dateLabel.textColor = .black
//            } else {
//                cell.dateLabel.textColor = .lightGray
//            }
//
//            if parent.sessionDates.contains(date) {
//                cell.dateLabel.textColor = .white
//                cell.selectedView.isHidden = false
//                cell.selectedView.backgroundColor = .systemGreen
//            } else {
//                cell.selectedView.isHidden = true
//            }
//        }
//
//        func configureCalendar(_ calendar: JTACMonthView) -> ConfigurationParameters {
//            let startDate = Date().addingTimeInterval(-60*60*24*365) // 1 year ago
//            let endDate = Date().addingTimeInterval(60*60*24*365) // 1 year in the future
//            return ConfigurationParameters(startDate: startDate, endDate: endDate)
//        }
//    }
//}


import SwiftUI
import FSCalendar

struct CalendarView: UIViewRepresentable {
    var sessionDates: [Date]

    func makeUIView(context: Context) -> FSCalendar {
        let calendar = FSCalendar()
        calendar.delegate = context.coordinator
        calendar.dataSource = context.coordinator

        // Customize calendar appearance here:
        calendar.allowsMultipleSelection = true // Allows selecting multiple dates
        calendar.swipeToChooseGesture.isEnabled = true // Swipe to choose multiple dates
        calendar.appearance.caseOptions = [.headerUsesUpperCase, .weekdayUsesSingleUpperCase] // Use uppercase for headers and weekdays
        
        // Register cell for customizing appearance if needed
        calendar.register(FSCalendarCell.self, forCellReuseIdentifier: "cell")

        return calendar
    }

    func updateUIView(_ uiView: FSCalendar, context: Context) {
        // Here we update the calendar with the selected dates
        uiView.reloadData()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, FSCalendarDelegate, FSCalendarDataSource {
        var parent: CalendarView

        init(_ parent: CalendarView) {
            self.parent = parent
        }

        func calendar(_ calendar: FSCalendar, cellFor date: Date, at position: FSCalendarMonthPosition) -> FSCalendarCell {
            let cell = calendar.dequeueReusableCell(withIdentifier: "cell", for: date, at: position)
            // Customize cell appearance here if needed
            return cell
        }

        func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
            // Return true if the date should be selectable, false otherwise
            return true
        }

        func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
            // Handle date selection here
        }

        func calendar(_ calendar: FSCalendar, didDeselect date: Date, at monthPosition: FSCalendarMonthPosition) {
            // Handle date deselection here
        }
    }
}

