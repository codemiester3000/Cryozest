import SwiftUI

struct SessionRow: View {
    var session: LogbookView.Session

    var body: some View {
        HStack {
            Text(session.date)
                .font(.system(size: 14))
                .frame(width: 100, alignment: .leading)
            Text(session.formattedDuration)
                .font(.system(size: 14))
                .frame(width: 70, alignment: .leading)
            Text("\(session.temperature)°")
                .font(.system(size: 14))
                .frame(width: 60, alignment: .leading)
            Text("\(session.humidity)%")
                .font(.system(size: 14))
                .frame(width: 60, alignment: .leading)
            Text(session.therapyType.rawValue)
                .font(.system(size: 14))
                .frame(width: 120, alignment: .leading)
        }
    }
}
