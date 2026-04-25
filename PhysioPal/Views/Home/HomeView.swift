import Combine
import SwiftUI

struct HomeView: View {
    @StateObject private var sessionStore = SessionStore.shared
    @State private var healthMetrics: HealthReadiness?
    @State private var isLoadingHealth = true
    @State private var appeared = false

    private let patient = PatientProfile.mock

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 8)

                    greetingHeader
                    readinessAndStartCard
                    healthSnapshotSection
                    myProgressSection
                    recentSessionsSection
                    achievementsSection
                    quickActionsSection

                    Spacer().frame(height: 24)
                }
                .padding(.horizontal, AppLayout.screenPadding)
            }
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: AppAnimation.screenTransition)) {
                    appeared = true
                }
            }
        }
        .task {
            isLoadingHealth = true
            healthMetrics = await HealthKitManager.shared.assessReadiness()
            isLoadingHealth = false
        }
    }

    // MARK: - Greeting

    private var greetingHeader: some View {
        HStack(spacing: 16) {
            Image(systemName: patient.avatarSystemImage)
                .font(.system(size: 50))
                .foregroundStyle(AppColors.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(greetingText), \(patient.name)")
                    .font(AppFonts.heading)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Week \(patient.weeksSinceStart) of recovery")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)

                if let metrics = healthMetrics {
                    HStack(spacing: 6) {
                        Image(systemName: metrics.level.iconName)
                            .font(.system(size: 14))
                            .foregroundStyle(readinessColor(metrics.level))
                        Text(metrics.level.displayLabel)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(readinessColor(metrics.level))
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()
        }
    }

    // MARK: - Readiness + Start

    private var readinessAndStartCard: some View {
        VStack(spacing: 16) {
            if let metrics = healthMetrics {
                HStack(spacing: 12) {
                    metricPill(icon: "bed.double.fill", value: metrics.formattedSleep ?? "—")
                    metricPill(icon: "heart.fill", value: metrics.formattedHeartRate ?? "—")
                    metricPill(icon: "flame.fill", value: metrics.formattedEnergy ?? "—")
                    metricPill(icon: "figure.walk", value: metrics.formattedSteps ?? "—")
                }
            } else if isLoadingHealth {
                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppColors.surface)
                            .frame(height: 48)
                    }
                }
                .redacted(reason: .placeholder)
            }

            NavigationLink {
                AppFlowView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 22))
                    Text("Start Today's Session")
                        .font(AppFonts.button)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AppLayout.buttonHeight)
                .background(AppColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                .shadow(color: AppColors.primary.opacity(0.3), radius: 8, y: 4)
            }
            .simultaneousGesture(TapGesture().onEnded {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            })
            .accessibilityLabel("Start today's exercise session")
        }
        .padding(AppLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(AppColors.cardWhite)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
    }

    private func metricPill(icon: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.primary)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppColors.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Health Snapshot

    private var healthSnapshotSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("My Health Today")
                    .font(AppFonts.heading)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                if let metrics = healthMetrics {
                    Text(timeAgo(metrics.assessedAt))
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            if let metrics = healthMetrics {
                healthRow(icon: "bed.double.fill", label: "Sleep last night", value: metrics.formattedSleep ?? "No data", color: sleepColor(metrics.sleepHours), detail: sleepDetail(metrics.sleepHours))

                healthRow(icon: "heart.fill", label: "Resting heart rate", value: metrics.formattedHeartRate ?? "No data", color: hrColor(metrics.restingHeartRate), detail: hrDetail(metrics.restingHeartRate))

                healthRow(icon: "flame.fill", label: "Active energy", value: metrics.formattedEnergy ?? "No data", color: energyColor(metrics.activeEnergyKcal), detail: nil)

                healthRow(icon: "figure.walk", label: "Steps today", value: metrics.formattedSteps ?? "No data", color: stepsColor(metrics.stepCount), detail: nil)

                if let hrv = metrics.formattedHRV {
                    healthRow(icon: "waveform.path.ecg", label: "Heart rate variability", value: hrv, color: AppColors.primary, detail: "Measures recovery capacity")
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 80)
            }
        }
    }

    private func healthRow(icon: String, label: String, value: String, color: Color, detail: String?) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
                .frame(width: 42, height: 42)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                HStack(spacing: 8) {
                    Text(value)
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)
                    if let detail {
                        Text("· \(detail)")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardWhite)
                .shadow(color: AppShadow.color, radius: 6, x: 0, y: 2)
        )
    }

    // MARK: - My Progress

    private var myProgressSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("My Progress")
                .font(AppFonts.heading)
                .foregroundStyle(AppColors.textPrimary)

            HStack(spacing: 12) {
                progressStat(
                    icon: "flame.fill",
                    value: "\(streakDays)",
                    label: "Day Streak",
                    color: AppColors.secondary
                )
                progressStat(
                    icon: "checkmark.circle.fill",
                    value: "\(sessionStore.totalSessionCount)",
                    label: "Sessions",
                    color: AppColors.primary
                )
                progressStat(
                    icon: "target",
                    value: sessionStore.totalSessionCount > 0 ? String(format: "%.0f%%", sessionStore.averageAccuracy) : "—",
                    label: "Accuracy",
                    color: AppColors.success
                )
            }

            if sessionStore.totalSessionCount >= 2 {
                HStack(spacing: 10) {
                    Image(systemName: sessionStore.trendIcon)
                        .font(.system(size: 18))
                        .foregroundStyle(sessionStore.trendColor)
                    Text("Form trend: \(sessionStore.accuracyTrend)")
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(sessionStore.trendColor.opacity(0.08))
                )
            }
        }
    }

    private func progressStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)

            Text(value)
                .font(AppFonts.heading)
                .foregroundStyle(AppColors.textPrimary)

            Text(label)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(AppColors.cardWhite)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
    }

    // MARK: - Recent Sessions

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Sessions")
                .font(AppFonts.heading)
                .foregroundStyle(AppColors.textPrimary)

            if sessionStore.sessions.isEmpty {
                emptySessionCard
            } else {
                ForEach(sessionStore.sessions.prefix(3)) { session in
                    NavigationLink {
                        PTSessionDetailView(session: session)
                    } label: {
                        sessionRow(session)
                    }
                }
            }
        }
    }

    private var emptySessionCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 36))
                .foregroundStyle(AppColors.textSecondary.opacity(0.4))

            Text("No sessions yet — tap Start to begin!")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(AppColors.surface)
        )
    }

    private func sessionRow(_ session: ExerciseSession) -> some View {
        HStack(spacing: 14) {
            VStack(spacing: 4) {
                Text(shortDate(session.date))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primary)
                Text(shortDay(session.date))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(session.exercises.count) exercises · \(session.formattedDuration) min")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)

                HStack(spacing: 6) {
                    accuracyBadge(session.overallAccuracy)
                    Text(String(format: "%.0f%% form accuracy", session.overallAccuracy))
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary.opacity(0.4))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardWhite)
                .shadow(color: AppShadow.color, radius: 6, x: 0, y: 2)
        )
    }

    private func accuracyBadge(_ accuracy: Double) -> some View {
        Circle()
            .fill(accuracy >= 85 ? AppColors.success : accuracy >= 70 ? AppColors.accent : AppColors.secondary)
            .frame(width: 10, height: 10)
    }

    // MARK: - Achievements

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Achievements")
                .font(AppFonts.heading)
                .foregroundStyle(AppColors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    achievementBadge(
                        icon: "star.fill",
                        title: "First Session",
                        earned: sessionStore.totalSessionCount >= 1,
                        color: AppColors.accent
                    )
                    achievementBadge(
                        icon: "flame.fill",
                        title: "3-Day Streak",
                        earned: streakDays >= 3,
                        color: AppColors.secondary
                    )
                    achievementBadge(
                        icon: "target",
                        title: "Perfect Form",
                        earned: sessionStore.sessions.contains { $0.overallAccuracy >= 95 },
                        color: AppColors.success
                    )
                    achievementBadge(
                        icon: "trophy.fill",
                        title: "Week Warrior",
                        earned: sessionStore.sessionsThisWeek >= 5,
                        color: AppColors.primary
                    )
                    achievementBadge(
                        icon: "heart.circle.fill",
                        title: "10 Sessions",
                        earned: sessionStore.totalSessionCount >= 10,
                        color: Color(hex: "9B59B6")
                    )
                }
            }
        }
    }

    private func achievementBadge(icon: String, title: String, earned: Bool, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(earned ? color.opacity(0.15) : AppColors.surface)
                    .frame(width: 60, height: 60)

                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundStyle(earned ? color : AppColors.textSecondary.opacity(0.3))
            }

            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(earned ? AppColors.textPrimary : AppColors.textSecondary.opacity(0.5))
                .multilineTextAlignment(.center)
                .frame(width: 72)
        }
        .opacity(earned ? 1 : 0.6)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick Actions")
                .font(AppFonts.heading)
                .foregroundStyle(AppColors.textPrimary)

            NavigationLink {
                EscalationView { }
            } label: {
                quickActionRow(
                    icon: "phone.fill",
                    title: "Call My Physiotherapist",
                    subtitle: "Get help or ask a question",
                    color: AppColors.secondary
                )
            }

            NavigationLink {
                PatientHealthDetailView(metrics: healthMetrics)
            } label: {
                quickActionRow(
                    icon: "heart.text.clipboard.fill",
                    title: "View Full Health Report",
                    subtitle: "See all your health data in detail",
                    color: AppColors.primary
                )
            }
        }
    }

    private func quickActionRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary.opacity(0.4))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.cardWhite)
                .shadow(color: AppShadow.color, radius: 6, x: 0, y: 2)
        )
    }

    // MARK: - Helpers

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var streakDays: Int {
        var streak = 0
        let calendar = Calendar.current
        var checkDate = calendar.startOfDay(for: Date())
        let sessionDates = Set(sessionStore.sessions.map { calendar.startOfDay(for: $0.date) })

        while sessionDates.contains(checkDate) || (streak == 0 && calendar.isDateInToday(checkDate)) {
            if sessionDates.contains(checkDate) {
                streak += 1
            } else if streak == 0 {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                continue
            }
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        return streak
    }

    private func readinessColor(_ level: ReadinessLevel) -> Color {
        switch level {
        case .normal: return AppColors.success
        case .moderate: return AppColors.accent
        case .low: return AppColors.secondary
        }
    }

    private func sleepColor(_ hours: Double?) -> Color {
        guard let h = hours else { return AppColors.textSecondary }
        return h < HealthThresholds.lowSleepHours ? AppColors.secondary : AppColors.primary
    }

    private func sleepDetail(_ hours: Double?) -> String? {
        guard let h = hours else { return nil }
        if h >= 7 { return "Well rested" }
        if h >= 5 { return "Could be better" }
        return "Low — take it easy"
    }

    private func hrColor(_ hr: Double?) -> Color {
        guard let hr = hr else { return AppColors.textSecondary }
        return hr > HealthThresholds.elevatedHeartRate ? AppColors.secondary : AppColors.success
    }

    private func hrDetail(_ hr: Double?) -> String? {
        guard let hr = hr else { return nil }
        if hr <= 70 { return "Excellent" }
        if hr <= 85 { return "Normal" }
        return "Elevated"
    }

    private func energyColor(_ kcal: Double?) -> Color {
        guard let e = kcal else { return AppColors.textSecondary }
        return e < HealthThresholds.lowEnergyKcal ? AppColors.secondary : AppColors.accent
    }

    private func stepsColor(_ steps: Double?) -> Color {
        guard let s = steps else { return AppColors.textSecondary }
        return s < 2000 ? AppColors.secondary : AppColors.success
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "Just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        return "\(seconds / 3600)h ago"
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func shortDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
}

// MARK: - Patient Health Detail

struct PatientHealthDetailView: View {
    let metrics: HealthReadiness?

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 8)

                    if let metrics {
                        readinessSection(metrics)
                        detailedMetrics(metrics)
                    } else {
                        noDataView
                    }

                    privacyNote
                    Spacer().frame(height: 24)
                }
                .padding(.horizontal, AppLayout.screenPadding)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("My Health Report")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
    }

    private func readinessSection(_ metrics: HealthReadiness) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: metrics.level.iconName)
                    .font(.system(size: 36))
                    .foregroundStyle(readinessColor(metrics.level))
                    .symbolEffect(.pulse, options: .repeating.speed(0.5))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Readiness")
                        .font(AppFonts.heading)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(metrics.level.displayLabel)
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(readinessColor(metrics.level))
                }

                Spacer()
            }

            Text(metrics.explanation)
                .font(AppFonts.doctorsNote)
                .foregroundStyle(AppColors.textPrimary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(AppColors.cardWhite)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(readinessColor(metrics.level).opacity(0.2), lineWidth: 1.5)
        )
    }

    private func detailedMetrics(_ metrics: HealthReadiness) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Health Metrics")
                .font(AppFonts.heading)
                .foregroundStyle(AppColors.textPrimary)

            HealthMetricCard(
                icon: "bed.double.fill",
                label: "Sleep Last Night",
                value: metrics.formattedSleep ?? "No data available",
                color: AppColors.primary,
                progress: (metrics.sleepHours ?? 0) / 9.0
            )

            HealthMetricCard(
                icon: "heart.fill",
                label: "Resting Heart Rate",
                value: metrics.formattedHeartRate ?? "No data available",
                color: AppColors.success,
                progress: (metrics.restingHeartRate ?? 0) / 120.0
            )

            HealthMetricCard(
                icon: "flame.fill",
                label: "Active Energy Burned",
                value: metrics.formattedEnergy ?? "No data available",
                color: AppColors.accent,
                progress: (metrics.activeEnergyKcal ?? 0) / 300.0
            )

            HealthMetricCard(
                icon: "figure.walk",
                label: "Steps Today",
                value: metrics.formattedSteps ?? "No data available",
                color: AppColors.success,
                progress: (metrics.stepCount ?? 0) / 6000.0
            )

            if metrics.heartRateVariability != nil {
                HealthMetricCard(
                    icon: "waveform.path.ecg",
                    label: "Heart Rate Variability",
                    value: metrics.formattedHRV ?? "—",
                    color: AppColors.primary,
                    progress: (metrics.heartRateVariability ?? 0) / 60.0
                )
            }
        }
    }

    private var noDataView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textSecondary.opacity(0.4))

            Text("No health data available")
                .font(AppFonts.heading)
                .foregroundStyle(AppColors.textPrimary)

            Text("Open the Health app and grant PhysioPal permission to read your health data.")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(32)
    }

    private var privacyNote: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppColors.success)
            Text("All health data is read-only from Apple Health and never leaves your device.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .padding(AppLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(AppColors.success.opacity(0.06))
        )
    }

    private func readinessColor(_ level: ReadinessLevel) -> Color {
        switch level {
        case .normal: return AppColors.success
        case .moderate: return AppColors.accent
        case .low: return AppColors.secondary
        }
    }
}
