import SwiftUI

struct ScheduleView: View {
    let appState: AppState
    var onAction: ((ScheduleAction) -> Void)?

    @State private var showingAddSheet = false
    @State private var schedules: [Schedule] = []

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Charging Schedules")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
            }

            if schedules.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                    Text("No schedules configured")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text("Add a schedule to automatically adjust charge limits at specific times")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(schedules) { schedule in
                            ScheduleRow(schedule: schedule) { enabled in
                                onAction?(.toggle(schedule.id, enabled))
                                if let idx = schedules.firstIndex(where: { $0.id == schedule.id }) {
                                    schedules[idx].isEnabled = enabled
                                }
                            } onDelete: {
                                onAction?(.remove(schedule.id))
                                schedules.removeAll { $0.id == schedule.id }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingAddSheet) {
            AddScheduleSheet { schedule in
                schedules.append(schedule)
                onAction?(.add(schedule))
            }
        }
    }
}

struct ScheduleRow: View {
    let schedule: Schedule
    var onToggle: ((Bool) -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(schedule.startTimeString) - \(schedule.endTimeString)")
                    .font(.system(size: 11, weight: .medium))
                HStack(spacing: 4) {
                    Text("Target: \(schedule.targetPercent)%")
                        .font(.system(size: 9))
                    Text(schedule.repeatDaysString)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { schedule.isEnabled },
                set: { onToggle?($0) }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)

            Button {
                onDelete?()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct AddScheduleSheet: View {
    var onAdd: ((Schedule) -> Void)?
    @Environment(\.dismiss) var dismiss

    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var targetPercent: Double = 80
    @State private var selectedDays: Set<Int> = []

    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Schedule")
                .font(.headline)

            DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                .font(.system(size: 12))
            DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                .font(.system(size: 12))

            VStack(spacing: 4) {
                HStack {
                    Text("Target: \(Int(targetPercent))%")
                        .font(.system(size: 12))
                    Spacer()
                }
                Slider(value: $targetPercent, in: 20...100, step: 5)
            }

            VStack(spacing: 4) {
                Text("Repeat")
                    .font(.system(size: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { index in
                        let day = index + 1
                        Button {
                            if selectedDays.contains(day) {
                                selectedDays.remove(day)
                            } else {
                                selectedDays.insert(day)
                            }
                        } label: {
                            Text(dayNames[index])
                                .font(.system(size: 9, weight: .medium))
                                .frame(width: 32, height: 24)
                                .background(selectedDays.contains(day) ? Color.blue : Color.gray.opacity(0.1))
                                .foregroundStyle(selectedDays.contains(day) ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Add") {
                    let startComps = Calendar.current.dateComponents([.hour, .minute], from: startTime)
                    let endComps = Calendar.current.dateComponents([.hour, .minute], from: endTime)
                    let schedule = Schedule(
                        startHour: startComps.hour ?? 0,
                        startMinute: startComps.minute ?? 0,
                        endHour: endComps.hour ?? 0,
                        endMinute: endComps.minute ?? 0,
                        targetPercent: Int(targetPercent),
                        repeatDays: selectedDays
                    )
                    onAdd?(schedule)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
