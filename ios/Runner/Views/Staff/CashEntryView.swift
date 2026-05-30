import SwiftUI

struct CashEntryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm = CashEntryViewModel()
    @StateObject private var editWindowVM = EditWindowViewModel()

    @State private var mainAmount = ""
    @State private var manoAmount = ""
    @State private var mainNotes  = ""
    @State private var manoNotes  = ""
    @State private var entryDate  = Date()
    @State private var error: String?
    @State private var success = false
    @State private var showLargeAmountConfirm = false

    private var showroomId: Int? { auth.user?.showroomId }
    private static let largeThreshold: Double = 1_000_000

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

                    // Edit window gate
                    if !editWindowVM.isOpen {
                        editWindowClosedBanner
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

                    // Main Account section
                    entrySection(
                        title: "Main Cash Account",
                        icon: "banknote",
                        amountBinding: $mainAmount,
                        notesBinding: $mainNotes,
                        accountType: "main"
                    )

                    // Mano Account section
                    entrySection(
                        title: "Mano's Cash Account",
                        icon: "person.crop.circle.badge.checkmark",
                        amountBinding: $manoAmount,
                        notesBinding: $manoNotes,
                        accountType: "mano"
                    )

                    MMButton(title: "Submit Entries",
                             isLoading: vm.isSubmitting) {
                        let mainAmt = Double(mainAmount) ?? -1
                        let manoAmt = Double(manoAmount) ?? -1
                        if mainAmt >= Self.largeThreshold || manoAmt >= Self.largeThreshold {
                            showLargeAmountConfirm = true
                        } else {
                            Task { await submit() }
                        }
                    }
                    .disabled(!editWindowVM.isOpen)
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
            }
            .confirmationDialog(
                "Large Amount",
                isPresented: $showLargeAmountConfirm,
                titleVisibility: .visible
            ) {
                Button("Submit Anyway", role: .destructive) { Task { await submit() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("One or more amounts are ≥ Rs. 1,000,000. Are you sure?")
            }
        }
    }

    @ViewBuilder
    private func entrySection(title: String, icon: String,
                               amountBinding: Binding<String>,
                               notesBinding: Binding<String>,
                               accountType: String) -> some View {
        let todayStr = dateString(entryDate)
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

    private var editWindowClosedBanner: some View {
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
        guard let sId = showroomId else { error = "No showroom assigned."; return }
        let mainAmt = Double(mainAmount) ?? -1
        let manoAmt = Double(manoAmount) ?? -1
        guard mainAmt >= 0 || manoAmt >= 0 else {
            error = "Enter at least one valid amount."
            return
        }
        let dateStr = dateString(entryDate)
        error = nil
        do {
            if mainAmt >= 0 {
                try await vm.submit(showroomId: sId, cashAmount: mainAmt,
                                    notes: mainNotes.isEmpty ? nil : mainNotes,
                                    cashAccountType: "main", entryDate: dateStr)
            }
            if manoAmt >= 0 {
                try await vm.submit(showroomId: sId, cashAmount: manoAmt,
                                    notes: manoNotes.isEmpty ? nil : manoNotes,
                                    cashAccountType: "mano", entryDate: dateStr)
            }
            success = true
            mainAmount = ""; manoAmount = ""; mainNotes = ""; manoNotes = ""
            await vm.fetchMyHistory(cashAccountType: nil, refresh: true)
        } catch {
            self.error = error.localizedDescription
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

