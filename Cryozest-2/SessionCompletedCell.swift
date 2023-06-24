import SwiftUI
import FSCalendar

class SessionCompleteCell: FSCalendarCell {
    var circleView: UIView?
    var therapyType: TherapyType? {
        didSet {
            // Whenever therapyType changes, update circleView's background color
            if let therapyType = therapyType {
                circleView?.backgroundColor = UIColor(therapyType.color)
            }
        }
    }

    override init!(frame: CGRect) {
        super.init(frame: frame)

        // Create the circle view with larger size
        circleView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30)) // 30% larger than 20x20
        circleView?.layer.cornerRadius = 15 // Half the width and height to make it circular
        circleView?.isHidden = true // Hide it initially

        if let circleView = circleView {
            // Add the circle view to the contentView
            contentView.insertSubview(circleView, belowSubview: self.titleLabel)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Position the circle view centered with titleLabel
        if let circleView = circleView {
            circleView.center.x = contentView.center.x
            circleView.center.y = titleLabel.center.y
        }
    }

    // Function to show or hide the circle view
    func showCircle(_ show: Bool) {
        circleView?.isHidden = !show
    }
}

