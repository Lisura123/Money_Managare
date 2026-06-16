import SwiftUI

struct CashEntryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm = CashEntryViewModel()
    @StateObject private var editWindowVM = EditWindowViewModel()

    @State private var selectedAccount: String = "main"  // "main" or "mano"
    @State private var mainAmount = ""
    @State private var mainNotes  = ""
    @State private var manoAmount = ""
    @State private var manoNotes  = ""
    @State private var entryDate  = Date()
    @State private var selectedShowroomId: Int?
    @State private var error: String?
    @State private var success = false
    @State private var showLargeAmountConfirm = false

    /// Showrooms the logged-in staff member is assigned to.
    private var assignedShowrooms: [Showroom] { auth.user?.showrooms ?? [] }
    private var hasMultipleShowrooms: Bool { assignedShowrooms.count > 1 }

    /// Resolved showroom for the entry: the picked one when multiple are
    /// assigned, otherwise the single assigned showroom.
    private var showroomId: Int? {
        hasMultipleShowrooms ? selectedShowroomId : (assignedShowrooms.first?.id ?? auth.user?.showroomId)
    }
    private static let largeThreshold: Double = 1_000_000

    /// Form is locked when the window is closed, cash entries are disabled by admin.
    private var formLocked: Bool { !editWindowVM.isOpen || !editWindowVM.cashEnabled }
    /// Showroom is only needed for Main Cash when the user is assigned to multiple showrooms.
    private var needsShowroomSelection: Bool { selectedAccount == "main" && hasMultipleShowrooms && selectedShowroomId == nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let e = error {
                        ErrorBanner(message: e) { error = nil }
                    }
                    if success {
                        successBanner
                    }

                    // Edit window / availability gate
                    if !editWindowVM.cashEnabled {
                        cashDisabledBanner
                    } else if !editWindowVM.isOpen {
                        editWindowClosedBanner
                    }

                    // Account type selector
                    Picker("Account", selection: $selectedAccount) {
                        Label("Main Cash",   systemImage: "banknote").tag("main")
                        Label("Mano's Cash", systemImage: "person.crop.circle.badge.checkmark").tag("mano")
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)

                    // Showroom selector — only required for Main Cash when assigned to multiple showrooms
                    if selectedAccount == "main" && hasMultipleShowrooms {
                        showroomPicker
                    }

                    // Entry date picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Entry Date")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.mmTextSecondary)
                        DatePicker("", selection: $entryDate,
                                   in: ...Date(),
                                   displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(12)
                            .background(Color.mmInputFill)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mmDivider))
                    }
                    .padding(16)
                    .background(Color.mmCard)
                    .cornerRadius(14)

                    // Account entry fields — disabled when window is closed or showroom needed
                    if selectedAccount == "main" {
                        entrySection(
                            title: "Main Cash Account",
                            icon: "banknote",
                            amountBinding: $mainAmount,
                            notesBinding: $mainNotes,
                            accountType: "main"
                        )
                        .disabled(formLocked || needsShowroomSelection)
                        .opacity(formLocked || needsShowroomSelection ? 0.45 : 1)
                    } else {
                        entrySection(
                            title: "Mano's Cash Account",
                            icon: "person.crop.circle.badge.checkmark",
                            amountBinding: $manoAmount,
                            notesBinding: $manoNotes,
                            accountType: "mano"
                        )
                        .disabled(formLocked)
                        .opacity(formLocked ? 0.45 : 1)
                    }

                    MMButton(title: "Submit Entry",
                             isLoading: vm.isSubmitting) {
                        let amt = selectedAccount == "main" ? (Double(mainAmount) ?? -1) : (Double(manoAmount) ?? -1)
                        if amt >= Self.largeThreshold {
                            showLargeAmountConfirm = true
                        } else {
                            Task { await submit() }
                        }
                    }
                    .disabled(formLocked || needsShowroomSelection)
                }
                .padding(20)
            }
            .background(Color.mmBackground)
            .navigationTitle("Cash Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await editWindowVM.fetch()
                await vm.fetchMyHistory(cashAccountType: nil, refresh: true)
                if !hasMultipleShowrooms { selectedShowroomId = assignedShowrooms.first?.id ?? auth.user?.showroomId }
            }
            .confirmationDialog(
                "Large Amount",
                isPresented: $showLargeAmountConfirm,
                titleVisibility: .visible
            ) {
                Button("Submit Anyway", role: .destructive) { Task { await submit() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Amount is ≥ Rs. 1,000,000. Are you sure?")
            }
        }
    }

    // MARK: - Showroom picker (multi-showroom staff)

    private var showroomPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Showroom", systemImage: "building.2")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.mmTextSecondary)
            Picker(selection: $selectedShowroomId) {
                Text("Select showroom…").tag(Optional<Int>.none)
                ForEach(assignedShowrooms) { sr in
                    Text(sr.name).tag(Optional<Int>.some(sr.id))
                }
            } label: { Text("Select Showroom") }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.mmInputFill)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mmDivider))

            if selectedShowroomId == nil {
                Text("Please select a showroom before adding an entry.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mmError)
            }
        }
        .padding(16)
        .background(Color.mmCard)
        .cornerRadius(14)
    }

    @ViewBuilder
    private func entrySection(title: String, icon: String,
                               amountBinding: Binding<String>,
                               notesBinding: Binding<String>,
                               accountType: String) -> some View {        let todayStr = dateString(entryDate)
        let todayEntries = vm.myHistory.filter {
            $0.cashAccountType == accountType && $0.entryDate == todayStr
        }
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.mmPrimary)

            MMTextField(label: "Amount", text: amountBinding,
                        placeholder: "0.00", keyboardType: .decimalPad,
                        autocapitalization: .never)
            MMTextField(label: "Notes (optional)", text: notesBinding,
                        placeholder: "Any remarks...")

            if !todayEntries.isEmpty {
                Divider()
                Text("Today's \(accountType == "main" ? "Main" : "Mano") Entries")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.mmTextSecondary)
                ForEach(todayEntries) { entry in
                    TodayCashEntryRow(entry: entry)
                }
            }
        }
        .padding(16)
        .background(Color.mmCard)
        .cornerRadius(14)
    }

    private var editWindowClosedBanner: some View {        HStack(spacing: 10) {
            Image(systemName: "lock.circle.fill").foregroundStyle(Color.mmError)
            VStack(alignment: .leading, spacing: 2) {
                Text("Entry window is closed")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.mmError)
                Text("Open hours: \(editWindowVM.windowHours)")
                    .font(.system(size: 11)).foregroundStyle(Color.mmError.opacity(0.8))
            }
            Spacer()
        }
        .padding(14)
        .background(Color.mmError.opacity(0.1))
        .cornerRadius(12)
    }

    private var cashDisabledBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.circle.fill").foregroundStyle(Color.mmError)
            VStack(alignment: .leading, spacing: 2) {
                Text("Cash entries are disabled")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.mmError)
                Text("Submission has been turned off by the administrator.")
                    .font(.system(size: 11)).foregroundStyle(Color.mmError.opacity(0.8))
            }
            Spacer()
        }
        .padding(14)
        .background(Color.mmError.opacity(0.1))
        .cornerRadius(12)
    }

    private var successBanner: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.mmSuccess)
            Text("Entries submitted successfully")
                .font(.system(size: 14)).foregroundStyle(Color.mmSuccess)
        }
        .padding(12)
        .background(Color.mmSuccess.opacity(0.1))
        .cornerRadius(10)
    }

    private func submit() async {
        let isMano = selectedAccount == "mano"

        if isMano {
            // Mano's Cash — no showroom required
            let manoAmt = Double(manoAmount) ?? -1
            guard manoAmt >= 0 else { error = "Enter a valid amount."; return }
            let dateStr = dateString(entryDate)
            error = nil
            do {
                try await vm.submit(showroomId: nil, cashAmount: manoAmt,
                                    notes: manoNotes.isEmpty ? nil : manoNotes,
                                    cashAccountType: "mano", entryDate: dateStr)
                success = true
                manoAmount = ""; manoNotes = ""
                await vm.fetchMyHistory(cashAccountType: nil, refresh: true)
            } catch { self.error = error.localizedDescription }
        } else {
            // Main Cash — showroom required
            guard let sId = showroomId else {
                error = hasMultipleShowrooms ? "Please select a showroom first." : "No showroom assigned."
                return
            }
            let mainAmt = Double(mainAmount) ?? -1
            guard mainAmt >= 0 else { error = "Enter a valid amount."; return }
            let dateStr = dateString(entryDate)
            error = nil
            do {
                try await vm.submit(showroomId: sId, cashAmount: mainAmt,
                                    notes: mainNotes.isEmpty ? nil : mainNotes,
                                    cashAccountType: "main", entryDate: dateStr)
                success = true
                mainAmount = ""; mainNotes = ""
                await vm.fetchMyHistory(cashAccountType: nil, refresh: true)
            } catch { self.error = error.localizedDescription }
        }
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

// MARK: - Today's cash entry row

struct TodayCashEntryRow: View {
    let entry: DailyCashEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.cashAccountLabel)
                    .font(.system(size: 12, weight: .medium))
                if let n = entry.notes {
                    Text(n).font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                }
            }
            Spacer()
            HStack(spacing: 6) {
                Text(entry.cashAmount.currency)
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(Color.mmPrimary)
                if entry.isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10)).foregroundStyle(Color.mmTextSecondary)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.mmBackground)
        .cornerRadius(8)
    }
}

