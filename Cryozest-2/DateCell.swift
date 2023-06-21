//import UIKit
//import JTAppleCalendar
//
//class DateCell: JTACDayCell {
//
//    var dateLabel: UILabel!
//    var selectedView: UIView!
//    var eventDotView: UIView!
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//        // date label
//        dateLabel = UILabel()
//        dateLabel.textAlignment = .center
//        dateLabel.font = UIFont.systemFont(ofSize: 16)
//        contentView.addSubview(dateLabel)
//
//        // selected view
//        selectedView = UIView()
//        selectedView.isHidden = true
//        selectedView.layer.cornerRadius = 20
//        contentView.insertSubview(selectedView, at: 0)
//
//        // event dot view
//        eventDotView = UIView()
//        eventDotView.isHidden = true
//        eventDotView.layer.cornerRadius = 3
//        eventDotView.backgroundColor = .systemGreen
//        contentView.addSubview(eventDotView)
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        let side = bounds.height / 2.5
//        dateLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - side / 2)
//        selectedView.frame = CGRect(x: side, y: side, width: bounds.width - side * 2, height: bounds.height - side * 2)
//        eventDotView.frame = CGRect(x: bounds.midX - 3, y: bounds.maxY - 10, width: 6, height: 6)
//    }
//
//}
