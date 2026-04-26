import SwiftUI
import AVKit

struct PTSessionDetailView: View {
    let session: ExerciseSession
    let showOnlySharedVideos: Bool
    @ObservedObject private var videoStore = SessionVideoStore.shared
    @State private var selectedVideo: SessionVideo?

    init(session: ExerciseSession, showOnlySharedVideos: Bool = false) {
        self.session = session
        self.showOnlySharedVideos = showOnlySharedVideos
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 8)

                    summaryHeader
                    sharedVideoCard
                    exerciseList
                    overallCard

                    Spacer().frame(height: 24)
                }
                .padding(.horizontal, AppLayout.screenPadding)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Session Details")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .sheet(item: $selectedVideo) { video in
            VideoPlayer(player: AVPlayer(url: video.fileURL))
                .ignoresSafeArea()
        }
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.formattedDate)
                        .font(AppFonts.title)
                        .foregroundStyle(AppColors.textPrimary)

                    Text("Session at \(session.formattedTime)")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                VStack(spacing: 4) {
                    Image(systemName: session.readinessLevel.iconName)
                        .font(.system(size: 28))
                        .foregroundStyle(readinessColor)

                    Text(session.readinessLevel.displayLabel)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(readinessColor)
                }
            }

            HStack(spacing: 24) {
                statPill(icon: "clock.fill", value: session.formattedDuration, label: "Duration")
                statPill(icon: "repeat", value: "\(session.totalReps)", label: "Total Reps")
                statPill(icon: "target", value: String(format: "%.0f%%", session.overallAccuracy), label: "Accuracy")
            }
        }
        .padding(AppLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(AppColors.cardWhite)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
    }

    private func statPill(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(AppColors.primary)

            Text(value)
                .font(AppFonts.bodyBold)
                .foregroundStyle(AppColors.textPrimary)

            Text(label)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var exerciseList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Exercises")
                .font(AppFonts.heading)
                .foregroundStyle(AppColors.textPrimary)

            ForEach(session.exercises) { exercise in
                exerciseRow(exercise)
            }
        }
    }

    private func exerciseRow(_ exercise: CompletedExercise) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: exercise.iconName)
                    .font(.system(size: AppLayout.iconSize))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 44, height: 44)
                    .background(AppColors.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.exerciseName)
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)

                    Text("\(exercise.completedReps)/\(exercise.targetReps) reps completed")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Text(String(format: "%.0f%%", exercise.formAccuracy))
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(accuracyColor(exercise.formAccuracy))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.surface)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(accuracyColor(exercise.formAccuracy))
                        .frame(width: geo.size.width * exercise.formAccuracy / 100, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(AppLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(AppColors.cardWhite)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
    }

    private var overallCard: some View {
        HStack(spacing: 14) {
            Image(systemName: session.overallAccuracy >= 85 ? "hand.thumbsup.fill" : "info.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(accuracyColor(session.overallAccuracy))

            VStack(alignment: .leading, spacing: 4) {
                Text(session.overallAccuracy >= 85 ? "Good session" : "Form needs improvement")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)

                Text(session.overallAccuracy >= 85
                    ? "Patient maintained good form throughout this session."
                    : "Consider reviewing exercise technique at the next appointment.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
            }
        }
        .padding(AppLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(accuracyColor(session.overallAccuracy).opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(accuracyColor(session.overallAccuracy).opacity(0.2), lineWidth: 1)
        )
    }

    private var sharedVideoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Video")
                .font(AppFonts.heading)
                .foregroundStyle(AppColors.textPrimary)

            let videos = showOnlySharedVideos
                ? videoStore.sharedVideos(for: session)
                : videoStore.videos(for: session)
            if !videos.isEmpty {
                ForEach(videos) { video in
                    Button {
                        selectedVideo = video
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "video.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(AppColors.primary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(video.exerciseName ?? "Shared by patient")
                                    .font(AppFonts.bodyBold)
                                    .foregroundStyle(AppColors.textPrimary)
                                Text("Tap to play this video clip")
                                    .font(AppFonts.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(AppColors.success)
                        }
                        .padding(AppLayout.cardPadding)
                        .background(
                            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                                .fill(AppColors.cardWhite)
                                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
                        )
                    }
                }
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.textSecondary)
                    Text("This session video has not been shared by the patient.")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(AppLayout.cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                        .fill(AppColors.surface)
                )
            }
        }
    }

    private var readinessColor: Color {
        switch session.readinessLevel {
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
