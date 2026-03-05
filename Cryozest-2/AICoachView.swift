import SwiftUI
import CoreData

// MARK: - Data Models

struct SuggestedQuestion: Identifiable {
    let id = UUID()
    let text: String
    let icon: String
    let color: Color
}

// MARK: - CoachSheetView

struct CoachSheetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        entity: TherapySessionEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TherapySessionEntity.date, ascending: false)]
    )
    private var sessions: FetchedResults<TherapySessionEntity>

    @FetchRequest(
        entity: SelectedTherapy.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \SelectedTherapy.therapyType, ascending: true)]
    )
    private var selectedTherapies: FetchedResults<SelectedTherapy>

    var insightsViewModel: InsightsViewModel?
    var initialQuestion: String?

    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var recoveryModel = RecoveryGraphModel(
        selectedDate: Calendar.current.startOfDay(for: Date())
    )

    @FocusState private var isInputFocused: Bool
    @State private var hasConfigured = false

    // MARK: - Computed Data

    private var selectedTherapyTypes: [TherapyType] {
        if selectedTherapies.isEmpty {
            return [.running, .weightTraining, .cycling, .meditation]
        } else {
            return selectedTherapies.compactMap { TherapyType(rawValue: $0.therapyType ?? "") }
        }
    }

    private var suggestedQuestions: [SuggestedQuestion] {
        var questions: [SuggestedQuestion] = []

        // Recovery-based
        if let score = recoveryModel.recoveryScores.last, score > 0 {
            if score >= 75 {
                questions.append(SuggestedQuestion(
                    text: "Recovery is \(score)% — should I go all out today?",
                    icon: "bolt.fill", color: .green
                ))
            } else if score < 55 {
                questions.append(SuggestedQuestion(
                    text: "Recovery is only \(score)% — how should I adjust today?",
                    icon: "battery.25percent", color: .orange
                ))
            } else {
                questions.append(SuggestedQuestion(
                    text: "Recovery is \(score)% — what intensity works best?",
                    icon: "gauge.open.with.lines.needle.33percent", color: .cyan
                ))
            }
        }

        // Sleep-based
        if let sleep = recoveryModel.previousNightSleepDuration, !sleep.isEmpty {
            if let hours = Double(sleep), hours < 7 {
                questions.append(SuggestedQuestion(
                    text: "Only got \(sleep) hours of sleep — what's the damage?",
                    icon: "moon.fill", color: .orange
                ))
            } else {
                questions.append(SuggestedQuestion(
                    text: "How did my \(sleep) hours of sleep affect recovery?",
                    icon: "moon.fill", color: .indigo
                ))
            }
        }

        // HRV trend
        if let hrv = recoveryModel.avgHrvDuringSleep, let avg = recoveryModel.avgHrvDuringSleep60Days, avg > 0 {
            let diff = hrv - avg
            if abs(diff) > 3 {
                let direction = diff > 0 ? "above" : "below"
                questions.append(SuggestedQuestion(
                    text: "HRV is \(hrv)ms — \(abs(diff))ms \(direction) baseline. What's driving this?",
                    icon: "waveform.path.ecg", color: diff > 0 ? .green : .orange
                ))
            }
        }

        // Correlation-based
        if let vm = insightsViewModel, let top = vm.topHabitImpacts.first {
            questions.append(SuggestedQuestion(
                text: "How does \(top.habitType.displayName(viewContext)) impact my \(top.metricName)?",
                icon: "chart.line.uptrend.xyaxis", color: .cyan
            ))
        }

        // Defaults
        if questions.count < 3 {
            questions.append(SuggestedQuestion(
                text: "What should I prioritize this week?",
                icon: "target", color: .cyan
            ))
        }
        if questions.count < 4 {
            questions.append(SuggestedQuestion(
                text: "Give me a full health breakdown",
                icon: "list.clipboard.fill", color: .white
            ))
        }

        return Array(questions.prefix(4))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.10, blue: 0.18)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                // Content
                if chatViewModel.messages.isEmpty {
                    welcomeScreen
                        .transition(.opacity)
                } else {
                    messagesList
                        .transition(.opacity)
                }

                // Error
                if let error = chatViewModel.errorMessage {
                    errorBanner(error)
                }

                // Input
                inputBar
            }
        }
        .onAppear {
            guard !hasConfigured else { return }
            hasConfigured = true

            let sleepModel = DailySleepViewModel(selectedDate: Calendar.current.startOfDay(for: Date()))
            let exertionModel = ExertionModel(selectedDate: Calendar.current.startOfDay(for: Date()))

            chatViewModel.configure(
                insightsViewModel: insightsViewModel,
                recoveryModel: recoveryModel,
                sleepModel: sleepModel,
                exertionModel: exertionModel,
                sessions: Array(sessions),
                selectedTherapyTypes: selectedTherapyTypes,
                viewContext: viewContext
            )

            chatViewModel.sendInitialQuestionIfNeeded(initialQuestion)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: chatViewModel.messages.isEmpty)
    }

    // MARK: - Sheet Header

    private var sheetHeader: some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                Text("Coach")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.cyan.opacity(0.6))
            }

            Spacer()

            if !chatViewModel.messages.isEmpty {
                Button(action: clearConversation) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus.message")
                            .font(.system(size: 13, weight: .semibold))
                        Text("New")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                    )
                }
            }

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Welcome Screen (compact for sheet)

    private var welcomeScreen: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .white.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, 24)

                    Text("What do you want to know?")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 24)

                questionsSection
                    .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Questions Section

    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.cyan)

                Text("Ask Me")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 6) {
                ForEach(suggestedQuestions) { question in
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        chatViewModel.sendMessage(question.text)
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(question.color.opacity(0.12))
                                    .frame(width: 32, height: 32)

                                Image(systemName: question.icon)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(question.color)
                            }

                            Text(question.text)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.15))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.green.opacity(0.5))
                        Text("Using your health data from today")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.25))
                    }
                    .padding(.top, 4)

                    ForEach(chatViewModel.messages) { message in
                        CoachChatBubble(message: message)
                            .id(message.id)
                    }

                    if chatViewModel.isLoading {
                        CoachTypingIndicator()
                            .id("typing")
                    }

                    Color.clear
                        .frame(height: 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
            .onChange(of: chatViewModel.messages.count) { _ in
                scrollToBottom(proxy)
            }
            .onChange(of: chatViewModel.isLoading) { loading in
                if loading { scrollToBottom(proxy) }
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            if chatViewModel.isLoading {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let last = chatViewModel.messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.orange)

            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(2)

            Spacer()

            Button(action: { chatViewModel.errorMessage = nil }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("", text: $chatViewModel.inputText,
                      prompt: Text("Message your coach...")
                          .foregroundColor(.white.opacity(0.3)))
                .font(.system(size: 15))
                .foregroundColor(.white)
                .tint(.cyan)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit { sendCurrentMessage() }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                )

            Button(action: sendCurrentMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(canSend ? .cyan : .white.opacity(0.12))
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private var canSend: Bool {
        !chatViewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !chatViewModel.isLoading
    }

    private func sendCurrentMessage() {
        guard canSend else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        chatViewModel.sendMessage(chatViewModel.inputText)
    }

    private func clearConversation() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let sleepModel = DailySleepViewModel(selectedDate: Calendar.current.startOfDay(for: Date()))
        let exertionModel = ExertionModel(selectedDate: Calendar.current.startOfDay(for: Date()))

        chatViewModel.clearConversation(
            insightsViewModel: insightsViewModel,
            recoveryModel: recoveryModel,
            sleepModel: sleepModel,
            exertionModel: exertionModel,
            sessions: Array(sessions),
            selectedTherapyTypes: selectedTherapyTypes,
            viewContext: viewContext
        )
    }
}

// MARK: - Chat Bubble

struct CoachChatBubble: View {
    let message: ChatMessage

    var body: some View {
        if message.role == .model {
            aiBubble
        } else {
            userBubble
        }
    }

    private var aiBubble: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyan)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 8) {
                if let blocks = message.blocks, !blocks.isEmpty {
                    ForEach(blocks) { block in
                        CoachBlockView(block: block)
                    }
                } else {
                    // Fallback to plain text
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(3)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )
                }
            }

            Spacer(minLength: 16)
        }
    }

    private var userBubble: some View {
        HStack {
            Spacer(minLength: 50)

            Text(message.content)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.22), Color.cyan.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.cyan.opacity(0.15), lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Block Renderer

struct CoachBlockView: View {
    let block: CoachResponseBlock

    var body: some View {
        switch block.content {
        case .text(let text):
            TextBlockView(text: text)
        case .metric(let data):
            MetricBlockView(metric: data)
        case .metricsRow(let metrics):
            MetricsRowBlockView(metrics: metrics)
        case .chart(let data):
            ChartBlockView(data: data)
        case .comparison(let data):
            ComparisonBlockView(data: data)
        case .tip(let data):
            TipBlockView(data: data)
        case .workoutSummary(let data):
            WorkoutSummaryBlockView(data: data)
        case .sessionList(let data):
            SessionListBlockView(data: data)
        case .heartZones(let data):
            HeartZonesBlockView(data: data)
        }
    }
}

// MARK: - Text Block

struct TextBlockView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundColor(.white.opacity(0.9))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Single Metric Block

struct MetricBlockView: View {
    let metric: MetricData

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(metric.label.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(0.5)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(metric.value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(metric.unit)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: metric.trend.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(metric.trend.color)

                if let change = metric.change {
                    Text(change)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(metric.trend.color)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - Metrics Row Block

struct MetricsRowBlockView: View {
    let metrics: [MetricData]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(metrics.prefix(4)) { metric in
                VStack(spacing: 5) {
                    Image(systemName: metric.trend.icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(metric.trend.color)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(metric.value)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(metric.unit)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white.opacity(0.35))
                    }

                    Text(metric.label)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.35))
                        .textCase(.uppercase)
                        .tracking(0.3)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                )
            }
        }
    }
}

// MARK: - Chart Block

struct ChartBlockView: View {
    let data: ChartBlockData
    @State private var animatedProgress: CGFloat = 0

    private var maxValue: Double {
        data.values.map(\.value).max() ?? 1
    }

    private var minValue: Double {
        let min = data.values.map(\.value).min() ?? 0
        return max(0, min - (maxValue - min) * 0.2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(data.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(0.3)

                Spacer()

                Text(data.unit)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.25))
            }

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(data.values.enumerated()), id: \.offset) { index, point in
                    VStack(spacing: 4) {
                        // Bar
                        let range = maxValue - minValue
                        let normalizedHeight = range > 0
                            ? CGFloat((point.value - minValue) / range)
                            : 0.5

                        RoundedRectangle(cornerRadius: 4)
                            .fill(barGradient(for: point.value))
                            .frame(height: max(4, normalizedHeight * 80 * animatedProgress))

                        // Label
                        Text(point.label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animatedProgress = 1
            }
        }
    }

    private func barGradient(for value: Double) -> LinearGradient {
        let ratio = maxValue > minValue ? (value - minValue) / (maxValue - minValue) : 0.5
        let color: Color = ratio > 0.7 ? .green : (ratio > 0.4 ? .cyan : .orange)
        return LinearGradient(
            colors: [color.opacity(0.6), color.opacity(0.25)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Comparison Block

struct ComparisonBlockView: View {
    let data: ComparisonData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(data.title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.35))
                .tracking(0.5)

            ForEach(data.items) { item in
                HStack {
                    Text(item.label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    Spacer()

                    HStack(spacing: 8) {
                        Text(item.previous)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                            .strikethrough(color: .white.opacity(0.15))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.2))

                        Text(item.current)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)

                        Image(systemName: item.trend.icon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(item.trend.color)
                    }
                }
                .padding(.vertical, 4)

                if item.id != data.items.last?.id {
                    Rectangle()
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 1)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - Tip Block

struct TipBlockView: View {
    let data: TipData

    private var sfIcon: String {
        switch data.icon.lowercased() {
        case "flame", "fire": return "flame.fill"
        case "moon", "sleep": return "moon.fill"
        case "heart", "hr": return "heart.fill"
        case "figure.walk", "walk", "steps": return "figure.walk"
        case "brain", "mind": return "brain.head.profile"
        case "bed.double", "bed", "rest": return "bed.double.fill"
        case "bolt", "energy": return "bolt.fill"
        case "drop", "water": return "drop.fill"
        default: return "lightbulb.fill"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.cyan.opacity(0.12))
                    .frame(width: 32, height: 32)

                Image(systemName: sfIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.cyan)
            }

            Text(data.text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.08), Color.cyan.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.cyan.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

// MARK: - Workout Summary Block

struct WorkoutSummaryBlockView: View {
    let data: WorkoutSummaryData

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(data.type.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(0.5)

                    if data.isAppleWatch {
                        Image(systemName: "applewatch")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.green.opacity(0.6))
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(data.durationMinutes)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("min")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                }

                Text(data.date)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
            }

            Spacer()

            if let hr = data.avgHeartRate {
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red.opacity(0.7))

                    Text("\(hr) bpm")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - Session List Block

struct SessionListBlockView: View {
    let data: SessionListData

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(data.title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.35))
                .tracking(0.5)

            ForEach(Array(data.sessions.prefix(5).enumerated()), id: \.offset) { index, session in
                HStack {
                    Text(Self.shortDateFormatter.string(from: session.date))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(width: 44, alignment: .leading)

                    Text(session.type)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Text("\(session.durationMinutes) min")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))

                    if let hr = session.avgHeartRate {
                        HStack(spacing: 3) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.red.opacity(0.6))
                            Text("\(hr)")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(width: 50, alignment: .trailing)
                    } else {
                        Color.clear.frame(width: 50)
                    }

                    if session.isAppleWatch {
                        Image(systemName: "applewatch")
                            .font(.system(size: 8))
                            .foregroundColor(.green.opacity(0.5))
                    }
                }
                .padding(.vertical, 4)

                if index < min(data.sessions.count, 5) - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 1)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - Heart Zones Block

struct HeartZonesBlockView: View {
    let data: HeartZoneData
    @State private var animatedProgress: CGFloat = 0

    private var totalMinutes: Int {
        max(data.recovery + data.conditioning + data.overload, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HEART RATE ZONES")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.35))
                .tracking(0.5)

            zoneBar(label: "Recovery", minutes: data.recovery, color: .green)
            zoneBar(label: "Conditioning", minutes: data.conditioning, color: .cyan)
            zoneBar(label: "Overload", minutes: data.overload, color: .orange)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animatedProgress = 1
            }
        }
    }

    private func zoneBar(label: String, minutes: Int, color: Color) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 85, alignment: .leading)

            GeometryReader { geo in
                let maxWidth = geo.size.width
                let ratio = CGFloat(minutes) / CGFloat(totalMinutes)
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.7), color.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(4, maxWidth * ratio * animatedProgress))
            }
            .frame(height: 16)

            Text("\(minutes) min")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 50, alignment: .trailing)
        }
    }
}

// MARK: - Typing Indicator

struct CoachTypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyan)
            }
            .padding(.top, 2)

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 7, height: 7)
                        .offset(y: animating ? -5 : 0)
                        .animation(
                            .easeInOut(duration: 0.45)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )

            Spacer(minLength: 50)
        }
        .onAppear { animating = true }
    }
}
