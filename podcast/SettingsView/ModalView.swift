//
//  ModalView.swift
//  podcast
//
//  Created by Matt Wittbrodt on 1/19/26.
//

import SwiftUI

struct ModalView: View {
    let action: SettingsAction
    let onConfirm: () -> Void
    @Environment(\.dismiss) var dismiss // To close the modal
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon changes based on the action
            Image(systemName: action == .deleteDownloads ? "trash" : "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
                .padding(.top, 40)
            
            Text(action.title)
                .font(.headline)
            
            Text("Are you sure you want to proceed? This action cannot be undone.")
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            // Confirm Button
            Button(role: .destructive) {
                onConfirm()
                dismiss()
            } label: {
                Text("Confirm and Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            // Cancel Button
            Button("Cancel") {
                dismiss()
            }
            .padding(.bottom, 20)
        }
        .padding()
        .presentationDetents([.fraction(0.4)]) // Makes the modal only take up half the screen
    }
}

#Preview {
    ModalView(action: SettingsAction.deleteDownloads) {}
}
