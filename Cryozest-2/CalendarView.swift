import SwiftUI
import FSCalendar

struct CalendarView: UIViewRepresentable {
    var sessionDates: [Date]
    
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
        calendar.appearance.weekdayTextColor = .white
        calendar.appearance.titleDefaultColor = .white
        //calendar.appearance.headerBackgroundColor = UIColor.darkGray
        calendar.appearance.selectionColor = UIColor.red
        // calendar.appearance.backgroundColor = UIColor.darkGray

        // Change font size for better readability
        calendar.appearance.titleFont = UIFont.boldSystemFont(ofSize: 18)
        calendar.appearance.weekdayFont = UIFont.boldSystemFont(ofSize: 16)
        calendar.appearance.headerTitleFont = UIFont.boldSystemFont(ofSize: 20)
        
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

            // Show the circle view if the session is complete
            cell.showCircle(parent.sessionDates.contains(date))

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
