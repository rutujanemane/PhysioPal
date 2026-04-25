import SwiftUI

struct PTDashboardView: View {
    @StateObject private var viewModel = PhysiotherapistDashboardViewModel()
    @State private var appeared = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            if viewModel.isLoadingHealth && viewModel.healthMetrics == nil {
                loadingState
            } else {
                dashboardContent
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Patient Dashboard")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .task {
            await viewModel.loadDashboard()
        }
    }

    private var loadingState: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.text.clipboard.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.secondary)
                .symbolEffect(.pulse, options: .repeating)

            Text("Loading patient data...")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer().frame(height: 8)

                patientHeader
                healthMetricsSection
                readinessCard
                weeklyOverview
                recentSessionsSection

                Spacer().frame(height: 24)
            }
            .padding(.horizontal, AppLayout.screenPadding)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: AppAnimation.screenTransition)) {
                    appeared = true
                }
            }
        }
        .refreshable {
            await viewModel.refreshHealth()
        }
    }

    // MARK: - Patient Header

    private var patientHeader: some View {
        HStack(spacing: 16) {
            Image(systemName: viewModel.patient.avatarSystemImage)
                .font(.system(size: 56))
                .foregroundStyle(AppColors.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.patient.name)
                    .font(AppFonts.title)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Age \(viewModel.patient.age)")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textSecondary)

                Text(viewModel.patient.condition)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(4)
            }

            Spacer()
        }
        .padding(AppLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(AppColors.cardWhite)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
    }

    // MARK: - Health Metrics

    private var healthMetricsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Today's Health Snapshot")
                    .font(AppFonts.heading)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                if let metrics = viewModel.healthMetrics {
                    Text(timeAgoString(from: metrics.assessedAt))
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            if let metrics = viewModel.healthMetrics {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    HealthMetricCard(
                        icon: "bed.double.fill",
                        label: "Sleep",
                        value: metrics.formattedSleep ?? "—",
                        color: sleepColor(metrics.sleepHours),
                        progress: (metrics.sleepHours ?? 0) / 9.0
                    )

                    HealthMetricCard(
                        icon: "heart.fill",
                        label: "Heart Rate",
                        value: metrics.formattedHeartRate ?? "—",
                        color: heartRateColor(metrics.restingHeartRate),
                        progress: heartRateProgress(metrics.restingHeartRate)
                    )

                    HealthMetricCard(
                        icon: "flame.fill",
                        label: "Active Energy",
                        value: metrics.formattedEnergy ?? "—",
                        color: energyColor(metrics.activeEnergyKcal),
                        progress: (metrics.activeEnergyKcal ?? 0) / 300.0
                    )

                    HealthMetricCard(
                        icon: "figure.walk",
                        label: "Steps",
                        value: metrics.formattedSteps ?? "—",
                        color: stepsColor(metrics.stepCount),
                        progress: (metrics.stepCount ?? 0) / 6000.0
                    )
                }

                if let hrv = metrics.formattedHRV {
                    HealthMetricCard(
                        icon: "waveform.path.ecg",
                        label: "Heart Rate Variability",
                        value: hrv,
                        color: AppColors.primary,
                        progress: (metrics.heartRateVariability ?? 0) / 60.0
                    )
                }
            } else {
                noDataCard(message: "Health data not available. Ensure the patient has granted HealthKit permissions.")
            }
        }
    }

    // MARK: - Readiness Card

    private var readinessCard: some View {
        Group {
            if let metrics = viewModel.healthMetrics {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: metrics.level.iconName)
                            .font(.system(size: 28))
                            .foregroundStyle(readinessColor(metrics.level))
                            .symbolEffect(.pulse, options: .repeating.speed(0.5))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Readiness Assessment")
                                .font(AppFonts.bodyBold)
                                .foregroundStyle(AppColors.textPrimary)
                            Text(metrics.level.displayLabel)
                                .font(AppFonts.caption)
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
        }
    }

    // MARK: - Weekly Overview

    private var weeklyOverview: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("This Week")
                .font(AppFonts.heading)
                .foregroundStyle(AppColors.textPrimary)

            HStack(spacing: 14) {
                weekStat(
                    icon: "calendar.badge.checkmark",
                    value: "\(viewModel.sessionStore.sessionsThisWeek)",
                    label: "Sessions",
                    color: AppColors.primary
                )

                weekStat(
                    icon: "target",
                    value: String(format: "%.0f%%", viewModel.sessionStore.averageAccuracy),
                    label: "Avg. Accuracy",
                    color: AppColors.success
                )

                weekStat(
                    icon: viewModel.sessionStore.trendIcon,
                    value: viewModel.sessionStore.accuracyTrend,
                    label: "Trend",
                    color: viewModel.sessionStore.trendColor
                )
            }
        }
    }

    private func weekStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)

            Text(value)
                .font(AppFonts.bodyBold)
                .foregroundStyle(AppColors.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

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

    // MARK: - Sessions

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Sessions")
                .font(AppFonts.heading)
                .foregroundStyle(AppColors.textPrimary)

            if viewModel.sessionStore.sessions.isEmpty {
                noDataCard(message: "No exercise sessions recorded yet.")
            } else {
                ForEach(viewModel.sessionStore.recentSessions) { session in
                    NavigationLink {
                        PTSessionDetailView(session: session)
                    } label: {
                        sessionCard(session)
                    }
                }
            }
        }
    }

    private func sessionCard(_ session: ExerciseSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.formattedDate)
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("\(session.formattedTime)  ·  \(session.formattedDuration) min")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Image(systemName: session.readinessLevel.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(readinessColor(session.readinessLevel))

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
            }

            HStack(spacing: 16) {
                Label("\(session.exercises.count) exercises", systemImage: "figure.strengthtraining.functional")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)

                Label("\(session.totalReps) reps", systemImage: "repeat")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            HStack(spacing: 10) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.surface)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(accuracyColor(session.overallAccuracy))
                            .frame(width: geo.size.width * session.overallAccuracy / 100, height: 8)
                    }
                }
                .frame(height: 8)

                Text(String(format: "%.0f%%", session.overallAccuracy))
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(accuracyColor(session.overallAccuracy))
                    .frame(width: 50, alignment: .trailing)
            }
        }
        .padding(AppLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(AppColors.cardWhite)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
    }

    // MARK: - Helpers

    private func noDataCard(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(AppColors.textSecondary)
            Text(message)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppLayout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(AppColors.surface)
        )
    }

    private func timeAgoString(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "Just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        return "\(seconds / 3600)h ago"
    }

    private func sleepColor(_ hours: Double?) -> Color {
        guard let h = hours else { return AppColors.textSecondary }
        return h < HealthThresholds.lowSleepHours ? AppColors.secondary : AppColors.primary
    }

    private func heartRateColor(_ hr: Double?) -> Color {
        guard let hr = hr else { return AppColors.textSecondary }
        if hr > HealthThresholds.elevatedHeartRate { return AppColors.secondary }
        if hr < 60 { return AppColors.primary }
        return AppColors.success
    }

    private func heartRateProgress(_ hr: Double?) -> Double {
        guard let hr = hr else { return 0 }
        return min(hr / 120.0, 1.0)
    }

    private func energyColor(_ kcal: Double?) -> Color {
        guard let e = kcal else { return AppColors.textSecondary }
        return e < HealthThresholds.lowEnergyKcal ? AppColors.secondary : AppColors.accent
    }

    private func stepsColor(_ steps: Double?) -> Color {
        guard let s = steps else { return AppColors.textSecondary }
        return s < 2000 ? AppColors.secondary : AppColors.success
    }

    private func readinessColor(_ level: ReadinessLevel) -> Color {
        switch level {
        case .normal: return AppColors.success
        case .moderate: return AppColors.accent
        case .low: return AppColors.secondary
        }
    }

    private func accuracyColor(_ accuracy: Double) -> Color {
        if accuracy >= 85 { return AppColors.success }
        if accuracy >= 70 { return AppColors.accent }
        return AppColors.secondary
    }
}
