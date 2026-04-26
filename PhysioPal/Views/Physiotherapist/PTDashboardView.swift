import SwiftUI

private enum PTColors {
    static let accent = Color(hex: "3D5A80")
    static let accentLight = Color(hex: "5B7FB5")
    static let background = Color(hex: "F0F2F5")
    static let cardBackground = Color.white
    static let bannerGradientStart = Color(hex: "3D5A80")
    static let bannerGradientEnd = Color(hex: "2C3E6B")
    static let sectionHeader = Color(hex: "3D5A80")
}

struct PTDashboardView: View {
    @StateObject private var viewModel = PhysiotherapistDashboardViewModel()
    @ObservedObject private var incidentStore = IncidentStore.shared
    @State private var appeared = false

    var body: some View {
        ZStack {
            PTColors.background.ignoresSafeArea()

            if viewModel.isLoadingHealth && viewModel.healthMetrics == nil {
                loadingState
            } else {
                dashboardContent
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image(systemName: "stethoscope")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(PTColors.accent)
                    Text("Physiotherapist Dashboard")
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(PTColors.accent)
                }
            }
        }
        .task {
            await viewModel.loadDashboard()
        }
    }

    private var loadingState: some View {
        VStack(spacing: 24) {
            Image(systemName: "stethoscope")
                .font(.system(size: 64))
                .foregroundStyle(PTColors.accent)
                .symbolEffect(.pulse, options: .repeating)

            Text("Loading patient data...")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                ptBanner
                patientInfoCard
                routineManagementSection
                healthMetricsSection
                readinessCard
                incidentsSection
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

    // MARK: - PT Banner

    private var ptBanner: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(PTColors.accent.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: "stethoscope")
                    .font(.system(size: 26))
                    .foregroundStyle(PTColors.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Dr. Sarah Mitchell")
                    .font(AppFonts.heading)
                    .foregroundStyle(.white)
                Text("Physiotherapist")
                    .font(AppFonts.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("PT View")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.white.opacity(0.25)))
            }
        }
        .padding(AppLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(
                    LinearGradient(
                        colors: [PTColors.bannerGradientStart, PTColors.bannerGradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: PTColors.accent.opacity(0.3), radius: 12, y: 6)
        )
    }

    // MARK: - Patient Info Card

    private var patientInfoCard: some View {
        HStack(spacing: 16) {
            accentBar(color: PTColors.accentLight)

            Image(systemName: viewModel.patient.avatarSystemImage)
                .font(.system(size: 44))
                .foregroundStyle(PTColors.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text("Patient")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(PTColors.accent)
                    .textCase(.uppercase)
                    .kerning(1.2)

                Text(viewModel.patient.name)
                    .font(AppFonts.heading)
                    .foregroundStyle(AppColors.textPrimary)

                HStack(spacing: 12) {
                    Label("Age \(viewModel.patient.age)", systemImage: "person.fill")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

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
                .fill(PTColors.cardBackground)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
    }

    // MARK: - Routine Management

    private var routineManagementSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Exercise Routine", icon: "list.clipboard.fill")

            VStack(spacing: 16) {
                if viewModel.routineStore.hasAssignedRoutine {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(AppColors.success)
                            Text("Routine assigned — \(viewModel.routineStore.assignedExercises.count) exercises")
                                .font(AppFonts.bodyBold)
                                .foregroundStyle(AppColors.textPrimary)
                            Spacer()
                        }

                        ForEach(viewModel.routineStore.assignedExercises) { item in
                            if let exercise = Exercise.find(byID: item.exerciseID) {
                                HStack(spacing: 12) {
                                    Image(systemName: exercise.iconName)
                                        .font(.system(size: 18))
                                        .foregroundStyle(PTColors.accent)
                                        .frame(width: 32)

                                    Text(exercise.name)
                                        .font(AppFonts.body)
                                        .foregroundStyle(AppColors.textPrimary)

                                    Spacer()

                                    Text("\(item.targetReps) reps")
                                        .font(AppFonts.caption)
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(AppColors.accent)
                        Text("No routine assigned to patient")
                            .font(AppFonts.body)
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                    }
                }

                NavigationLink {
                    PTRoutineBuilderView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: viewModel.routineStore.hasAssignedRoutine ? "pencil.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 22))
                        Text(viewModel.routineStore.hasAssignedRoutine ? "Edit Routine" : "Create Routine")
                            .font(AppFonts.button)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppLayout.buttonHeight)
                    .background(PTColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                    .shadow(color: PTColors.accent.opacity(0.3), radius: 8, y: 4)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                })
            }
            .padding(AppLayout.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                    .fill(PTColors.cardBackground)
                    .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
            )
        }
    }

    // MARK: - Health Metrics

    private var healthMetricsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader(title: "Patient Health Snapshot", icon: "heart.text.clipboard.fill")

                Spacer()

                if let metrics = viewModel.healthMetrics {
                    Text(timeAgoString(from: metrics.assessedAt))
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            if let metrics = viewModel.healthMetrics {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ptMetricCard(icon: "bed.double.fill", label: "Sleep", value: metrics.formattedSleep ?? "—", color: sleepColor(metrics.sleepHours), progress: (metrics.sleepHours ?? 0) / 9.0)

                    ptMetricCard(icon: "heart.fill", label: "Heart Rate", value: metrics.formattedHeartRate ?? "—", color: heartRateColor(metrics.restingHeartRate), progress: heartRateProgress(metrics.restingHeartRate))

                    ptMetricCard(icon: "flame.fill", label: "Active Energy", value: metrics.formattedEnergy ?? "—", color: energyColor(metrics.activeEnergyKcal), progress: (metrics.activeEnergyKcal ?? 0) / 300.0)

                    ptMetricCard(icon: "figure.walk", label: "Steps", value: metrics.formattedSteps ?? "—", color: stepsColor(metrics.stepCount), progress: (metrics.stepCount ?? 0) / 6000.0)
                }

                if let hrv = metrics.formattedHRV {
                    ptMetricCard(icon: "waveform.path.ecg", label: "Heart Rate Variability", value: hrv, color: PTColors.accent, progress: (metrics.heartRateVariability ?? 0) / 60.0)
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
                HStack(spacing: 0) {
                    accentBar(color: readinessColor(metrics.level))

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
                            .font(AppFonts.body)
                            .foregroundStyle(AppColors.textPrimary)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(AppLayout.cardPadding)
                }
                .background(
                    RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                        .fill(PTColors.cardBackground)
                        .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
            }
        }
    }

    // MARK: - Weekly Overview

    private var incidentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Incidents", icon: "exclamationmark.shield.fill")

            if incidentStore.incidents.isEmpty {
                noDataCard(message: "No incidents have been reported.")
            } else {
                ForEach(incidentStore.incidents.prefix(5)) { incident in
                    HStack(spacing: 0) {
                        accentBar(color: AppColors.secondary)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(incident.title)
                                    .font(AppFonts.bodyBold)
                                    .foregroundStyle(AppColors.textPrimary)
                                Spacer()
                                Text(timeAgoString(from: incident.createdAt))
                                    .font(AppFonts.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            Text(incident.details)
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textSecondary)
                                .lineSpacing(4)
                            Text("Shared clips: \(incident.sharedVideoCount)")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.primary)
                        }
                        .padding(AppLayout.cardPadding)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                            .fill(PTColors.cardBackground)
                            .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                }
            }
        }
    }

    private var weeklyOverview: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "This Week", icon: "chart.bar.fill")

            HStack(spacing: 14) {
                weekStat(
                    icon: "calendar.badge.checkmark",
                    value: "\(viewModel.sessionStore.sessionsThisWeek)",
                    label: "Sessions",
                    color: PTColors.accent
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
                .fill(PTColors.cardBackground)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
    }

    // MARK: - Sessions

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Recent Sessions", icon: "clock.arrow.circlepath")

            if viewModel.sessionStore.sessions.isEmpty {
                noDataCard(message: "No exercise sessions recorded yet.")
            } else {
                ForEach(viewModel.sessionStore.recentSessions) { session in
                    NavigationLink {
                        PTSessionDetailView(session: session, showOnlySharedVideos: true)
                    } label: {
                        sessionCard(session)
                    }
                }
            }
        }
    }

    private func sessionCard(_ session: ExerciseSession) -> some View {
        HStack(spacing: 0) {
            accentBar(color: accuracyColor(session.overallAccuracy))

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
                                .fill(PTColors.background)
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
        }
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(PTColors.cardBackground)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
    }

    // MARK: - Shared Components

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(PTColors.accent)
            Text(title)
                .font(AppFonts.heading)
                .foregroundStyle(PTColors.sectionHeader)
        }
    }

    private func accentBar(color: Color) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(width: 5)
            .padding(.vertical, 12)
            .padding(.leading, 4)
    }

    private func ptMetricCard(icon: String, label: String, value: String, color: Color, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                Spacer()
                Text(value)
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
            }

            Text(label)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(PTColors.background)
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * min(progress, 1.0), height: 5)
                }
            }
            .frame(height: 5)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(PTColors.cardBackground)
                .shadow(color: AppShadow.color, radius: 6, x: 0, y: 2)
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
                .fill(PTColors.background)
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
        return h < HealthThresholds.lowSleepHours ? AppColors.secondary : PTColors.accent
    }

    private func heartRateColor(_ hr: Double?) -> Color {
        guard let hr = hr else { return AppColors.textSecondary }
        if hr > HealthThresholds.elevatedHeartRate { return AppColors.secondary }
        if hr < 60 { return PTColors.accent }
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
