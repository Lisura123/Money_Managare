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
    @State private var error: String?
    @State private var success = false
    @State private var showLargeAmountConfirm = false

    private var showroomId: Int? { auth.user?.showroomId }
    private static let largeThreshold: Double = 1_000_000

    /// Form is locked when the window is closed OR bank entries are disabled by admin.
    private var formLocked: Bool { !editWindowVM.isOpen || !editWindowVM.bankEnabled }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let e = error {
                        ErrorBanner(message: e) { error = nil }
                    }
                    if success {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.mmSuccess)
                            Text("Bank entry submitted").foregroundStyle(Color.mmSuccess)
                        }
                        .padding(12).background(Color.mmSuccess.opacity(0.1)).cornerRadius(10)
                    }

                    // Edit window / availability gate
                    if !editWindowVM.bankEnabled {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.circle.fill").foregroundStyle(Color.mmError)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Bank entries are disabled")
                                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.mmError)
                                Text("Submission has been turned off by the administrator.")
                                    .font(.system(size: 11)).foregroundStyle(Color.mmError.opacity(0.8))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.mmError.opacity(0.1))
                        .cornerRadius(12)
                    } else if !editWindowVM.isOpen {
                        HStack(spacing: 10) {
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

                    // Form card — disabled when window is closed
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Bank Account", systemImage: "creditcard")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.mmPrimary)

                        if accountVM.isLoading {
                            ProgressView()
                        } else if accountVM.accounts.isEmpty {
                            Text("No active bank accounts for your showroom.")
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

                        // Today's card entries
                        let todayStr = dateString(entryDate)
                        let todayEntries = vm.myHistory.filter { $0.entryDate == todayStr }
                        if !todayEntries.isEmpty {
                            Divider()
                            Text("Today's Bank Entries")
                                .font(.system(size: 12, weight: .medium)).foregroundStyle(Color.mmTextSecondary)
                            ForEach(todayEntries) { entry in
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
                        }
                    }
                    .padding(16)
                    .background(Color.mmCard)
                    .cornerRadius(14)
                    .disabled(formLocked)
                    .opacity(formLocked ? 0.45 : 1)

                    MMButton(title: "Submit Bank Entry", isLoading: vm.isSubmitting) {
                        guard let amt = Double(amount), amt > 0 else { error = "Enter a valid amount."; return }
                        if amt >= Self.largeThreshold { showLargeAmountConfirm = true }
                        else { Task { await submit() } }
                    }
                    .disabled(formLocked || selectedAccountId == nil)
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
                await accountVM.fetchMyAccounts()
                await vm.fetchMyHistory(refresh: true)
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

    private func submit() async {
        guard let sId = showroomId else { error = "No showroom assigned."; return }
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

