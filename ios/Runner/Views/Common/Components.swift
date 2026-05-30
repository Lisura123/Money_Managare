import SwiftUI

// MARK: - Primary button

struct MMButton: View {
    let title: String
    var isLoading: Bool = false
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDestructive ? Color.mmError : Color.mmPrimary)
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .disabled(isLoading)
    }
}

// MARK: - Text field

struct MMTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    @State private var showPassword = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.mmTextSecondary)

            ZStack(alignment: .trailing) {
                Group {
                    if isSecure && !showPassword {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                            .textInputAutocapitalization(autocapitalization)
                    }
                }
                .padding(14)
                .background(Color.mmInputFill)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.mmDivider, lineWidth: 1)
                )

                if isSecure {
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    .padding(.trailing, 14)
                }
            }
        }
    }
}

// MARK: - Stat card

struct StatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var color: Color = .mmAccent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.mmTextSecondary)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(color)
            if let s = subtitle {
                Text(s)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mmTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.mmCard)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Row card

struct RowCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mmCard)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Status badge

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.capitalized)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .cornerRadius(6)
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(Color.mmTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Loading overlay

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            ProgressView()
                .padding(24)
                .background(Color.mmCard)
                .cornerRadius(16)
        }
    }
}

// MARK: - Error banner

struct ErrorBanner: View {
    let message: String
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.mmError)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Color.mmError)
            Spacer()
            if let dismiss = onDismiss {
                Button(action: dismiss) {
                    Image(systemName: "xmark").foregroundStyle(Color.mmTextSecondary)
                }
            }
        }
        .padding(12)
        .background(Color.mmError.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.mmTextSecondary)
            .padding(.horizontal, 4)
    }
}

// MARK: - Divider

struct MMDivider: View {
    var body: some View {
        Divider().overlay(Color.mmDivider)
    }
}

// MARK: - Avatar

struct AvatarView: View {
    let initials: String
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.mmAccent.opacity(0.2))
                .frame(width: size, height: size)
            Text(initials)
                .font(.system(size: size * 0.35, weight: .bold))
                .foregroundStyle(Color.mmPrimary)
        }
    }
}
