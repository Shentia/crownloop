import SwiftUI

/// RingView: draws a circular ring and a marker capsule positioned at `ringAngle`.
/// The marker is placed at the top and the whole marker is rotated by `ringAngle` so
/// 0 degrees corresponds to 12 o'clock and increases clockwise to match common UI.
struct RingView: View {
    var ringAngle: Double
    var diameter: CGFloat
    var lineWidth: CGFloat = 12
    var markerWidth: CGFloat = 6
    var markerLength: CGFloat = 18
    var skin: GameEngine.RingSkin = .neonCyan
    /// Scale applied for hit pulse (1.0 = normal)
    var scale: CGFloat = 1.0
    /// Pulse overlay toggle (fades out)
    var pulse: Bool = false

    init(ringAngle: Double, diameter: CGFloat, lineWidth: CGFloat = 12, skin: GameEngine.RingSkin = .neonCyan, scale: CGFloat = 1.0, pulse: Bool = false) {
        self.ringAngle = ringAngle
        self.diameter = diameter
        self.lineWidth = lineWidth
        self.skin = skin
        self.scale = scale
        self.pulse = pulse
    }

    public var body: some View {
        let radius = diameter / 2
        let c = Color(red: skin.ringColor.r, green: skin.ringColor.g, blue: skin.ringColor.b)
        ZStack {
            Circle()
                .stroke(c.opacity(0.95), lineWidth: lineWidth)
                .frame(width: diameter, height: diameter)

            // Marker placed at top and rotated by ringAngle so it moves around the ring.
            Capsule()
                .fill(c)
                .frame(width: markerWidth, height: markerLength)
                .offset(y: -radius + (markerLength / 2))
                .rotationEffect(Angle(degrees: ringAngle))

            // Accessibility: the marker is decorative; top-level PlayAreaView will provide combined labels.
            .accessibilityHidden(true)

            // Pulse overlay circle
            Circle()
                .stroke(c.opacity(pulse ? 0.25 : 0.0), lineWidth: lineWidth)
                .frame(width: diameter * (pulse ? 1.12 : 1.0), height: diameter * (pulse ? 1.12 : 1.0))
                .scaleEffect(pulse ? 1.02 : 1.0)
                .animation(.easeOut(duration: 0.28), value: pulse)
            .accessibilityHidden(true)
        }
        .scaleEffect(scale)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: scale)
    }
}

/// GateView: draws a short arc (segmentDegrees long) centered at `gateAngle`.
/// Includes a subtle glow/shadow for visibility on dark backgrounds.
struct GateView: View {
    var gateAngle: Double
    var diameter: CGFloat
    var segmentDegrees: Double = 20
    var strokeColor: Color = .red
    var strokeWidth: CGFloat = 14
    var skin: GameEngine.RingSkin = .neonCyan
    /// Progress 0..1 representing remaining time fraction; 1 == full, 0 == expired
    var progress: CGFloat = 1.0

    init(gateAngle: Double, diameter: CGFloat, segmentDegrees: Double = 20, skin: GameEngine.RingSkin = .neonCyan, progress: CGFloat = 1.0) {
        self.gateAngle = gateAngle
        self.diameter = diameter
        self.segmentDegrees = segmentDegrees
        self.skin = skin
        self.progress = progress
    }

    public var body: some View {
        let fraction = CGFloat(segmentDegrees / 360)
        let rotation = Angle(degrees: gateAngle - (segmentDegrees / 2) - 90)
        let c = Color(red: skin.ringColor.r, green: skin.ringColor.g, blue: skin.ringColor.b)

        ZStack {
            // glow layer: scale and blur tied to progress
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(c.opacity(Double(0.5 * progress)), style: StrokeStyle(lineWidth: strokeWidth * 1.8, lineCap: .round))
                .frame(width: diameter, height: diameter)
                .rotationEffect(rotation)
                .blur(radius: 6 * (0.6 + 0.4 * progress))
            .accessibilityHidden(true)

            // Main gate stroke
            Circle()
                .trim(from: 0, to: fraction * progress)
                .stroke(c, style: StrokeStyle(lineWidth: strokeWidth * (0.8 + 0.4 * progress), lineCap: .round))
                .frame(width: diameter * (0.75 + 0.25 * progress), height: diameter * (0.75 + 0.25 * progress))
                .rotationEffect(rotation)
                .animation(.linear(duration: Double(max(0.01, 0.01 + (1.0 - Double(progress)) * 0.0))), value: progress)
            .accessibilityHidden(true)
        }
        .scaleEffect(0.85 + 0.15 * progress)
        .animation(.linear(duration: 0.12), value: progress)
        // Gate visuals are decorative; PlayAreaView will provide combined accessibility description.
        .accessibilityElement(children: .ignore)
    }
}

// MARK: - Previews

struct RingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            RingView(ringAngle: 45, diameter: 150)
            GateView(gateAngle: 120, diameter: 150)
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}
