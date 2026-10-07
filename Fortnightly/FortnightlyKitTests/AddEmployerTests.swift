import Foundation
import Testing
@testable import FortnightlyKit

@Suite("Adding an employer")
struct AddEmployerTests {
    @Test("An employer with the same name as a current one is rejected")
    func sameNameAsCurrentEmployerIsRejected() {
        let employers = InMemoryEmployerRepository(.cafeRoma, .thaiExpress)

        #expect(throws: AddEmployerError.nameAlreadyUsed(existingName: "Café Roma")) {
            try AddEmployer(employers: employers, display: IgnoredDisplayRefresh())
                .execute(EmployerDetails(name: "  cafe roma ", payCycleStartsOn: october(5)))
        }
        #expect(employers.savedEmployers.count == 2)
    }

    @Test("A new employer gets a colour no current employer is using")
    func newEmployerGetsAColourNoCurrentEmployerUses() throws {
        var thaiExpress = Employer.thaiExpress
        thaiExpress.isArchived = true
        let uniLibrary = Employer(name: "Uni Library", colour: .magenta, payCycleStartsOn: october(5))
        let employers = InMemoryEmployerRepository(.cafeRoma, thaiExpress, uniLibrary)

        try AddEmployer(employers: employers, display: IgnoredDisplayRefresh())
            .execute(EmployerDetails(name: "Gelato Bar", payCycleStartsOn: october(5)))

        let gelatoBar = try #require(employers.savedEmployers.first { $0.name == "Gelato Bar" })
        #expect(gelatoBar.colour != .violet)
        #expect(gelatoBar.colour != .magenta)
    }
}
