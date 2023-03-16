import Foundation

extension URLCache {
  static var imageCache: URLCache {
    let cache = URLCache(memoryCapacity: 512 * 1024 * 1024, diskCapacity: 10 * 1000 * 1000 * 1000, diskPath: "imageCache")
    return cache
  }
}
