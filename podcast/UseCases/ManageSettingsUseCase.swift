//
//  UpdateSettingsUseCase.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/27/26.
//

import Foundation

struct ManageSettingsUseCase {
    let repository: SettingsRepository
    
    // 1. Generic Read
    func get<Value>(_ keyPath: KeyPath<UserSettings, Value>) -> Value {
        // We read directly from the repository's settings instance
        return repository.settings[keyPath: keyPath]
    }

    // Same clean KeyPath signature
    func execute<Value>(_ keyPath: WritableKeyPath<UserSettings, Value>, to newValue: Value) {
        // You can add global logic here later if needed (e.g., logging, analytics)
        repository.update(keyPath, to: newValue)
    }
}
