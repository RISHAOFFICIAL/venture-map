import SwiftUI

/// The "Suggested organizations" section of the profile menu, shown right
/// under the Account / organization info.
///
/// How it works, in two steps:
///   1. The user types their focus area (the "Focus" row above this
///      section). The proxy server's AI turns that free text into 2–4 clean
///      category labels — shown here as chips so the user can see what the
///      AI understood.
///   2. The app searches for real organizations in each of the top
///      categories (near the account's location) and lists them with
///      tappable contact details via `SuggestedOrganizationRow`.
///
/// AUTO-REFRESH: `.onChange(of: focus)` watches the Focus row. Whenever it
/// changes, the section re-searches by itself — no Refresh tap needed.
/// `searchSoon()` debounces it: it waits 0.8 seconds after the last
/// keystroke before hitting the network, so typing "teaching kids to code"
/// fires one search, not twenty. Any pending or in-flight work is cancelled
/// first, so stale results can never overwrite fresh ones.
///
/// PRESENTATION SAFETY NET: if the proxy server can't be reached (or any
/// step errors), the section falls back to clearly-labeled sample data and
/// says so outright. That means the feature always demonstrates — in class
/// nobody has to start a server — while a broken server can never silently
/// look "fine". Tapping Refresh retries the live server.
///
/// - **`@State`**: every piece of mutable UI state lives here. Changing any
///   of them re-runs `body` automatically.
/// - **`.task`**: SwiftUI's way of running async work when a view appears.
///   `didLoad` guards it so the initial fetch happens once, not on every
///   redraw — focus changes re-fetch through `searchSoon()`.
/// - **`Task { await load() }`**: buttons are synchronous, so async work
///   starts inside a `Task` — Swift's lightweight unit of concurrent work.
struct SuggestedOrganizationsSection: View {
    /// The organization's typed focus area, e.g. "teaching kids to code".
    let focus: String
    /// The account's location, e.g. "Detroit, MI". May be empty.
    let location: String

    @State private var categories: [String] = []
    @State private var organizations: [SuggestedOrganization] = []
    @State private var isLoading = false
    @State private var didLoad = false
    /// True when what's on screen is sample data, not live results.
    @State private var showingDemoData = false
    /// Why the live fetch failed (shown in the sample-data note).
    @State private var demoReason: String?
    /// The pending debounced search (or in-flight fetch), if any.
    @State private var searchTask: Task<Void, Never>?

    // A plain struct with no stored state — safe to keep as a constant.
    private let service = OrganizationSearchService()

    /// The honest label shown above sample data: what happened and how to
    /// get live results.
    private var demoNote: String {
        var note = "Showing sample data — the live server couldn't be reached."
        if let demoReason { note += " (\(demoReason))" }
        note += " Start the proxy server (see Server/README.md) for real results."
        return note
    }

    /// (Re)starts the fetch for the current focus, debounced. Called
    /// whenever the Focus row changes. Cancels any pending or in-flight
    /// work first so only the latest focus ever reaches the screen.
    private func searchSoon() {
        searchTask?.cancel()
        let trimmed = focus.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        searchTask = Task {
            // Debounce: wait for the user to stop typing. If another
            // keystroke lands first, this task is cancelled above and the
            // sleep below throws, ending it quietly via `try?`.
            try? await Task.sleep(for: .seconds(0.8))
            guard !Task.isCancelled else { return }
            await load()
        }
    }

    /// Runs the two-step fetch: AI categories first, then orgs per category.
    /// Any failure lands in the `catch`, which swaps in sample data instead
    /// of leaving the section broken or empty. Checks for cancellation
    /// after each network call so a superseded fetch can't overwrite fresh
    /// results.
    private func load() async {
        let trimmed = focus.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        showingDemoData = false
        demoReason = nil
        // `defer` runs when this function returns, no matter which path it
        // takes — the spinner always stops, even on failure.
        defer { isLoading = false }

        do {
            // Step 1: AI turns the typed focus into category labels.
            let foundCategories = try await service.categories(focus: trimmed)
            guard !Task.isCancelled else { return }

            // Step 2: search organizations for the top categories. Two keeps
            // it quick; each category is its own web search on the server.
            var seenIDs = Set<String>()
            var foundOrgs: [SuggestedOrganization] = []
            for category in foundCategories.prefix(2) {
                let orgs = try await service.suggestions(focus: category, location: location)
                guard !Task.isCancelled else { return }
                for org in orgs where seenIDs.insert(org.id).inserted {
                    foundOrgs.append(org)
                }
            }

            categories = foundCategories
            organizations = foundOrgs
        } catch {
            // Safety net: sample data, labeled as such, with the reason.
            // (A cancelled task lands here too via the guards above — but
            // those return before reaching the catch, so this is only for
            // real failures.)
            categories = SuggestedOrganization.demoCategories
            organizations = SuggestedOrganization.demoOrganizations
            demoReason = error.localizedDescription
            showingDemoData = true
        }
        didLoad = true
    }

    var body: some View {
        Section {
            if focus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Type your organization's focus in the Focus row above, then return here to see matching organizations.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else if isLoading {
                HStack {
                    Spacer()
                    ProgressView("Finding organizations…")
                    Spacer()
                }
                .padding(.vertical, 8)
            } else if !didLoad {
                // Focus was empty when this section first appeared, so the
                // auto-fetch in `.task` skipped. The user typed a focus
                // since — offer the search explicitly. (Normally the
                // debounced auto-refresh below handles it.)
                Button("Find organizations", systemImage: "magnifyingglass") {
                    Task { await load() }
                }
                .font(.callout)
            } else {
                if showingDemoData {
                    Label(demoNote, systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                }

                if !categories.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(showingDemoData ? "Sample categories" : "AI-matched categories")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { category in
                                    Text(category)
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.blue.opacity(0.12), in: Capsule())
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                if organizations.isEmpty {
                    Text("No organizations found for these categories yet — try a different focus.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(organizations) { org in
                        SuggestedOrganizationRow(organization: org)
                    }
                }

                Button("Refresh suggestions", systemImage: "arrow.clockwise") {
                    Task { await load() }
                }
                .font(.callout)
            }
        } header: {
            Text("Suggested organizations")
        }
        .task {
            // Initial fetch when the section first appears.
            if !didLoad { await load() }
        }
        // Watch the Focus row: any change re-searches automatically.
        .onChange(of: focus) { _, _ in
            searchSoon()
        }
        .onDisappear {
            searchTask?.cancel()
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            SuggestedOrganizationsSection(focus: "teaching kids to code", location: "Detroit, MI")
        }
    }
}
