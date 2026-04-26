import SwiftUI

private enum PTBuilderColors {
    static let accent = Color(hex: "3D5A80")
    static let background = Color(hex: "F0F2F5")
    static let cardBackground = Color.white
}

struct PTRoutineBuilderView: View {
    @StateObject private var routineStore = RoutineStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selections: [String: ExerciseSelection] = [:]
    @State private var showSavedConfirmation = false

    struct ExerciseSelection {
        var isEnabled: Bool
        var reps: Int
    }

    var body: some View {
        ZStack {
            PTBuilderColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 8)
                    headerCard
                    exerciseListSection
                    Spacer().frame(height: 8)
                    saveButton
                    if routineStore.hasAssignedRoutine {
                        clearButton
                    }
                    Spacer().frame(height: 24)
                }
                .padding(.horizontal, AppLayout.screenPadding)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image(systemName: "list.clipboard.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(PTBuilderColors.accent)
                    Text("Assign Routine")
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(PTBuilderColors.accent)
                }
            }
        }
        .onAppear { loadCurrentSelections() }
        .overlay {
            if showSavedConfirmation {
                savedToast
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "list.clipboard.fill")
                .font(.system(size: 32))
                .foregroundStyle(PTBuilderColors.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text("Build Routine")
                    .font(AppFonts.heading)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Select exercises and set reps for your patient.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
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

    // MARK: - Exercise List

    private var exerciseListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Exercises")
                .font(AppFonts.heading)
                .foregroundStyle(AppColors.textPrimary)

            ForEach(Exercise.library) { exercise in
                exerciseRow(exercise)
            }
        }
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        let sel = selections[exercise.id] ?? ExerciseSelection(isEnabled: false, reps: exercise.standardReps)

        return VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: exercise.iconName)
                    .font(.system(size: AppLayout.iconSize))
                    .foregroundStyle(sel.isEnabled ? PTBuilderColors.accent : AppColors.textSecondary)
                    .frame(width: 44, height: 44)
                    .background((sel.isEnabled ? PTBuilderColors.accent : AppColors.textSecondary).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)

                    Text(exercise.description)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { sel.isEnabled },
                    set: { newVal in
                        selections[exercise.id] = ExerciseSelection(
                            isEnabled: newVal,
                            reps: sel.reps
                        )
                    }
                ))
                .tint(PTBuilderColors.accent)
                .labelsHidden()
            }

            if sel.isEnabled {
                HStack(spacing: 16) {
                    Text("Reps")
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(AppColors.textSecondary)

                    Spacer()

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        let newReps = max(1, sel.reps - 1)
                        selections[exercise.id] = ExerciseSelection(isEnabled: true, reps: newReps)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(PTBuilderColors.accent)
                    }
                    .frame(width: 54, height: 54)

                    Text("\(sel.reps)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 44)
                        .multilineTextAlignment(.center)

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        let newReps = min(30, sel.reps + 1)
                        selections[exercise.id] = ExerciseSelection(isEnabled: true, reps: newReps)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(PTBuilderColors.accent)
                    }
                    .frame(width: 54, height: 54)
                }
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(AppLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .fill(AppColors.cardWhite)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(sel.isEnabled ? PTBuilderColors.accent.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.25), value: sel.isEnabled)
    }

    // MARK: - Actions

    private var selectedCount: Int {
        selections.values.filter(\.isEnabled).count
    }

    private var saveButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            saveRoutine()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                Text(selectedCount > 0 ? "Save Routine (\(selectedCount) exercises)" : "Save Routine")
                    .font(AppFonts.button)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: AppLayout.buttonHeight)
            .background(selectedCount > 0 ? PTBuilderColors.accent : AppColors.textSecondary)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
            .shadow(color: (selectedCount > 0 ? PTBuilderColors.accent : AppColors.textSecondary).opacity(0.3), radius: 8, y: 4)
        }
        .disabled(selectedCount == 0)
    }

    private var clearButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            routineStore.clear()
            loadCurrentSelections()
            showConfirmation()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "trash")
                    .font(.system(size: 20))
                Text("Clear Assigned Routine")
                    .font(AppFonts.button)
            }
            .foregroundStyle(AppColors.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: AppLayout.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.buttonRadius)
                    .stroke(AppColors.secondary, lineWidth: 2)
            )
        }
    }

    // MARK: - Toast

    private var savedToast: some View {
        VStack {
            Spacer()

            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.success)
                Text("Routine saved")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(AppColors.cardWhite)
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
            )
            .padding(.bottom, 40)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .allowsHitTesting(false)
    }

    // MARK: - Logic

    private func loadCurrentSelections() {
        var map: [String: ExerciseSelection] = [:]
        let assigned = Set(routineStore.assignedExercises.map(\.exerciseID))
        let repMap = Dictionary(uniqueKeysWithValues: routineStore.assignedExercises.map { ($0.exerciseID, $0.targetReps) })

        for exercise in Exercise.library {
            map[exercise.id] = ExerciseSelection(
                isEnabled: assigned.contains(exercise.id),
                reps: repMap[exercise.id] ?? exercise.standardReps
            )
        }
        selections = map
    }

    private func saveRoutine() {
        let items: [AssignedRoutineItem] = Exercise.library.compactMap { exercise in
            guard let sel = selections[exercise.id], sel.isEnabled else { return nil }
            return AssignedRoutineItem(exerciseID: exercise.id, targetReps: sel.reps)
        }
        routineStore.save(items)
        showConfirmation()
    }

    private func showConfirmation() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showSavedConfirmation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSavedConfirmation = false }
        }
    }
}
