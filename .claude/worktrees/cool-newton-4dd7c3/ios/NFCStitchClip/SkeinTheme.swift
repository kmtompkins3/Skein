import SwiftUI

// MARK: — Skein colour palette
extension Color {
    static let skeinCream      = Color(red: 0.980, green: 0.965, blue: 0.941) // #FAF6F0
    static let skeinCream2     = Color(red: 0.949, green: 0.929, blue: 0.894) // #F2EDE4
    static let skeinCharcoal   = Color(red: 0.102, green: 0.102, blue: 0.102) // #1A1A1A
    static let skeinInk        = Color(red: 0.227, green: 0.208, blue: 0.180) // #3A352E
    static let skeinMuted      = Color(red: 0.478, green: 0.439, blue: 0.396) // #7A7065
    static let skeinHairline   = Color(red: 0.878, green: 0.851, blue: 0.796) // #E0D9CB
    static let skeinTangerine  = Color(red: 1.000, green: 0.420, blue: 0.208) // #FF6B35
    static let skeinMint       = Color(red: 0.616, green: 0.827, blue: 0.769) // #9DD3C4
    static let skeinPink       = Color(red: 1.000, green: 0.239, blue: 0.498) // #FF3D7F
    static let skeinChampagne  = Color(red: 0.831, green: 0.635, blue: 0.298) // #D4A24C
}

// MARK: — Yarn-texture thumbnail
struct YarnThumbnail: View {
    var size:  CGFloat = 56
    var color: Color   = .skeinMint
    var label: String? = nil

    var body: some View {
        ZStack {
            color
            // Diagonal stripe overlay
            Canvas { ctx, sz in
                let stripe: CGFloat = 3
                let gap:    CGFloat = 6
                var x: CGFloat = -sz.height
                while x < sz.width + sz.height {
                    var path = Path()
                    path.move(to:    CGPoint(x: x,          y: 0))
                    path.addLine(to: CGPoint(x: x + stripe, y: 0))
                    path.addLine(to: CGPoint(x: x + stripe + sz.height, y: sz.height))
                    path.addLine(to: CGPoint(x: x +          sz.height, y: sz.height))
                    path.closeSubpath()
                    ctx.fill(path, with: .color(.black.opacity(0.08)))
                    x += gap
                }
            }
            if let label {
                Text(label)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.55))
                    .kerning(0.5)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: — Stat pill
struct StatPill: View {
    let key:   String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(key)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.skeinMuted)
                .kerning(1.5)
            Text(value)
                .font(Font.custom("Helvetica Neue", size: 20).weight(.semibold))
                .foregroundStyle(Color.skeinCharcoal)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.skeinCream2)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: — Primary CTA button
struct SkeinButton: View {
    let label:  String
    var icon:   String? = nil
    var style:  SkeinButtonStyle = .tangerine
    let action: () -> Void

    enum SkeinButtonStyle { case tangerine, charcoal }

    var bg: Color { style == .tangerine ? .skeinTangerine : .skeinCharcoal }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon).font(.system(size: 16, weight: .medium)) }
                Text(label)
                    .font(Font.custom("Helvetica Neue", size: 15).weight(.semibold))
            }
            .foregroundStyle(Color.skeinCream)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(bg)
            .clipShape(Capsule())
            .shadow(color: style == .tangerine ? Color.skeinTangerine.opacity(0.35) : .clear, radius: 12, y: 6)
        }
    }
}

// MARK: — Tag number badge
struct TagNumberBadge: View {
    let number: Int
    var color: Color = .skeinTangerine

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.skeinCream2)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(color, lineWidth: 1.5)
                )
            Text(String(format: "%02d", number))
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .kerning(0.5)
        }
        .frame(width: 32, height: 32)
    }
}
