import Foundation
import Testing
@testable import FortnightlyKit

@Suite("Recording a course break")
struct RecordCourseBreakTests {
    @Test("A course break starting on another break's last day is rejected")
    func breakStartingOnAnotherBreaksLastDayIsRejected() {
        let midSemester = CourseBreak(name: "Mid-semester break", startsOn: october(19), endsOn: october(25))
        let courseBreaks = InMemoryCourseBreakRepository()
        courseBreaks.add(midSemester)

        #expect(throws: RecordCourseBreakError.overlaps(midSemester)) {
            try RecordCourseBreak(courseBreaks: courseBreaks, display: IgnoredDisplayRefresh(), calendar: Sydney.calendar)
                .execute(CourseBreakDetails(name: "Study week", startsOn: october(25), endsOn: october(30)))
        }
        #expect(courseBreaks.savedCourseBreaks == [midSemester])
    }
}
