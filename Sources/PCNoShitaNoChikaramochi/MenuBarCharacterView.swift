import SwiftUI

struct MenuBarCharacterView: View {
    @ObservedObject var animator: CharacterAnimator

    var body: some View {
        CharacterIcon(state: animator.state, phase: animator.phase)
            .padding(.horizontal, 1)
    }
}
