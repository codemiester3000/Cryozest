import SwiftUI
import FSCalendar

struct CalendarView: UIViewRepresentable {
    var sessionDates: [Date]
    
    func makeUIView(context: Context) -> FSCalendar {
        let calendar = FSCalendar()
        calendar.delegate = context.coordinator
        calendar.dataSource = context.coordinator
        
        // Register cell identifier
        calendar.register(FSCalendarCell.self, forCellReuseIdentifier: "cell")
        
        // Customize calendar appearance here:
        calendar.allowsMultipleSelection = true // Allows selecting multiple dates
        calendar.swipeToChooseGesture.isEnabled = true // Swipe to choose multiple dates
        calendar.appearance.caseOptions = [.headerUsesUpperCase, .weekdayUsesSingleUpperCase] // Use uppercase for headers and weekdays
        
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
            
            // Customize cell appearance here
            if parent.sessionDates.contains(date) {
                cell.backgroundColor = .orange
            } else {
                cell.backgroundColor = .clear
            }
            
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
        
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {
            if parent.sessionDates.contains(date) {
                return .clear // Clear background color
            } else {
                return nil // Default background color
            }
        }
        
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillSelectionColorFor date: Date) -> UIColor? {
            return UIColor.green // Disable default selection color
        }
    }
}

