import SwiftUI

// MARK: - BookCatalog

enum BookCatalog {

    // MARK: - Big Book (Alcoholics Anonymous, 2nd Edition)

    static let bigBook = Book(
        id: "bigbook",
        title: "Alcoholics Anonymous",
        subtitle: "The Big Book",
        author: "Bill W. et al.",
        edition: "Second Edition",
        icon: "text.book.closed.fill",
        iconColor: .brown,
        subdirectory: "BigBook",
        headerLinesToSkip: 4,
        chapters: [
            BookChapter(
                id: "00-foreword",
                filename: "00-foreword",
                title: "Foreword",
                subtitle: "pp. xiii\u{2013}xiv",
                number: nil
            ),
            BookChapter(
                id: "01-the-doctors-opinion",
                filename: "01-the-doctors-opinion",
                title: "The Doctor\u{2019}s Opinion",
                subtitle: "pp. xviii\u{2013}xxx",
                number: nil
            ),
            BookChapter(
                id: "02-bills-story",
                filename: "02-bills-story",
                title: "Bill\u{2019}s Story",
                subtitle: "pp. 1\u{2013}16",
                number: 1
            ),
            BookChapter(
                id: "03-there-is-a-solution",
                filename: "03-there-is-a-solution",
                title: "There Is a Solution",
                subtitle: "pp. 17\u{2013}29",
                number: 2
            ),
            BookChapter(
                id: "04-more-about-alcoholism",
                filename: "04-more-about-alcoholism",
                title: "More About Alcoholism",
                subtitle: "pp. 30\u{2013}43",
                number: 3
            ),
            BookChapter(
                id: "05-we-agnostics",
                filename: "05-we-agnostics",
                title: "We Agnostics",
                subtitle: "pp. 44\u{2013}57",
                number: 4
            ),
            BookChapter(
                id: "06-how-it-works",
                filename: "06-how-it-works",
                title: "How It Works",
                subtitle: "pp. 58\u{2013}71",
                number: 5
            ),
            BookChapter(
                id: "07-into-action",
                filename: "07-into-action",
                title: "Into Action",
                subtitle: "pp. 72\u{2013}88",
                number: 6
            ),
            BookChapter(
                id: "08-working-with-others",
                filename: "08-working-with-others",
                title: "Working with Others",
                subtitle: "pp. 89\u{2013}103",
                number: 7
            ),
            BookChapter(
                id: "09-to-wives",
                filename: "09-to-wives",
                title: "To Wives",
                subtitle: "pp. 104\u{2013}121",
                number: 8
            ),
            BookChapter(
                id: "10-the-family-afterward",
                filename: "10-the-family-afterward",
                title: "The Family Afterward",
                subtitle: "pp. 122\u{2013}135",
                number: 9
            ),
            BookChapter(
                id: "11-to-employers",
                filename: "11-to-employers",
                title: "To Employers",
                subtitle: "pp. 136\u{2013}150",
                number: 10
            ),
            BookChapter(
                id: "12-a-vision-for-you",
                filename: "12-a-vision-for-you",
                title: "A Vision for You",
                subtitle: "pp. 151\u{2013}164",
                number: 11
            ),
            BookChapter(
                id: "13-doctor-bobs-nightmare",
                filename: "13-doctor-bobs-nightmare",
                title: "Doctor Bob\u{2019}s Nightmare",
                subtitle: "pp. 171\u{2013}181",
                number: nil
            ),
            BookChapter(
                id: "14-spiritual-experience",
                filename: "14-spiritual-experience",
                title: "Spiritual Experience",
                subtitle: "pp. 569\u{2013}570",
                number: nil
            ),
        ],
        chapterLabel: "Chapter",
        numberStyle: .arabic
    )

    // MARK: - Confessions (Augustine of Hippo)

    static let confessions = Book(
        id: "confessions",
        title: "Confessions",
        subtitle: "Translated by E.B. Pusey",
        author: "Augustine of Hippo",
        edition: nil,
        icon: "flame.fill",
        iconColor: .orange,
        subdirectory: "Confessions",
        headerLinesToSkip: 4,
        chapters: [
            BookChapter(id: "01-book-i", filename: "01-book-i", title: "Book I", subtitle: "", number: 1),
            BookChapter(id: "02-book-ii", filename: "02-book-ii", title: "Book II", subtitle: "", number: 2),
            BookChapter(id: "03-book-iii", filename: "03-book-iii", title: "Book III", subtitle: "", number: 3),
            BookChapter(id: "04-book-iv", filename: "04-book-iv", title: "Book IV", subtitle: "", number: 4),
            BookChapter(id: "05-book-v", filename: "05-book-v", title: "Book V", subtitle: "", number: 5),
            BookChapter(id: "06-book-vi", filename: "06-book-vi", title: "Book VI", subtitle: "", number: 6),
            BookChapter(id: "07-book-vii", filename: "07-book-vii", title: "Book VII", subtitle: "", number: 7),
            BookChapter(id: "08-book-viii", filename: "08-book-viii", title: "Book VIII", subtitle: "", number: 8),
            BookChapter(id: "09-book-ix", filename: "09-book-ix", title: "Book IX", subtitle: "", number: 9),
            BookChapter(id: "10-book-x", filename: "10-book-x", title: "Book X", subtitle: "", number: 10),
            BookChapter(id: "11-book-xi", filename: "11-book-xi", title: "Book XI", subtitle: "", number: 11),
            BookChapter(id: "12-book-xii", filename: "12-book-xii", title: "Book XII", subtitle: "", number: 12),
            BookChapter(id: "13-book-xiii", filename: "13-book-xiii", title: "Book XIII", subtitle: "", number: 13),
        ],
        chapterLabel: "Book",
        numberStyle: .roman
    )

    // MARK: - Humility (Andrew Murray)

    static let humility = Book(
        id: "humility",
        title: "Humility",
        subtitle: "The Beauty of Holiness",
        author: "Andrew Murray",
        edition: nil,
        icon: "person.and.arrow.left.and.arrow.right",
        iconColor: .rrPrimary,
        subdirectory: "Humility",
        headerLinesToSkip: 4,
        chapters: [
            BookChapter(id: "01-chapter-01", filename: "01-chapter-01", title: "Humility: The Glory of the Creature", subtitle: "", number: 1),
            BookChapter(id: "02-chapter-02", filename: "02-chapter-02", title: "Humility: The Secret of Redemption", subtitle: "", number: 2),
            BookChapter(id: "03-chapter-03", filename: "03-chapter-03", title: "The Humility of Jesus", subtitle: "", number: 3),
            BookChapter(id: "04-chapter-04", filename: "04-chapter-04", title: "Humility in the Teaching of Jesus", subtitle: "", number: 4),
            BookChapter(id: "05-chapter-05", filename: "05-chapter-05", title: "Humility in the Disciples of Jesus", subtitle: "", number: 5),
            BookChapter(id: "06-chapter-06", filename: "06-chapter-06", title: "Humility in Daily Life", subtitle: "", number: 6),
            BookChapter(id: "07-chapter-07", filename: "07-chapter-07", title: "Humility and Holiness", subtitle: "", number: 7),
            BookChapter(id: "08-chapter-08", filename: "08-chapter-08", title: "Humility and Sin", subtitle: "", number: 8),
            BookChapter(id: "09-chapter-09", filename: "09-chapter-09", title: "Humility and Faith", subtitle: "", number: 9),
            BookChapter(id: "10-chapter-10", filename: "10-chapter-10", title: "Humility and Death to Self", subtitle: "", number: 10),
            BookChapter(id: "11-chapter-11", filename: "11-chapter-11", title: "Humility and Happiness", subtitle: "", number: 11),
            BookChapter(id: "12-chapter-12", filename: "12-chapter-12", title: "Humility and Exaltation", subtitle: "", number: 12),
        ],
        chapterLabel: "Chapter",
        numberStyle: .arabic
    )

    // MARK: - Absolute Surrender (Andrew Murray)

    static let absoluteSurrender = Book(
        id: "absolutesurrender",
        title: "Absolute Surrender",
        subtitle: "",
        author: "Andrew Murray",
        edition: nil,
        icon: "hands.sparkles.fill",
        iconColor: .purple,
        subdirectory: "AbsoluteSurrender",
        headerLinesToSkip: 4,
        chapters: [
            BookChapter(id: "01-chapter-01", filename: "01-chapter-01", title: "Absolute Surrender", subtitle: "", number: 1),
            BookChapter(id: "02-chapter-02", filename: "02-chapter-02", title: "The Fruit of the Spirit Is Love", subtitle: "", number: 2),
            BookChapter(id: "03-chapter-03", filename: "03-chapter-03", title: "Separated Unto the Holy Ghost", subtitle: "", number: 3),
            BookChapter(id: "04-chapter-04", filename: "04-chapter-04", title: "Peter\u{2019}s Repentance", subtitle: "", number: 4),
            BookChapter(id: "05-chapter-05", filename: "05-chapter-05", title: "Impossible with Man, Possible with God", subtitle: "", number: 5),
            BookChapter(id: "06-chapter-06", filename: "06-chapter-06", title: "O Wretched Man That I Am!", subtitle: "", number: 6),
            BookChapter(id: "07-chapter-07", filename: "07-chapter-07", title: "Having Begun in the Spirit", subtitle: "", number: 7),
            BookChapter(id: "08-chapter-08", filename: "08-chapter-08", title: "Kept by the Power of God", subtitle: "", number: 8),
            BookChapter(id: "09-chapter-09", filename: "09-chapter-09", title: "Ye Are the Branches", subtitle: "", number: 9),
        ],
        chapterLabel: "Chapter",
        numberStyle: .arabic
    )

    // MARK: - With Christ in the School of Prayer (Andrew Murray)

    static let schoolOfPrayer = Book(
        id: "schoolofprayer",
        title: "With Christ in the School of Prayer",
        subtitle: "With Christ in the School of Prayer",
        author: "Andrew Murray",
        edition: nil,
        icon: "book.and.wreath.fill",
        iconColor: .rrSecondary,
        subdirectory: "SchoolOfPrayer",
        headerLinesToSkip: 4,
        chapters: [
            BookChapter(id: "01-lesson-01", filename: "01-lesson-01", title: "Lord, Teach Us to Pray", subtitle: "", number: 1),
            BookChapter(id: "02-lesson-02", filename: "02-lesson-02", title: "In Spirit and Truth", subtitle: "", number: 2),
            BookChapter(id: "03-lesson-03", filename: "03-lesson-03", title: "Pray to Thy Father, Which Is in Secret", subtitle: "", number: 3),
            BookChapter(id: "04-lesson-04", filename: "04-lesson-04", title: "After This Manner Pray", subtitle: "", number: 4),
            BookChapter(id: "05-lesson-05", filename: "05-lesson-05", title: "Ask, and It Shall Be Given You", subtitle: "", number: 5),
            BookChapter(id: "06-lesson-06", filename: "06-lesson-06", title: "How Much More?", subtitle: "", number: 6),
            BookChapter(id: "07-lesson-07", filename: "07-lesson-07", title: "How Much More the Holy Spirit", subtitle: "", number: 7),
            BookChapter(id: "08-lesson-08", filename: "08-lesson-08", title: "Because of His Importunity", subtitle: "", number: 8),
            BookChapter(id: "09-lesson-09", filename: "09-lesson-09", title: "Pray the Lord of the Harvest", subtitle: "", number: 9),
            BookChapter(id: "10-lesson-10", filename: "10-lesson-10", title: "What Wilt Thou?", subtitle: "", number: 10),
            BookChapter(id: "11-lesson-11", filename: "11-lesson-11", title: "Believe That Ye Have Received", subtitle: "", number: 11),
            BookChapter(id: "12-lesson-12", filename: "12-lesson-12", title: "Have Faith in God", subtitle: "", number: 12),
            BookChapter(id: "13-lesson-13", filename: "13-lesson-13", title: "Prayer and Fasting", subtitle: "", number: 13),
            BookChapter(id: "14-lesson-14", filename: "14-lesson-14", title: "When Ye Stand Praying, Forgive", subtitle: "", number: 14),
            BookChapter(id: "15-lesson-15", filename: "15-lesson-15", title: "If Two Agree", subtitle: "", number: 15),
            BookChapter(id: "16-lesson-16", filename: "16-lesson-16", title: "Speedily, Though Bearing Long", subtitle: "", number: 16),
            BookChapter(id: "17-lesson-17", filename: "17-lesson-17", title: "I Know That Thou Hearest Me Always", subtitle: "", number: 17),
            BookChapter(id: "18-lesson-18", filename: "18-lesson-18", title: "Whose Is This Image?", subtitle: "", number: 18),
            BookChapter(id: "19-lesson-19", filename: "19-lesson-19", title: "I Go unto the Father!", subtitle: "", number: 19),
            BookChapter(id: "20-lesson-20", filename: "20-lesson-20", title: "That the Father May Be Glorified", subtitle: "", number: 20),
            BookChapter(id: "21-lesson-21", filename: "21-lesson-21", title: "If Ye Abide in Me", subtitle: "", number: 21),
            BookChapter(id: "22-lesson-22", filename: "22-lesson-22", title: "My Words in You", subtitle: "", number: 22),
            BookChapter(id: "23-lesson-23", filename: "23-lesson-23", title: "Bear Fruit, That the Father May Give What Ye Ask", subtitle: "", number: 23),
            BookChapter(id: "24-lesson-24", filename: "24-lesson-24", title: "In My Name", subtitle: "", number: 24),
            BookChapter(id: "25-lesson-25", filename: "25-lesson-25", title: "At That Day", subtitle: "", number: 25),
            BookChapter(id: "26-lesson-26", filename: "26-lesson-26", title: "I Have Prayed for Thee", subtitle: "", number: 26),
            BookChapter(id: "27-lesson-27", filename: "27-lesson-27", title: "Father, I Will", subtitle: "", number: 27),
            BookChapter(id: "28-lesson-28", filename: "28-lesson-28", title: "Father! Not What I Will", subtitle: "", number: 28),
            BookChapter(id: "29-lesson-29", filename: "29-lesson-29", title: "According to His Will", subtitle: "", number: 29),
            BookChapter(id: "30-lesson-30", filename: "30-lesson-30", title: "An Holy Priesthood", subtitle: "", number: 30),
            BookChapter(id: "31-lesson-31", filename: "31-lesson-31", title: "Pray Without Ceasing", subtitle: "", number: 31),
        ],
        chapterLabel: "Lesson",
        numberStyle: .arabic
    )

    // MARK: - Waiting on God (Andrew Murray)

    static let waitingOnGod = Book(
        id: "waitingongod",
        title: "Waiting on God",
        subtitle: "",
        author: "Andrew Murray",
        edition: nil,
        icon: "clock.badge.checkmark.fill",
        iconColor: .rrSuccess,
        subdirectory: "WaitingOnGod",
        headerLinesToSkip: 4,
        chapters: [
            BookChapter(id: "01-day-01", filename: "01-day-01", title: "The God of Our Salvation", subtitle: "", number: 1),
            BookChapter(id: "02-day-02", filename: "02-day-02", title: "The Keynote of Life", subtitle: "", number: 2),
            BookChapter(id: "03-day-03", filename: "03-day-03", title: "The True Place of the Creature", subtitle: "", number: 3),
            BookChapter(id: "04-day-04", filename: "04-day-04", title: "For Supplies", subtitle: "", number: 4),
            BookChapter(id: "05-day-05", filename: "05-day-05", title: "For Instruction", subtitle: "", number: 5),
            BookChapter(id: "06-day-06", filename: "06-day-06", title: "For All Saints", subtitle: "", number: 6),
            BookChapter(id: "07-day-07", filename: "07-day-07", title: "A Plea in Prayer", subtitle: "", number: 7),
            BookChapter(id: "08-day-08", filename: "08-day-08", title: "Strong and of Good Courage", subtitle: "", number: 8),
            BookChapter(id: "09-day-09", filename: "09-day-09", title: "With the Heart", subtitle: "", number: 9),
            BookChapter(id: "10-day-10", filename: "10-day-10", title: "In Humble Fear and Hope", subtitle: "", number: 10),
            BookChapter(id: "11-day-11", filename: "11-day-11", title: "Patiently", subtitle: "", number: 11),
            BookChapter(id: "12-day-12", filename: "12-day-12", title: "Keeping His Ways", subtitle: "", number: 12),
            BookChapter(id: "13-day-13", filename: "13-day-13", title: "For More Than We Know", subtitle: "", number: 13),
            BookChapter(id: "14-day-14", filename: "14-day-14", title: "The Way to the New Song", subtitle: "", number: 14),
            BookChapter(id: "15-day-15", filename: "15-day-15", title: "For His Counsel", subtitle: "", number: 15),
            BookChapter(id: "16-day-16", filename: "16-day-16", title: "For His Light in the Heart", subtitle: "", number: 16),
            BookChapter(id: "17-day-17", filename: "17-day-17", title: "In Times of Darkness", subtitle: "", number: 17),
            BookChapter(id: "18-day-18", filename: "18-day-18", title: "To Reveal Himself", subtitle: "", number: 18),
            BookChapter(id: "19-day-19", filename: "19-day-19", title: "As a God of Judgment", subtitle: "", number: 19),
            BookChapter(id: "20-day-20", filename: "20-day-20", title: "Who Waits on Us", subtitle: "", number: 20),
            BookChapter(id: "21-day-21", filename: "21-day-21", title: "The Almighty One", subtitle: "", number: 21),
            BookChapter(id: "22-day-22", filename: "22-day-22", title: "Its Certainty of Blessing", subtitle: "", number: 22),
            BookChapter(id: "23-day-23", filename: "23-day-23", title: "For Unlooked-for Things", subtitle: "", number: 23),
            BookChapter(id: "24-day-24", filename: "24-day-24", title: "To Know His Goodness", subtitle: "", number: 24),
            BookChapter(id: "25-day-25", filename: "25-day-25", title: "Quietly", subtitle: "", number: 25),
            BookChapter(id: "26-day-26", filename: "26-day-26", title: "In Holy Expectancy", subtitle: "", number: 26),
            BookChapter(id: "27-day-27", filename: "27-day-27", title: "For Redemption", subtitle: "", number: 27),
            BookChapter(id: "28-day-28", filename: "28-day-28", title: "For the Coming of His Son", subtitle: "", number: 28),
            BookChapter(id: "29-day-29", filename: "29-day-29", title: "For the Promise of the Father", subtitle: "", number: 29),
            BookChapter(id: "30-day-30", filename: "30-day-30", title: "Continually", subtitle: "", number: 30),
            BookChapter(id: "31-day-31", filename: "31-day-31", title: "Only", subtitle: "", number: 31),
        ],
        chapterLabel: "Day",
        numberStyle: .arabic
    )

    // MARK: - All Books

    static let allBooks: [Book] = [
        bigBook,
        confessions,
        humility,
        absoluteSurrender,
        schoolOfPrayer,
        waitingOnGod,
    ]
}
