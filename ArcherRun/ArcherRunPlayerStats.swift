import Foundation
import SpriteKit

let kSoundState = "kSoundState"

enum SoundFileName: String {
    case hurtMan = "hurt-human.mp3"
    case Background = "theme.mp3"
    case hurtMamute = "hurt-mammuth.mp3"
    case bowShot = "sound-bow.mp3"
    case soundMamute = "sound-mammuth.mp3"
}

class ArcherRunPlayerStats {
    private init() {}
    
    static let shared = ArcherRunPlayerStats()
    
    func setSounds(_ state: Bool){
        UserDefaults.standard.setValue(state, forKey: kSoundState)
        UserDefaults.standard.synchronize()
    }
    
    func getSound() -> Bool {
        return UserDefaults.standard.bool(forKey: kSoundState)
    }
}
