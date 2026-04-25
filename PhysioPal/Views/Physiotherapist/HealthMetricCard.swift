import SwiftUI

struct HealthMetricCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    let progress: Double?

    init(icon: String, label: String, value: String, color: Color, progress: Double? = nil) {
        self.icon = icon
        self.label = label
        self.value = value
        self.color = color
        self.progress = progress
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(label)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)

                Spacer()
            }

            Text(value)
                .font(AppFonts.heading)
                .foregroundStyle(AppColors.textPrimary)

            if let progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.surface)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: geo.size.width * min(max(progress, 0), 1), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(AppLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(AppColors.cardWhite)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
    }
}
