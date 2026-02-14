import SwiftUI

/// View modifier for displaying error alerts
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: AppError?
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        content
            .alert(
                error?.title ?? "Error",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { onDismiss() } }
                ),
                actions: {
                    Button("OK", role: .cancel) {
                        onDismiss()
                    }
                },
                message: {
                    if let error = error {
                        Text(error.message)
                    }
                }
            )
    }
}

extension View {
    /// Displays an error alert when an error is present
    /// - Parameters:
    ///   - error: Binding to optional AppError
    ///   - onDismiss: Closure called when alert is dismissed
    func errorAlert(error: Binding<AppError?>, onDismiss: @escaping () -> Void) -> some View {
        modifier(ErrorAlertModifier(error: error, onDismiss: onDismiss))
    }
}
