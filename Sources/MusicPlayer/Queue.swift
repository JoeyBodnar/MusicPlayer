//
//  Queue.swift
//  TestMusic
//
//  Created by Stephen Bodnar on 3/12/23.
//

import Foundation

protocol QueueInterface: AnyObject {
    func append(item: PlayableItem, completion: (_ queue: Queue, _ item: PlayableItem) -> Void)
    func prepend(item: PlayableItem, completion: (_ queue: Queue, _ item: PlayableItem) -> Void)
    func insert(item: PlayableItem, afterItem: PlayableItem, completion: (_ queue: Queue, _ item: PlayableItem, _ index: Int) -> Void)
    func set(items: [PlayableItem], completion: (_ queue: Queue, _ items: [PlayableItem]) -> Void)
    func reorder(item: PlayableItem, afterItem otherItem: PlayableItem, completion: ((_ result: QueueReorderOperationResult) -> Void))
    func remove(item: PlayableItem, completion: (_ queue: Queue, _ item: PlayableItem, _ index: Int) -> Void)
    func shuffle(fromItem item: PlayableItem, completion: (_ queue: Queue, _ unshuffledItems: [PlayableItem], _ shuffledItems: [PlayableItem], _ allItems: [PlayableItem]) -> Void)
    
    func getTrack(at index: Int) -> PlayableItem?
    
    var numberOfItems: Int { get }
}

enum QueueReorderOperationResult {
    case success(queue: Queue, item: PlayableItem, newIndex: Int)
    case failure(type: QueueReorderOperationFailureType)
}

enum QueueReorderOperationFailureType {
    case indexOfItemToReorderNotFound
    case indexOfOtherItemNotFound
}

final class Queue: QueueInterface {
    private var items: [PlayableItem] = []
    
    private let modificationQueue: DispatchQueue = DispatchQueue(label: "com.queue.queueModification")
    
    var numberOfItems: Int {
        return items.count
    }
    
    func append(item: PlayableItem, completion: (_ queue: Queue, _ item: PlayableItem) -> Void) {
        modificationQueue.sync {
            self.items.append(item)
            completion(self, item)
        }
    }
    
    func prepend(item: PlayableItem, completion: (_ queue: Queue, _ item: PlayableItem) -> Void) {
        modificationQueue.sync {
            self.items = [item] + self.items
            completion(self, item)
        }
    }
    
    func insert(item: PlayableItem, afterItem: PlayableItem, completion: (_ queue: Queue, _ item: PlayableItem, _ index: Int) -> Void) {
        if let index = indexOf(item: afterItem) {
            modificationQueue.sync {
                let proposedIndex: Int = index + 1
                if proposedIndex > self.items.count { // return, invalid index
                    return
                } else {
                    self.items.insert(item, at: proposedIndex)
                    completion(self, item, proposedIndex)
                }
            }
        }
    }
    
    func set(items: [PlayableItem], completion: (_ queue: Queue, _ items: [PlayableItem]) -> Void) {
        modificationQueue.sync {
            self.items = items
            completion(self, items)
        }
    }
    
    func reorder(item: PlayableItem, afterItem otherItem: PlayableItem, completion: ((_ result: QueueReorderOperationResult) -> Void)) {
        if let indexOfItemToReorder = self.indexOf(item: item) {
            modificationQueue.sync {
                self.items.remove(at: indexOfItemToReorder)
                if let indexOfOtherItem = self.indexOf(item: otherItem) {
                    // add 1 because the array `insert(at..)` prepends
                    let proposedIndex = indexOfOtherItem + 1
                    if proposedIndex > self.items.count { // revert
                        self.items.insert(item, at: indexOfItemToReorder)
                        return
                    } else {
                        self.items.insert(item, at: proposedIndex)
                        completion(.success(queue: self, item: item, newIndex: proposedIndex))
                    }
                } else {
                    // theoretically should not happen. but if it does then we will
                    // just revert the change
                    self.items.insert(item, at: indexOfItemToReorder)
                    completion(.failure(type: QueueReorderOperationFailureType.indexOfOtherItemNotFound))
                }
            }
        } else {
            completion(.failure(type: QueueReorderOperationFailureType.indexOfItemToReorderNotFound))
        }
    }
    
    func remove(item: PlayableItem, completion: (_ queue: Queue, _ item: PlayableItem, _ index: Int) -> Void) {
        if let index = indexOf(item: item) {
            modificationQueue.sync {
                self.items.remove(at: index)
                completion(self, item, index)
            }
        }
    }
    
    /// shuffle all songs **after** this item
    func shuffle(fromItem item: PlayableItem, completion: (_ queue: Queue, _ unshuffledItems: [PlayableItem], _ shuffledItems: [PlayableItem], _ allItems: [PlayableItem]) -> Void) {
        if let index = indexOf(item: item) {
            modificationQueue.sync {
                let indexToBeginShuffle = index + 1 // keep starting index in place
                let itemsNotToShuffle: [PlayableItem] = Array(items.prefix(indexToBeginShuffle))
                let itemsToShuffle: [PlayableItem] = Array(items.suffix(numberOfItems - (indexToBeginShuffle)))
                
                let shuffled: [PlayableItem] = itemsToShuffle.shuffled()
                let newItems: [PlayableItem] = itemsNotToShuffle + shuffled
                self.items = newItems
                completion(self, itemsNotToShuffle, shuffled, newItems)
            }
        }
    }
    
    // MARK: - Helpers
    
    func getTrack(at index: Int) -> PlayableItem? {
        guard index < items.count  else {
            return nil
        }
        
        return items[index]
    }
    
    // MARK: - Private
    
    private func indexOf(item: PlayableItem) -> Int? {
        return items.firstIndex(where: { playerItem in
            return playerItem.id == item.id
        })
    }
}
