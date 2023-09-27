import Foundation
import SpriteKit

let kSoundState = "kSoundState"

enum SoundFileName: String {
    case TapFile = "explosion.mp3"
    case Background = "backgroudMusic"
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
