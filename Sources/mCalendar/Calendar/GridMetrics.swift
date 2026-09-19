import CoreGraphics

/// Day-cell size, and the popover sizes that follow from it.
///
/// The plain grid keeps its compact 24pt tiles; lunar dates and holiday dots
/// each need extra room, so the cells (and the popover) grow only while those
/// are switched on.
struct GridMetrics {
    let cellWidth: CGFloat
    let cellHeight: CGFloat

    init(lunar: Bool, holidays: Bool) {
        cellWidth = lunar ? 34 : holidays ? 28 : 24
        // Holidays add a dot band above the text and an equal one below it.
        cellHeight = lunar ? (holidays ? 43 : 33) : holidays ? 35 : 24
    }

    /// The vertical gap between week rows.
    static let rowSpacing: CGFloat = 5

    /// Wide enough for the gutter, the padding and seven columns with a little
    /// air around each tile; 225 for the plain grid.
    var popoverWidth: CGFloat { (39 + 7 * (cellWidth + 2.6)).rounded() }

    /// Roughly how much taller the popover gets per added month: 4–5 week rows
    /// plus the spacing between them.
    var monthHeight: CGFloat { (cellHeight + Self.rowSpacing) * 4.3 }
}
