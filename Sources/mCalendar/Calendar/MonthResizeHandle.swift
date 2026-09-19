import SwiftUI
import AppKit

/// The grip under the grid: drag down/up to open or close months, like pulling
/// the bottom edge of the grid -- the grip on the Notification Center calendar
/// widget.
struct MonthResizeHandle: View {
    @Binding var monthCount: Int
    /// The most months that fit on screen.
    let maxMonths: Int
    /// How far to drag for one month, so the grip stays under the pointer.
    let monthHeight: CGFloat

    @State private var dragStartCount: Int?
    @State private var dragStartY: CGFloat?
    @State private var hovered = false

    var body: some View {
        Capsule()
            .fill(Color.primary.opacity(hovered ? 0.28 : 0.15))
            .frame(width: 36, height: 5)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onHover { hovering in
                hovered = hovering
                if hovering { NSCursor.resizeUpDown.push() } else { NSCursor.pop() }
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { _ in dragChanged() }
                    .onEnded { _ in
                        dragStartY = nil
                        dragStartCount = nil
                    }
            )
    }

    private func dragChanged() {
        // Measure against the screen, not the view: changing the month count
        // resizes the popover and moves this handle, so a view-local
        // translation would feed back on itself and run away to the limits
        // after one small drag.
        let y = NSEvent.mouseLocation.y
        guard let startY = dragStartY, let startCount = dragStartCount else {
            dragStartY = y
            dragStartCount = monthCount
            return
        }
        // Screen y grows upward, so dragging down opens more months.
        let months = Int(((startY - y) / monthHeight).rounded())
        let newCount = min(maxMonths, max(1, startCount + months))
        if newCount != monthCount { monthCount = newCount }
    }
}
