import SwiftUI
import FSCalendar

struct CalendarView: UIViewRepresentable {
    @Binding var sessionDates: [Date]
    @Binding var therapyType: TherapyType
    
    func makeUIView(context: Context) -> FSCalendar {
        let calendar = FSCalendar()
        calendar.delegate = context.coordinator
        calendar.dataSource = context.coordinator
        
        // Register cell identifier
        calendar.register(SessionCompleteCell.self, forCellReuseIdentifier: "cell")
        
        // Customize calendar appearance here:
        calendar.allowsMultipleSelection = false // Disable selecting multiple dates
        calendar.swipeToChooseGesture.isEnabled = false // Disable swipe to choose multiple dates
        calendar.appearance.caseOptions = [.headerUsesUpperCase, .weekdayUsesUpperCase] // Use uppercase for headers and weekdays
        
        // Change colors for better contrast
        calendar.appearance.headerTitleColor = .white
        calendar.appearance.titleDefaultColor = .white
        calendar.appearance.selectionColor = UIColor.red

        // Compact font sizes
        calendar.appearance.titleFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        calendar.appearance.headerTitleFont = UIFont.systemFont(ofSize: 15, weight: .semibold)
        calendar.appearance.weekdayFont = UIFont.systemFont(ofSize: 10, weight: .regular)

        // Reduce spacing for compact view
        calendar.weekdayHeight = 20
        calendar.headerHeight = 35

        // Set todayColor to clear
        calendar.appearance.todayColor = .clear
        calendar.appearance.weekdayTextColor = .white.withAlphaComponent(0.5)

        // Hide out-of-month dates
        calendar.placeholderType = .none

        calendar.backgroundColor = .clear

        
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
            let cell = (calendar.dequeueReusableCell(withIdentifier: "cell", for: date, at: position) as? SessionCompleteCell) ?? SessionCompleteCell()
            
            let sessionExistsOnDate = parent.sessionDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) })
            
            // Show the circle view if the session is complete
            cell.showCircle(sessionExistsOnDate)

            // Set the therapy type of the cell
            cell.therapyType = parent.therapyType
            
            return cell
        }
        
        func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
            // Disable date selection
            return false
        }
        
        func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
            // Do nothing as selection is disabled
        }
        
        func calendar(_ calendar: FSCalendar, didDeselect date: Date, at monthPosition: FSCalendarMonthPosition) {
            // Do nothing as selection is disabled
        }
        
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {
            // Set default background color
            return .clear
        }
        
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillSelectionColorFor date: Date) -> UIColor? {
            // Set default selection color
            return .clear
        }
    }
}
