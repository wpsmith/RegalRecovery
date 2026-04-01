import Testing
@testable import RegalRecovery

@Suite("ProfileViewModel")
struct ProfileViewModelTests {

    @Test("load populates user data from mock")
    func testLoad_PopulatesUserData() async {
        let vm = ProfileViewModel()
        await vm.load()

        #expect(vm.user != nil)
        #expect(vm.user?.name == "Alex")
        #expect(vm.editName == "Alex")
        #expect(vm.editEmail == "alex@example.com")
        #expect(!vm.addictions.isEmpty)
        #expect(!vm.supportNetwork.isEmpty)
        #expect(vm.streakDays == 270)
    }

    @Test("save updates the user name")
    func testSave_UpdatesName() async throws {
        let vm = ProfileViewModel()
        await vm.load()

        vm.editName = "Jordan"
        try await vm.save()

        #expect(vm.user?.name == "Jordan")
        #expect(vm.user?.avatarInitial == "J")
    }

    @Test("addAddiction appends to the list")
    func testAddAddiction_AppendsToList() async throws {
        let vm = ProfileViewModel()
        await vm.load()

        let countBefore = vm.addictions.count
        try await vm.addAddiction("Gambling", sobrietyDate: Date())

        #expect(vm.addictions.count == countBefore + 1)
        #expect(vm.addictions.contains("Gambling"))
    }

    @Test("removeAddiction removes from the list")
    func testRemoveAddiction_RemovesFromList() async throws {
        let vm = ProfileViewModel()
        await vm.load()

        let first = vm.addictions.first!
        try await vm.removeAddiction(first)

        #expect(!vm.addictions.contains(first))
    }
}
