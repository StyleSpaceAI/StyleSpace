import AppDevUtils
import Foundation

enum RootStateStorage {
  static func stateFileURL() throws -> URL {
    let documentsDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    return documentsDirectory.appendingPathComponent("state.json")
  }

  static func readState() -> Root.State {
    do {
      let fileURL = try stateFileURL()
      let state: Root.State = try .fromFile(path: fileURL.path)
      log.info("Successfully read state")
      return state
    } catch {
      log.error("Error reading state: \(error)")
      return Root.State()
    }
  }

  static func saveState(_ state: Root.State) {
    do {
      let fileURL = try stateFileURL()
      try state.saveToFile(path: fileURL.path)
    } catch {
      log.error("Error saving state: \(error)")
    }
  }
}
