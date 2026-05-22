import SwiftUI

struct MenuBarCharacterView: View {
    @ObservedObject var animator: CharacterAnimator
    @ObservedObject var store: AppearanceStore

    var body: some View {
        CharacterIcon(state: animator.state, phase: animator.phase, appearance: store.snapshot)
            .padding(.horizontal, 1)
    }
}
