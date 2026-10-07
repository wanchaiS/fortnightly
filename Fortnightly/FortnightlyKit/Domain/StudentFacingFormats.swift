import Foundation

// Formats used in messages the student reads (errors, prompts), in the phone's own locale and time zone.

extension DateInterval {
    /// "Sat 5:00 pm – 10:30 pm"
    var shiftTimesDescription: String {
        "\(start.formatted(.dateTime.weekday(.abbreviated).hour().minute())) – \(end.formatted(date: .omitted, time: .shortened))"
    }
}

extension WorkFortnight {
    /// "Mon 12 Oct – Sun 25 Oct"
    var datesDescription: String {
        let lastDay = interval.end.addingTimeInterval(-1)
        let style = Date.FormatStyle.dateTime.weekday(.abbreviated).day().month(.abbreviated)
        return "\(startsOn.formatted(style)) – \(lastDay.formatted(style))"
    }
}

extension Double {
    /// "51" or "50.5"
    var hoursDescription: String {
        formatted(.number.precision(.fractionLength(0 ... 1)))
    }
}
