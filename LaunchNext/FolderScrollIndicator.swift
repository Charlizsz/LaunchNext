import AppKit

/// Native overlay scroller, visible only during interaction with overflowing content.
final class FolderScrollIndicator: NSScroller {
    override class var isCompatibleWithOverlayScrollers: Bool { true }
    weak var scrollTarget: NSView?
    private var hideWorkItem: DispatchWorkItem?
    private var generation = 0
    private var overflowing = false
    private var trackingThumb = false

    override init(frame: NSRect) {
        super.init(frame: frame)
        scrollerStyle = .overlay
        controlSize = .small
        isHidden = true
        alphaValue = 0
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
    deinit { hideWorkItem?.cancel() }

    func update(value: Double, proportion: CGFloat) {
        doubleValue = min(1, max(0, value))
        knobProportion = min(1, max(0, proportion))
        overflowing = proportion < 0.999
        isEnabled = overflowing
        if !overflowing {
            hideWorkItem?.cancel()
            generation += 1
            alphaValue = 0
            isHidden = true
        }
    }

    func flash() {
        guard overflowing else { return }
        hideWorkItem?.cancel()
        generation += 1
        let token = generation
        isHidden = false
        alphaValue = 1
        let work = DispatchWorkItem { [weak self] in
            guard let self, !self.trackingThumb, self.generation == token else { return }
            NSAnimationContext.runAnimationGroup { context in
                context.duration = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.2
                self.animator().alphaValue = 0
            } completionHandler: { [weak self] in
                guard let self, self.generation == token else { return }
                self.isHidden = true
            }
        }
        hideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: work)
    }

    override func trackKnob(with event: NSEvent) {
        trackingThumb = true
        super.trackKnob(with: event)
        trackingThumb = false
        flash()
    }

    override func scrollWheel(with event: NSEvent) {
        (scrollTarget ?? superview)?.scrollWheel(with: event)
    }
}
