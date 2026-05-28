//
//  PlayerViewModel.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/27/26.
//

import Foundation

@MainActor
class PlayerViewModel: ObservableObject {
    
    private let useCase: ManageSettingsUseCase
    
    init(useCase: ManageSettingsUseCase) {
        self.useCase = useCase
    }

    var forwardSkip: Int16 {
        get { useCase.get(\UserSettings.forwardSkip) }
    }
    
    var backwardSkip: Int16 {
        get { useCase.get(\UserSettings.forwardSkip) }
    }
}
