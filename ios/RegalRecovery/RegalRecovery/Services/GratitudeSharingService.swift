import UIKit

// MARK: - Gratitude Sharing Service

/// Generates shareable text and styled images for gratitude entries.
/// Privacy rule: shared content NEVER includes mood, category tags, or photo paths.
struct GratitudeSharingService {

    // MARK: - Share Text (Single Item)

    /// Returns plain text for a single gratitude item.
    /// Privacy: only the gratitude text is included — no mood, category, or photo.
    static func shareText(for item: GratitudeItem) -> String {
        item.text
    }

    // MARK: - Share Text (Full Entry)

    /// Returns a numbered list of all items with a date header.
    /// Privacy: only date + gratitude texts are included — no mood, category, or photo.
    static func shareText(for entry: RRGratitudeEntry) -> String {
        let dateString = entry.date.formatted(date: .long, time: .omitted)
        var lines = ["Gratitude \u{2014} \(dateString)", ""]

        for (index, item) in entry.items.sorted(by: { $0.sortOrder < $1.sortOrder }).enumerated() {
            lines.append("\(index + 1). \(item.text)")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Styled Image

    /// Renders a shareable card image using UIGraphicsImageRenderer.
    ///
    /// Layout (top-to-bottom):
    /// - Gradient background
    /// - Gratitude text (centered, serif font)
    /// - Date (right-aligned)
    /// - Optional scripture verse
    /// - "Regal Recovery" watermark at bottom center
    static func styledImage(text: String, date: Date, scripture: String?) -> UIImage {
        let cardWidth: CGFloat = 600
        let horizontalPadding: CGFloat = 40
        let textAreaWidth = cardWidth - horizontalPadding * 2

        // Fonts
        let mainFont = UIFont(name: "Georgia", size: 22) ?? UIFont.systemFont(ofSize: 22, weight: .regular)
        let dateFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let scriptureFont = UIFont.italicSystemFont(ofSize: 16)
        let watermarkFont = UIFont.systemFont(ofSize: 12, weight: .light)

        // Paragraph style for centered text
        let centeredParagraph = NSMutableParagraphStyle()
        centeredParagraph.alignment = .center
        centeredParagraph.lineSpacing = 6

        let rightParagraph = NSMutableParagraphStyle()
        rightParagraph.alignment = .right

        // Pre-calculate text sizes to determine card height
        let mainAttributes: [NSAttributedString.Key: Any] = [
            .font: mainFont,
            .foregroundColor: UIColor(red: 0.20, green: 0.15, blue: 0.10, alpha: 1.0),
            .paragraphStyle: centeredParagraph
        ]

        let mainTextRect = (text as NSString).boundingRect(
            with: CGSize(width: textAreaWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: mainAttributes,
            context: nil
        )

        let dateString = "\u{2014} \(date.formatted(date: .long, time: .omitted))"
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: UIColor(red: 0.40, green: 0.35, blue: 0.30, alpha: 1.0),
            .paragraphStyle: rightParagraph
        ]

        let dateTextRect = (dateString as NSString).boundingRect(
            with: CGSize(width: textAreaWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: dateAttributes,
            context: nil
        )

        var scriptureHeight: CGFloat = 0
        var scriptureAttributes: [NSAttributedString.Key: Any] = [:]
        if let scripture, !scripture.isEmpty {
            scriptureAttributes = [
                .font: scriptureFont,
                .foregroundColor: UIColor(red: 0.35, green: 0.30, blue: 0.25, alpha: 0.8),
                .paragraphStyle: centeredParagraph
            ]

            let scriptureRect = (scripture as NSString).boundingRect(
                with: CGSize(width: textAreaWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: scriptureAttributes,
                context: nil
            )
            scriptureHeight = scriptureRect.height + 24 // spacing above scripture
        }

        let watermarkAttributes: [NSAttributedString.Key: Any] = [
            .font: watermarkFont,
            .foregroundColor: UIColor(red: 0.50, green: 0.45, blue: 0.40, alpha: 0.6),
            .paragraphStyle: centeredParagraph
        ]

        // Total card height
        let topPadding: CGFloat = 48
        let dateSpacing: CGFloat = 20
        let bottomPadding: CGFloat = 40
        let watermarkSpacing: CGFloat = 24
        let watermarkHeight: CGFloat = 20

        let cardHeight = topPadding
            + mainTextRect.height
            + dateSpacing
            + dateTextRect.height
            + scriptureHeight
            + watermarkSpacing
            + watermarkHeight
            + bottomPadding

        let size = CGSize(width: cardWidth, height: cardHeight)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let cgContext = context.cgContext

            // -- Gradient background --
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let topColor = UIColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1.0).cgColor  // warm cream
            let bottomColor = UIColor(red: 0.92, green: 0.88, blue: 0.82, alpha: 1.0).cgColor // warm tan
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: [topColor, bottomColor] as CFArray, locations: [0, 1]) {
                cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: cardWidth / 2, y: 0),
                    end: CGPoint(x: cardWidth / 2, y: cardHeight),
                    options: []
                )
            }

            // -- Rounded rectangle clip for subtle border --
            let borderRect = CGRect(x: 0, y: 0, width: cardWidth, height: cardHeight)
            let borderPath = UIBezierPath(roundedRect: borderRect.insetBy(dx: 1, dy: 1), cornerRadius: 16)
            UIColor(red: 0.80, green: 0.75, blue: 0.68, alpha: 0.4).setStroke()
            borderPath.lineWidth = 1.5
            borderPath.stroke()

            // -- Main text --
            var yOffset = topPadding
            let mainDrawRect = CGRect(x: horizontalPadding, y: yOffset, width: textAreaWidth, height: mainTextRect.height)
            (text as NSString).draw(in: mainDrawRect, withAttributes: mainAttributes)
            yOffset += mainTextRect.height + dateSpacing

            // -- Date --
            let dateDrawRect = CGRect(x: horizontalPadding, y: yOffset, width: textAreaWidth, height: dateTextRect.height)
            (dateString as NSString).draw(in: dateDrawRect, withAttributes: dateAttributes)
            yOffset += dateTextRect.height

            // -- Scripture --
            if let scripture, !scripture.isEmpty {
                yOffset += 24
                let scriptureDrawRect = CGRect(x: horizontalPadding, y: yOffset, width: textAreaWidth, height: scriptureHeight - 24)
                (scripture as NSString).draw(in: scriptureDrawRect, withAttributes: scriptureAttributes)
                yOffset += scriptureHeight - 24
            }

            // -- Watermark --
            yOffset += watermarkSpacing
            let watermarkText = "Regal Recovery"
            let watermarkDrawRect = CGRect(x: horizontalPadding, y: yOffset, width: textAreaWidth, height: watermarkHeight)
            (watermarkText as NSString).draw(in: watermarkDrawRect, withAttributes: watermarkAttributes)
        }
    }
}
