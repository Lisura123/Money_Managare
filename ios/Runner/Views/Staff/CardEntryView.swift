import SwiftUI

struct CardEntryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm = CardEntryViewModel()
    @StateObject private var accountVM = CardAccountViewModel()
    @StateObject private var editWindowVM = EditWindowViewModel()

    @State private var selectedAccountId: Int?
    @State private var amount = ""
    @State private var notes = ""
    @State private var entryDate = Date()
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

    /// Form is locked when the window is closed OR bank entries are disabled by admin.
    private var formLocked: Bool { !editWindowVM.isOpen || !editWindowVM.bankEnabled }
    private var needsShowroomSelection: Bool { hasMultipleShowrooms && selectedShowroomId == nil }

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

                    availabilityBanner

                    entryDatePicker

                    // Showroom selector — required when assigned to multiple showrooms
                    if hasMultipleShowrooms {
                        showroomPicker
                    }

                    bankAccountForm
                        .disabled(formLocked || needsShowroomSelection)
                        .opacity(formLocked || needsShowroomSelection ? 0.45 : 1)

                    MMButton(title: "Submit Bank Entry", isLoading: vm.isSubmitting) {
                        guard let amt = Double(amount), amt > 0 else { error = "Enter a valid amount."; return }
                        if amt >= Self.largeThreshold { showLargeAmountConfirm = true }
                        else { Task { await submit() } }
                    }
                    .disabled(formLocked || needsShowroomSelection || selectedAccountId == nil)
                }
                .padding(20)
            }
            .background(Color.mmBackground)
            .navigationTitle("Bank Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await editWindowVM.fetch()
                await vm.fetchMyHistory(refresh: true)
                if hasMultipleShowrooms {
                    // Wait for a showroom to be picked before loading accounts.
                    if let sid = selectedShowroomId { await accountVM.fetchMyAccounts(showroomId: sid) }
                } else {
                    selectedShowroomId = assignedShowrooms.first?.id ?? auth.user?.showroomId
                    await accountVM.fetchMyAccounts()
                }
            }
            .onChange(of: selectedShowroomId) { newValue in
                // Reload bank accounts for the newly selected showroom.
                selectedAccountId = nil
                guard let sid = newValue else { accountVM.accounts = []; return }
                Task { await accountVM.fetchMyAccounts(showroomId: sid) }
            }
            .confirmationDialog(
                "Large Amount",
                isPresented: $showLargeAmountConfirm,
                titleVisibility: .visible
            ) {
                Button("Submit Anyway", role: .destructive) { Task { await submit() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This amount is ≥ Rs. 1,000,000. Are you sure?")
            }
        }
    }

    // MARK: - Subviews

    private var successBanner: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.mmSuccess)
            Text("Bank entry submitted").foregroundStyle(Color.mmSuccess)
        }
        .padding(12).background(Color.mmSuccess.opacity(0.1)).cornerRadius(10)
    }

    @ViewBuilder
    private var availabilityBanner: some View {
        if !editWindowVM.bankEnabled {
            lockBanner(title: "Bank entries are disabled",
                       subtitle: "Submission has been turned off by the administrator.")
        } else if !editWindowVM.isOpen {
            lockBanner(title: "Entry window is closed",
                       subtitle: "Open hours: \(editWindowVM.windowHours)")
        }
    }

    private func lockBanner(title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.circle.fill").foregroundStyle(Color.mmError)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.mmError)
                Text(subtitle)
                    .font(.system(size: 11)).foregroundStyle(Color.mmError.opacity(0.8))
            }
            Spacer()
        }
        .padding(14)
        .background(Color.mmError.opacity(0.1))
        .cornerRadius(12)
    }

    private var entryDatePicker: some View {
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
    }

    private var bankAccountForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Bank Account", systemImage: "creditcard")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.mmPrimary)

            if accountVM.isLoading {
                ProgressView()
            } else if accountVM.accounts.isEmpty {
                Text(needsShowroomSelection
                     ? "Select a showroom to load its bank accounts."
                     : "No active bank accounts for your showroom.")
                    .font(.system(size: 13)).foregroundStyle(Color.mmTextSecondary)
            } else {
                Picker(selection: $selectedAccountId) {
                    Text("Select account…").tag(Optional<Int>.none)
                    ForEach(accountVM.accounts) { acc in
                        Text(acc.displayLabel).tag(Optional<Int>.some(acc.id))
                    }
                } label: { Text("Select Account") }
                .pickerStyle(.menu)
                .padding(12)
                .background(Color.mmInputFill)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mmDivider))
            }

            MMTextField(label: "Amount", text: $amount,
                        placeholder: "0.00", keyboardType: .decimalPad,
                        autocapitalization: .never)
            MMTextField(label: "Notes (optional)", text: $notes, placeholder: "Any remarks...")

            todayEntriesList
        }
        .padding(16)
        .background(Color.mmCard)
        .cornerRadius(14)
    }

    @ViewBuilder
    private var todayEntriesList: some View {
        let todayStr = dateString(entryDate)
        let todayEntries = vm.myHistory.filter { $0.entryDate == todayStr }
        if !todayEntries.isEmpty {
            Divider()
            Text("Today's Bank Entries")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.mmTextSecondary)
            ForEach(todayEntries) { entry in
                todayEntryRow(entry)
            }
        }
    }

    private func todayEntryRow(_ entry: DailyCardEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayCard)
                    .font(.system(size: 12, weight: .medium))
                if let n = entry.notes {
                    Text(n).font(.system(size: 11)).foregroundStyle(Color.mmTextSecondary)
                }
            }
            Spacer()
            HStack(spacing: 6) {
                Text(entry.amount.currency)
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(Color.mmPrimary)
                if entry.isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10)).foregroundStyle(Color.mmTextSecondary)
                }
            }
        }
        .padding(.vertical, 6).padding(.horizontal, 10)
        .background(Color.mmBackground).cornerRadius(8)
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

    private func submit() async {
        guard let sId = showroomId else {
            error = hasMultipleShowrooms ? "Please select a showroom first." : "No showroom assigned."
            return
        }
        guard let accId = selectedAccountId, let acc = accountVM.accounts.first(where: { $0.id == accId }) else { error = "Select a bank account."; return }
        guard let amt = Double(amount), amt > 0 else { error = "Enter a valid amount."; return }
        let dateStr = dateString(entryDate)
        error = nil
        do {
            try await vm.submit(showroomId: sId, cardAccountId: acc.id,
                                amount: amt, notes: notes.isEmpty ? nil : notes,
                                entryDate: dateStr)
            success = true; amount = ""; notes = ""; selectedAccountId = nil
            await vm.fetchMyHistory(refresh: true)
        } catch { self.error = error.localizedDescription }
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

