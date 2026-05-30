import SwiftUI

struct SubmitEditRequestView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm = EditRequestViewModel()

    let entryType: String      // "cash" or "card"
    let entryId: Int
    let originalAmount: Double
    let originalNotes: String?

    @State private var newAmount = ""
    @State private var newNotes  = ""
    @State private var reason    = ""
    @State private var customReason = ""
    @State private var error: String?
    @State private var success = false

    private let reasonChips = [
        "Wrong amount entered",
        "Missed entry",
        "Duplicate entry",
        "Other"
    ]

    private var effectiveReason: String {
        reason == "Other" ? customReason : reason
    }

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
                            Text("Edit request submitted")
                                .font(.system(size: 14)).foregroundStyle(Color.mmSuccess)
                        }
                        .padding(12).background(Color.mmSuccess.opacity(0.1)).cornerRadius(10)
                    }

                    // Original values (read-only)
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Original Entry", systemImage: "doc.text")
                            .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.mmPrimary)
                        HStack {
                            Text("Type").font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                            Spacer()
                            Text(entryType.capitalized + " Entry #\(entryId)")
                                .font(.system(size: 12, weight: .medium))
                        }
                        HStack {
                            Text("Amount").font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                            Spacer()
                            Text(originalAmount.currency)
                                .font(.system(size: 13, weight: .bold)).foregroundStyle(Color.mmPrimary)
                        }
                        if let n = originalNotes {
                            HStack {
                                Text("Notes").font(.system(size: 12)).foregroundStyle(Color.mmTextSecondary)
                                Spacer()
                                Text(n).font(.system(size: 12))
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.mmCard)
                    .cornerRadius(14)

                    // Requested changes
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Requested Changes", systemImage: "pencil.circle")
                            .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.mmPrimary)
                        MMTextField(label: "New Amount (leave blank to keep original)",
                                    text: $newAmount, placeholder: originalAmount.currency,
                                    keyboardType: .decimalPad, autocapitalization: .never)
                        MMTextField(label: "New Notes (leave blank to keep original)",
                                    text: $newNotes, placeholder: originalNotes ?? "")
                    }
                    .padding(16)
                    .background(Color.mmCard)
                    .cornerRadius(14)

                    // Reason
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Reason", systemImage: "text.bubble")
                            .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.mmPrimary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(reasonChips, id: \.self) { chip in
                                Button {
                                    reason = chip
                                } label: {
                                    Text(chip)
                                        .font(.system(size: 12, weight: reason == chip ? .semibold : .regular))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 10).padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(reason == chip ? Color.mmPrimary : Color.mmCard)
                                        .foregroundStyle(reason == chip ? .white : Color.mmTextPrimary)
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(
                                            reason == chip ? Color.clear : Color.mmDivider))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        if reason == "Other" {
                            MMTextField(label: "Describe reason", text: $customReason,
                                        placeholder: "Explain why…")
                        }
                    }
                    .padding(16)
                    .background(Color.mmCard)
                    .cornerRadius(14)

                    MMButton(title: "Submit Edit Request", isLoading: vm.isSubmitting) {
                        Task { await submit() }
                    }
                    .disabled(reason.isEmpty || (reason == "Other" && customReason.trimmingCharacters(in: .whitespaces).isEmpty))
                }
                .padding(20)
            }
            .background(Color.mmBackground)
            .navigationTitle("Edit Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func submit() async {
        guard !effectiveReason.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Please select or enter a reason."
            return
        }
        var changes: [String: Any] = [:]
        if let amt = Double(newAmount), amt > 0 {
            changes[entryType == "cash" ? "cash_amount" : "amount"] = amt
        }
        if !newNotes.trimmingCharacters(in: .whitespaces).isEmpty {
            changes["notes"] = newNotes
        }
        if changes.isEmpty {
            error = "Enter at least one change (new amount or notes)."
            return
        }
        error = nil
        do {
            if entryType == "cash" {
                try await vm.submitCashEditRequest(
                    cashEntryId: entryId, changes: changes, reason: effectiveReason
                )
            } else {
                try await vm.submitCardEditRequest(
                    cardEntryId: entryId, changes: changes, reason: effectiveReason
                )
            }
            success = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
