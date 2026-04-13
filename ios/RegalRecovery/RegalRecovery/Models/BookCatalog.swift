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

    // MARK: - The Imitation of Christ (Thomas a Kempis)

    static let imitationOfChrist: Book = {
        // Book I (25 chapters), Book II (12), Book III (59), Book IV (18) = 114 total
        let bookRanges: [(prefix: String, chapters: [(roman: String, title: String)])] = [
            ("booki", [
                ("chi", "Of the imitation of Christ, and of contempt of the world and all its vanities"),
                ("chii", "Of thinking humbly of oneself"),
                ("chiii", "Of the knowledge of truth"),
                ("chiv", "Of prudence in action"),
                ("chv", "Of the reading of Holy Scriptures"),
                ("chvi", "Of inordinate affections"),
                ("chvii", "Of fleeing from vain hope and pride"),
                ("chviii", "Of the danger of too much familiarity"),
                ("chix", "Of Obedience and Subjection"),
                ("chx", "Of the danger of superfluity of words"),
                ("chxi", "Of seeking peace of mind and of spiritual progress"),
                ("chxii", "Of the uses of adversity"),
                ("chxiii", "Of resisting temptation"),
                ("chxiv", "On avoiding rash judgment"),
                ("chxv", "Of works of charity"),
                ("chxvi", "Of bearing with the faults of others"),
                ("chxvii", "Of a Religious life"),
                ("chxviii", "Of the example of the holy fathers"),
                ("chxix", "Of the exercises of a religious man"),
                ("chxx", "Of the love of solitude and silence"),
                ("chxxi", "Of compunction of heart"),
                ("chxxii", "On the contemplation of human misery"),
                ("chxxiii", "Of meditation upon death"),
                ("chxxiv", "Of the judgment and punishment of the wicked"),
                ("chxxv", "Of the zealous amendment of our whole life"),
            ]),
            ("bookii", [
                ("chi", "Of the inward life"),
                ("chii", "Of lowly submission"),
                ("chiii", "Of the good, peaceable man"),
                ("chiv", "Of a pure mind and simple intention"),
                ("chv", "Of self-esteem"),
                ("chvi", "Of the joy of a good conscience"),
                ("chvii", "Of loving Jesus above all things"),
                ("chviii", "Of the intimate love of Jesus"),
                ("chix", "Of the lack of all comfort"),
                ("chx", "Of gratitude for the Grace of God"),
                ("chxi", "Of the fewness of those who love the Cross of Jesus"),
                ("chxii", "Of the royal way of the Holy Cross"),
            ]),
            ("bookiii", [
                ("chi", "Of the inward voice of Christ to the faithful soul"),
                ("chii", "What the truth saith inwardly without noise of words"),
                ("chiii", "How all the words of God are to be heard with humility, and how many consider them not"),
                ("chiv", "How we must walk in truth and humility before God"),
                ("chv", "Of the wonderful power of the Divine Love"),
                ("chvi", "Of the proving of the true lover"),
                ("chvii", "Of hiding our grace under the guard of humility"),
                ("chviii", "Of a low estimation of self in the sight of God"),
                ("chix", "That all things are to be referred to God, as the final end"),
                ("chx", "That it is sweet to despise the world and to serve God"),
                ("chxi", "That the desires of the heart are to be examined and governed"),
                ("chxii", "Of the inward growth of patience, and of the struggle against evil desires"),
                ("chxiii", "Of the obedience of one in lowly subjection after the example of Jesus Christ"),
                ("chxiv", "Of meditation upon the hidden judgments of God, that we may not be lifted up because of our well-doing"),
                ("chxv", "How we must stand and speak, in everything that we desire"),
                ("chxvi", "That true solace is to be sought in God alone"),
                ("chxvii", "That all care is to be cast upon God"),
                ("chxviii", "That temporal miseries are to be borne patiently after the example of Christ"),
                ("chxix", "Of bearing injuries, and who shall be approved as truly patient"),
                ("chxx", "Of confession of our infirmity and of the miseries of this life"),
                ("chxxi", "That we must rest in God above all goods and gifts"),
                ("chxxii", "Of the recollection of God\u{2019}s manifold benefits"),
                ("chxxiii", "Of four things which bring great peace"),
                ("chxxiv", "Of avoiding of curious inquiry into the life of another"),
                ("chxxv", "Wherein firm peace of heart and true profit consist"),
                ("chxxvi", "Of the exaltation of a free spirit, which humble prayer more deserveth than doth frequent reading"),
                ("chxxvii", "That personal love greatly hindereth from the highest good"),
                ("chxxviii", "Against the tongues of detractors"),
                ("chxxix", "How when tribulation cometh we must call upon and bless God"),
                ("chxxx", "Of seeking divine help, and the confidence of obtaining grace"),
                ("chxxxi", "Of the neglect of every creature, that the Creator may be found"),
                ("chxxxii", "Of self-denial and the casting away all selfishness"),
                ("chxxxiii", "Of instability of the heart, and of directing the aim towards God"),
                ("chxxxiv", "That to him who loveth God is sweet above all things and in all things"),
                ("chxxxv", "That there is no security against temptation in this life"),
                ("chxxxvi", "Against vain judgments of men"),
                ("chxxxvii", "Of pure and entire resignation of self, for the obtaining liberty of heart"),
                ("chxxxviii", "Of a good government in external things, and of having recourse to God in dangers"),
                ("chxxxix", "That man must not be immersed in business"),
                ("chxl", "That man hath no good in himself, and nothing whereof to glory"),
                ("chxli", "Of contempt of all temporal honour"),
                ("chxlii", "That our peace is not to be placed in men"),
                ("chxliii", "Against vain and worldly knowledge"),
                ("chxliv", "Of not troubling ourselves about outward things"),
                ("chxlv", "That we must not believe everyone, and that we are prone to fall in our words"),
                ("chxlvi", "Of having confidence in God when evil words are cast at us"),
                ("chxlvii", "That all troubles are to be endured for the sake of eternal life"),
                ("chxlviii", "Of the day of eternity and of the straitnesses of this life"),
                ("chxlix", "Of the desire after eternal life, and how great blessings are promised to those who strive"),
                ("chl", "How a desolate man ought to commit himself into the hands of God"),
                ("chli", "That we must give ourselves to humble works when we are unequal to those that are lofty"),
                ("chlii", "That a man ought not to reckon himself worthy of consolation, but more worthy of chastisement"),
                ("chliii", "That the Grace of God doth not join itself to those who mind earthly things"),
                ("chliv", "Of the diverse motions of Nature and of Grace"),
                ("chlv", "Of the corruption of Nature and the efficacy of Divine Grace"),
                ("chlvi", "That we ought to deny ourselves, and to imitate Christ by means of the Cross"),
                ("chlvii", "That a man must not be too much cast down when he falleth into some faults"),
                ("chlviii", "Of deeper matters, and God\u{2019}s hidden judgments which are not to be inquired into"),
                ("chlix", "That all hope and trust is to be fixed in God alone"),
            ]),
            ("bookiv", [
                ("chi", "With how great reverence Christ must be received"),
                ("chii", "That the greatness and charity of God is shown to men in the Sacrament"),
                ("chiii", "That it is profitable to Communicate often"),
                ("chiv", "That many good gifts are bestowed upon those who Communicate devoutly"),
                ("chv", "Of the dignity of this Sacrament, and of the office of the priest"),
                ("chvi", "An inquiry concerning preparation for Communion"),
                ("chvii", "Of the examination of conscience, and purpose of amendment"),
                ("chviii", "Of the oblation of Christ upon the cross, and of resignation of self"),
                ("chix", "That we ought to offer ourselves and all that is ours to God, and to pray for all"),
                ("chx", "That Holy Communion is not lightly to be omitted"),
                ("chxi", "That the Body and Blood of Christ and the Holy Scriptures are most necessary to a faithful soul"),
                ("chxii", "That he who is about to Communicate with Christ ought to prepare himself with great diligence"),
                ("chxiii", "That the devout soul ought with the whole heart to yearn after union with Christ in the Sacrament"),
                ("chxiv", "Of the fervent desire of certain devout persons to receive the Body and Blood of Christ"),
                ("chxv", "That the grace of devotion is acquired by humility and self-denial"),
                ("chxvi", "That we ought to lay open our necessities to Christ and to require His Grace"),
                ("chxvii", "Of fervent love and vehement desire of receiving Christ"),
                ("chxviii", "That a man should not be a curious searcher of the Sacrament, but a humble imitator of Christ, submitting his sense to holy faith"),
            ]),
        ]

        var chapters: [BookChapter] = []
        var fileNumber = 1
        for bookRange in bookRanges {
            for entry in bookRange.chapters {
                let paddedNum = String(format: "%02d", fileNumber)
                let filename = "\(paddedNum)-\(bookRange.prefix)-\(entry.roman)"
                chapters.append(BookChapter(
                    id: filename,
                    filename: filename,
                    title: entry.title,
                    subtitle: "",
                    number: fileNumber
                ))
                fileNumber += 1
            }
        }

        return Book(
            id: "imitationOfChrist",
            title: "The Imitation of Christ",
            subtitle: "Translated by William Benham",
            author: "Thomas a Kempis",
            edition: nil,
            icon: "cross.fill",
            iconColor: .rrPrimary,
            subdirectory: "ImitationOfChrist",
            headerLinesToSkip: 4,
            chapters: chapters,
            chapterLabel: "Chapter",
            numberStyle: .roman
        )
    }()

    // MARK: - The Practice of the Presence of God (Brother Lawrence)

    static let practicePresenceOfGod = Book(
        id: "practicePresenceOfGod",
        title: "The Practice of the Presence of God",
        subtitle: "",
        author: "Brother Lawrence",
        edition: nil,
        icon: "sparkles",
        iconColor: .yellow,
        subdirectory: "PracticePresenceOfGod",
        headerLinesToSkip: 4,
        chapters: [
            BookChapter(id: "01-preface", filename: "01-preface", title: "Preface", subtitle: "", number: nil),
            BookChapter(id: "02-first-conversation", filename: "02-first-conversation", title: "First Conversation", subtitle: "", number: 1),
            BookChapter(id: "03-second-conversation", filename: "03-second-conversation", title: "Second Conversation", subtitle: "", number: 2),
            BookChapter(id: "04-third-conversation", filename: "04-third-conversation", title: "Third Conversation", subtitle: "", number: 3),
            BookChapter(id: "05-fourth-conversation", filename: "05-fourth-conversation", title: "Fourth Conversation", subtitle: "", number: 4),
            BookChapter(id: "06-first-letter", filename: "06-first-letter", title: "First Letter", subtitle: "", number: 5),
            BookChapter(id: "07-second-letter", filename: "07-second-letter", title: "Second Letter", subtitle: "", number: 6),
            BookChapter(id: "08-third-letter", filename: "08-third-letter", title: "Third Letter", subtitle: "", number: 7),
            BookChapter(id: "09-fourth-letter", filename: "09-fourth-letter", title: "Fourth Letter", subtitle: "", number: 8),
            BookChapter(id: "10-fifth-letter", filename: "10-fifth-letter", title: "Fifth Letter", subtitle: "", number: 9),
            BookChapter(id: "11-sixth-letter", filename: "11-sixth-letter", title: "Sixth Letter", subtitle: "", number: 10),
            BookChapter(id: "12-seventh-letter", filename: "12-seventh-letter", title: "Seventh Letter", subtitle: "", number: 11),
            BookChapter(id: "13-eighth-letter", filename: "13-eighth-letter", title: "Eighth Letter", subtitle: "", number: 12),
            BookChapter(id: "14-ninth-letter", filename: "14-ninth-letter", title: "Ninth Letter", subtitle: "", number: 13),
            BookChapter(id: "15-tenth-letter", filename: "15-tenth-letter", title: "Tenth Letter", subtitle: "", number: 14),
            BookChapter(id: "16-eleventh-letter", filename: "16-eleventh-letter", title: "Eleventh Letter", subtitle: "", number: 15),
            BookChapter(id: "17-twelfth-letter", filename: "17-twelfth-letter", title: "Twelfth Letter", subtitle: "", number: 16),
            BookChapter(id: "18-thirteenth-letter", filename: "18-thirteenth-letter", title: "Thirteenth Letter", subtitle: "", number: 17),
            BookChapter(id: "19-fourteenth-letter", filename: "19-fourteenth-letter", title: "Fourteenth Letter", subtitle: "", number: 18),
            BookChapter(id: "20-fifteenth-letter", filename: "20-fifteenth-letter", title: "Fifteenth Letter", subtitle: "", number: 19),
        ],
        chapterLabel: "Section",
        numberStyle: .arabic
    )

    // MARK: - The Pursuit of God (A.W. Tozer)

    static let pursuitOfGod = Book(
        id: "pursuitOfGod",
        title: "The Pursuit of God",
        subtitle: "",
        author: "A.W. Tozer",
        edition: nil,
        icon: "figure.walk",
        iconColor: .rrSecondary,
        subdirectory: "PursuitOfGod",
        headerLinesToSkip: 4,
        chapters: [
            BookChapter(id: "01-introduction", filename: "01-introduction", title: "Introduction", subtitle: "", number: nil),
            BookChapter(id: "02-preface", filename: "02-preface", title: "Preface", subtitle: "", number: nil),
            BookChapter(id: "03-following-hard-after-god", filename: "03-following-hard-after-god", title: "Following Hard after God", subtitle: "", number: 1),
            BookChapter(id: "04-the-blessedness-of-possessing-nothing", filename: "04-the-blessedness-of-possessing-nothing", title: "The Blessedness of Possessing Nothing", subtitle: "", number: 2),
            BookChapter(id: "05-removing-the-veil", filename: "05-removing-the-veil", title: "Removing the Veil", subtitle: "", number: 3),
            BookChapter(id: "06-apprehending-god", filename: "06-apprehending-god", title: "Apprehending God", subtitle: "", number: 4),
            BookChapter(id: "07-the-universal-presence", filename: "07-the-universal-presence", title: "The Universal Presence", subtitle: "", number: 5),
            BookChapter(id: "08-the-speaking-voice", filename: "08-the-speaking-voice", title: "The Speaking Voice", subtitle: "", number: 6),
            BookChapter(id: "09-the-gaze-of-the-soul", filename: "09-the-gaze-of-the-soul", title: "The Gaze of the Soul", subtitle: "", number: 7),
            BookChapter(id: "10-restoring-the-creator-creature-relation", filename: "10-restoring-the-creator-creature-relation", title: "Restoring the Creator-creature Relation", subtitle: "", number: 8),
            BookChapter(id: "11-meekness-and-rest", filename: "11-meekness-and-rest", title: "Meekness and Rest", subtitle: "", number: 9),
            BookChapter(id: "12-the-sacrament-of-living", filename: "12-the-sacrament-of-living", title: "The Sacrament of Living", subtitle: "", number: 10),
        ],
        chapterLabel: "Chapter",
        numberStyle: .arabic
    )

    // MARK: - Grace Abounding to the Chief of Sinners (John Bunyan)

    static let graceAbounding = Book(
        id: "graceAbounding",
        title: "Grace Abounding to the Chief of Sinners",
        subtitle: "",
        author: "John Bunyan",
        edition: nil,
        icon: "heart.circle.fill",
        iconColor: .rrDestructive,
        subdirectory: "GraceAbounding",
        headerLinesToSkip: 4,
        chapters: [
            BookChapter(id: "01-prefatory-note", filename: "01-prefatory-note", title: "Prefatory Note", subtitle: "", number: nil),
            BookChapter(id: "02-a-preface", filename: "02-a-preface", title: "A Preface", subtitle: "", number: nil),
            BookChapter(id: "03-grace-abounding-introduction", filename: "03-grace-abounding-introduction", title: "Introduction", subtitle: "", number: nil),
            BookChapter(id: "04-paragraphs-2-40", filename: "04-paragraphs-2-40", title: "Paragraphs 2\u{2013}40", subtitle: "", number: 1),
            BookChapter(id: "05-paragraphs-41-80", filename: "05-paragraphs-41-80", title: "Paragraphs 41\u{2013}80", subtitle: "", number: 2),
            BookChapter(id: "06-paragraphs-81-120", filename: "06-paragraphs-81-120", title: "Paragraphs 81\u{2013}120", subtitle: "", number: 3),
            BookChapter(id: "07-paragraphs-121-160", filename: "07-paragraphs-121-160", title: "Paragraphs 121\u{2013}160", subtitle: "", number: 4),
            BookChapter(id: "08-paragraphs-161-200", filename: "08-paragraphs-161-200", title: "Paragraphs 161\u{2013}200", subtitle: "", number: 5),
            BookChapter(id: "09-paragraphs-201-240", filename: "09-paragraphs-201-240", title: "Paragraphs 201\u{2013}240", subtitle: "", number: 6),
            BookChapter(id: "10-paragraphs-241-280", filename: "10-paragraphs-241-280", title: "Paragraphs 241\u{2013}280", subtitle: "", number: 7),
            BookChapter(id: "11-paragraphs-281-317", filename: "11-paragraphs-281-317", title: "Paragraphs 281\u{2013}317", subtitle: "", number: 8),
            BookChapter(id: "12-a-brief-account-of-the-authors-imprisonment", filename: "12-a-brief-account-of-the-authors-imprisonment", title: "A Brief Account of the Author\u{2019}s Imprisonment", subtitle: "", number: nil),
            BookChapter(id: "13-the-conclusion", filename: "13-the-conclusion", title: "The Conclusion", subtitle: "", number: nil),
            BookChapter(id: "14-a-relation-of-the-authors-imprisonment", filename: "14-a-relation-of-the-authors-imprisonment", title: "A Relation of the Author\u{2019}s Imprisonment", subtitle: "", number: nil),
            BookChapter(id: "15-a-continuation-of-the-authors-life", filename: "15-a-continuation-of-the-authors-life", title: "A Continuation of the Author\u{2019}s Life", subtitle: "", number: nil),
            BookChapter(id: "16-a-brief-character-of-the-author", filename: "16-a-brief-character-of-the-author", title: "A Brief Character of the Author", subtitle: "", number: nil),
            BookChapter(id: "17-postscript", filename: "17-postscript", title: "Postscript", subtitle: "", number: nil),
        ],
        chapterLabel: "Section",
        numberStyle: .arabic
    )

    // MARK: - Power Through Prayer (E.M. Bounds)

    static let powerThroughPrayer = Book(
        id: "powerThroughPrayer",
        title: "Power Through Prayer",
        subtitle: "",
        author: "E.M. Bounds",
        edition: nil,
        icon: "bolt.fill",
        iconColor: .orange,
        subdirectory: "PowerThroughPrayer",
        headerLinesToSkip: 4,
        chapters: [
            BookChapter(id: "01-foreword-i-rev-a-c-dixon-dd", filename: "01-foreword-i-rev-a-c-dixon-dd", title: "Foreword: Rev. A. C. Dixon, D.D.", subtitle: "", number: nil),
            BookChapter(id: "02-foreword-ii-mr-albert-a-head", filename: "02-foreword-ii-mr-albert-a-head", title: "Foreword: Mr. Albert A. Head", subtitle: "", number: nil),
            BookChapter(id: "03-the-man-behind-the-sermon", filename: "03-the-man-behind-the-sermon", title: "The Man Behind the Sermon", subtitle: "", number: 1),
            BookChapter(id: "04-preaching-that-kills", filename: "04-preaching-that-kills", title: "Preaching that Kills", subtitle: "", number: 2),
            BookChapter(id: "05-the-letter-killeth", filename: "05-the-letter-killeth", title: "The Letter Killeth", subtitle: "", number: 3),
            BookChapter(id: "06-tendencies-to-be-avoided", filename: "06-tendencies-to-be-avoided", title: "Tendencies to be Avoided", subtitle: "", number: 4),
            BookChapter(id: "07-prayer-the-great-essential", filename: "07-prayer-the-great-essential", title: "Prayer the Great Essential", subtitle: "", number: 5),
            BookChapter(id: "08-a-praying-ministry-successful", filename: "08-a-praying-ministry-successful", title: "A Praying Ministry Successful", subtitle: "", number: 6),
            BookChapter(id: "09-much-time-should-be-given-to-prayer", filename: "09-much-time-should-be-given-to-prayer", title: "Much Time Should Be Given to Prayer", subtitle: "", number: 7),
            BookChapter(id: "10-examples-of-praying-men", filename: "10-examples-of-praying-men", title: "Examples of Praying Men", subtitle: "", number: 8),
            BookChapter(id: "11-begin-the-day-with-prayer", filename: "11-begin-the-day-with-prayer", title: "Begin the Day with Prayer", subtitle: "", number: 9),
            BookChapter(id: "12-prayer-and-devotion-united", filename: "12-prayer-and-devotion-united", title: "Prayer and Devotion United", subtitle: "", number: 10),
            BookChapter(id: "13-an-example-of-devotion", filename: "13-an-example-of-devotion", title: "An Example of Devotion", subtitle: "", number: 11),
            BookChapter(id: "14-heart-preparation-necessary", filename: "14-heart-preparation-necessary", title: "Heart Preparation Necessary", subtitle: "", number: 12),
            BookChapter(id: "15-grace-from-the-heart-rather-than-the-hea", filename: "15-grace-from-the-heart-rather-than-the-hea", title: "Grace from the Heart Rather than the Head", subtitle: "", number: 13),
            BookChapter(id: "16-unction-the-mark-of-true-preaching", filename: "16-unction-the-mark-of-true-preaching", title: "Unction, the Mark of True Preaching", subtitle: "", number: 14),
            BookChapter(id: "17-unction-and-the-word-of-god", filename: "17-unction-and-the-word-of-god", title: "Unction and the Word of God", subtitle: "", number: 15),
            BookChapter(id: "18-unction-and-the-holy-spirit", filename: "18-unction-and-the-holy-spirit", title: "Unction and the Holy Spirit", subtitle: "", number: 16),
            BookChapter(id: "19-prayer-marks-spiritual-leadership", filename: "19-prayer-marks-spiritual-leadership", title: "Prayer Marks Spiritual Leadership", subtitle: "", number: 17),
            BookChapter(id: "20-the-preachers-cry-pray-for-us", filename: "20-the-preachers-cry-pray-for-us", title: "The Preacher\u{2019}s Cry: Pray for Us", subtitle: "", number: 18),
            BookChapter(id: "21-deliberation-necessary-to-largest-result", filename: "21-deliberation-necessary-to-largest-result", title: "Deliberation Necessary to Largest Results", subtitle: "", number: 19),
            BookChapter(id: "22-a-praying-pulpit-begets-a-praying-pew", filename: "22-a-praying-pulpit-begets-a-praying-pew", title: "A Praying Pulpit Begets a Praying Pew", subtitle: "", number: 20),
        ],
        chapterLabel: "Chapter",
        numberStyle: .arabic
    )

    // MARK: - Holy in Christ (Andrew Murray)

    static let holyInChrist = Book(
        id: "holyInChrist",
        title: "Holy in Christ",
        subtitle: "Thoughts on the Calling of God\u{2019}s Children to be Holy as He is Holy",
        author: "Andrew Murray",
        edition: nil,
        icon: "sun.max.fill",
        iconColor: .rrSuccess,
        subdirectory: "HolyInChrist",
        headerLinesToSkip: 4,
        chapters: [
            BookChapter(id: "01-preface", filename: "01-preface", title: "Preface", subtitle: "", number: nil),
            BookChapter(id: "02-day-02-gods-call-to-holiness", filename: "02-day-02-gods-call-to-holiness", title: "God\u{2019}s Call to Holiness", subtitle: "", number: 1),
            BookChapter(id: "03-day-03-gods-provision-for-holiness", filename: "03-day-03-gods-provision-for-holiness", title: "God\u{2019}s Provision for Holiness", subtitle: "", number: 2),
            BookChapter(id: "04-day-04-holiness-and-creation", filename: "04-day-04-holiness-and-creation", title: "Holiness and Creation", subtitle: "", number: 3),
            BookChapter(id: "05-day-05-holiness-and-revelation", filename: "05-day-05-holiness-and-revelation", title: "Holiness and Revelation", subtitle: "", number: 4),
            BookChapter(id: "06-day-06-holiness-and-redemption", filename: "06-day-06-holiness-and-redemption", title: "Holiness and Redemption", subtitle: "", number: 5),
            BookChapter(id: "07-day-07-holiness-and-glory", filename: "07-day-07-holiness-and-glory", title: "Holiness and Glory", subtitle: "", number: 6),
            BookChapter(id: "08-day-08-holiness-and-obedience", filename: "08-day-08-holiness-and-obedience", title: "Holiness and Obedience", subtitle: "", number: 7),
            BookChapter(id: "09-day-09-holiness-and-indwelling", filename: "09-day-09-holiness-and-indwelling", title: "Holiness and Indwelling", subtitle: "", number: 8),
            BookChapter(id: "10-day-10-holiness-and-mediation", filename: "10-day-10-holiness-and-mediation", title: "Holiness and Mediation", subtitle: "", number: 9),
            BookChapter(id: "11-day-11-holiness-and-separation", filename: "11-day-11-holiness-and-separation", title: "Holiness and Separation", subtitle: "", number: 10),
            BookChapter(id: "12-day-12-the-holy-one-of-israel", filename: "12-day-12-the-holy-one-of-israel", title: "The Holy One of Israel", subtitle: "", number: 11),
            BookChapter(id: "13-day-13-the-thrice-holy-one", filename: "13-day-13-the-thrice-holy-one", title: "The Thrice Holy One", subtitle: "", number: 12),
            BookChapter(id: "14-day-14-holiness-and-humility", filename: "14-day-14-holiness-and-humility", title: "Holiness and Humility", subtitle: "", number: 13),
            BookChapter(id: "15-day-15-the-holy-one-of-god", filename: "15-day-15-the-holy-one-of-god", title: "The Holy One of God", subtitle: "", number: 14),
            BookChapter(id: "16-day-16-the-holy-spirit", filename: "16-day-16-the-holy-spirit", title: "The Holy Spirit", subtitle: "", number: 15),
            BookChapter(id: "17-day-17-holiness-and-truth", filename: "17-day-17-holiness-and-truth", title: "Holiness and Truth", subtitle: "", number: 16),
            BookChapter(id: "18-day-18-holiness-and-crucifixion", filename: "18-day-18-holiness-and-crucifixion", title: "Holiness and Crucifixion", subtitle: "", number: 17),
            BookChapter(id: "19-day-19-holiness-and-faith", filename: "19-day-19-holiness-and-faith", title: "Holiness and Faith", subtitle: "", number: 18),
            BookChapter(id: "20-day-20-holiness-and-resurrection", filename: "20-day-20-holiness-and-resurrection", title: "Holiness and Resurrection", subtitle: "", number: 19),
            BookChapter(id: "21-day-21-holiness-and-liberty", filename: "21-day-21-holiness-and-liberty", title: "Holiness and Liberty", subtitle: "", number: 20),
            BookChapter(id: "22-day-22-holiness-and-happiness", filename: "22-day-22-holiness-and-happiness", title: "Holiness and Happiness", subtitle: "", number: 21),
            BookChapter(id: "23-day-23-in-christ-our-sanctification", filename: "23-day-23-in-christ-our-sanctification", title: "In Christ our Sanctification", subtitle: "", number: 22),
            BookChapter(id: "24-day-24-holiness-and-the-body", filename: "24-day-24-holiness-and-the-body", title: "Holiness and the Body", subtitle: "", number: 23),
            BookChapter(id: "25-day-25-holiness-and-cleansing", filename: "25-day-25-holiness-and-cleansing", title: "Holiness and Cleansing", subtitle: "", number: 24),
            BookChapter(id: "26-day-26-holy-and-blameless", filename: "26-day-26-holy-and-blameless", title: "Holy and Blameless", subtitle: "", number: 25),
            BookChapter(id: "27-day-27-holiness-and-the-will-of-god", filename: "27-day-27-holiness-and-the-will-of-god", title: "Holiness and the Will of God", subtitle: "", number: 26),
            BookChapter(id: "28-day-28-holiness-and-service", filename: "28-day-28-holiness-and-service", title: "Holiness and Service", subtitle: "", number: 27),
            BookChapter(id: "29-day-29-the-way-into-the-holiest", filename: "29-day-29-the-way-into-the-holiest", title: "The Way into the Holiest", subtitle: "", number: 28),
            BookChapter(id: "30-day-30-holiness-and-chastisement", filename: "30-day-30-holiness-and-chastisement", title: "Holiness and Chastisement", subtitle: "", number: 29),
            BookChapter(id: "31-day-31-the-unction-from-the-holy-one", filename: "31-day-31-the-unction-from-the-holy-one", title: "The Unction from the Holy One", subtitle: "", number: 30),
            BookChapter(id: "32-day-32-holiness-and-heaven", filename: "32-day-32-holiness-and-heaven", title: "Holiness and Heaven", subtitle: "", number: 31),
            BookChapter(id: "33-notes", filename: "33-notes", title: "Notes", subtitle: "", number: nil),
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
        imitationOfChrist,
        practicePresenceOfGod,
        pursuitOfGod,
        graceAbounding,
        powerThroughPrayer,
        holyInChrist,
    ]
}
