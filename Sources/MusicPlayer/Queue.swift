//
//  Queue.swift
//  TestMusic
//
//  Created by Stephen Bodnar on 3/12/23.
//

import Foundation

protocol QueueInterface: Actor {
    func append(item: QueueItem) -> QueueModificationSuccess
    func prepend(item: QueueItem) -> QueueModificationSuccess
    func insert(item: QueueItem, afterItem: QueueItem) -> Result<QueueModificationSuccess, QueueInsertionFailure>
    func set(items: [QueueItem]) -> (queue: Queue, items: [QueueItem])
    func reorder(item: QueueItem, afterItem otherItem: QueueItem) -> Result<QueueReorderOperationSuccess, QueueReorderOperationFailureType>
    func remove(item: QueueItem) -> Result<QueueModificationSuccess, QueueRemoveOperationFailureType>
    func shuffle(fromItem item: QueueItem) -> Result<QueueShuffleOperationSuccess, QueueShuffleFailure>
    
    func getTrack(at index: Int) -> QueueItem?
    
    func numberOfItems() -> Int
}

enum QueueReorderOperationFailureType: Error {
    case indexOfItemToReorderNotFound
    case indexOfOtherItemNotFound
    case indexOutOfRange
}

struct QueueReorderOperationSuccess {
    /// the queue the item was inserted in
    let queue: Queue
    
    /// the item that was inserted
    let item: QueueItem
    
    /// the index where the item was inserted
    let index: Int
    
    /// the index where the item was previously, before being reordered
    let previousIndex: Int
}

struct QueueModificationSuccess {
    /// the queue the item was inserted in
    let queue: Queue
    
    /// the item which modified the queue. For appending, prepending, and inserting, this was the item that was added.
    /// for removing, this was the item that was removed
    let item: QueueItem
    
    /// the index modified. for appending, prepending, and inserting, this was the index where the `item` property is now placed int he array
    /// for removing, this is the index the item was at before it was removed
    let index: Int
}

enum QueueRemoveOperationFailureType: Error {
    case indexNotFound
}

enum QueueInsertionFailure: Error {
    /// the index where the item was attempted to be inserted was not found
    case indexNotFound
}

public struct QueueShuffleOperationSuccess {
    let queue: Queue
    let unshuffledItems: [QueueItem]
    let shuffledItems: [QueueItem]
    let allItems: [QueueItem]
}

public enum QueueShuffleFailure: Error {
    /// the index to start shuffling from was not found
    case indexNotFound
}

actor Queue: QueueInterface {
    private var items: [QueueItem] = []
    
    func numberOfItems() -> Int {
        return items.count
    }
    
    func append(item: QueueItem) -> QueueModificationSuccess {
        self.items.append(item)
        return QueueModificationSuccess(queue: self, item: item, index: items.count - 1)
    }
    
    func prepend(item: QueueItem) -> QueueModificationSuccess {
        self.items = [item] + self.items
        return QueueModificationSuccess(queue: self, item: item, index: 0)
    }
    
    func insert(item: QueueItem, afterItem: QueueItem) -> Result<QueueModificationSuccess, QueueInsertionFailure> {
        if let index = indexOf(item: afterItem) {
            let proposedIndex: Int = index + 1 // add 1, because the `insert` api for Swift arrays inserts the item **before** but we want to insert after
            if proposedIndex > self.items.count { // invalid index
                return Result.failure(QueueInsertionFailure.indexNotFound)
            } else {
                self.items.insert(item, at: proposedIndex)
                return Result.success(QueueModificationSuccess(queue: self, item: item, index: proposedIndex))
            }
        }
        
        return Result.failure(QueueInsertionFailure.indexNotFound)
    }
    
    func set(items: [QueueItem]) -> (queue: Queue, items: [QueueItem]) {
        self.items = items
        return (self, items)
    }
    
    func reorder(item: QueueItem, afterItem otherItem: QueueItem) -> Result<QueueReorderOperationSuccess, QueueReorderOperationFailureType> {
        if let indexOfItemToReorder = self.indexOf(item: item) {
            self.items.remove(at: indexOfItemToReorder)
            if let indexOfOtherItem = self.indexOf(item: otherItem) {
                // add 1 because the array `insert(at..)` prepends
                let proposedIndex = indexOfOtherItem + 1
                if proposedIndex > self.items.count { // revert
                    self.items.insert(item, at: indexOfItemToReorder)
                    return Result.failure(QueueReorderOperationFailureType.indexOutOfRange)
                } else {
                    self.items.insert(item, at: proposedIndex)
                    return Result.success(QueueReorderOperationSuccess(queue: self, item: item, index: proposedIndex, previousIndex: indexOfItemToReorder))
                }
            } else {
                // theoretically should not happen. but if it does then we will
                // just revert the change
                self.items.insert(item, at: indexOfItemToReorder)
                return Result.failure(QueueReorderOperationFailureType.indexOfOtherItemNotFound)
            }
        } else {
            return Result.failure(QueueReorderOperationFailureType.indexOfItemToReorderNotFound)
        }
    }
    
    func remove(item: QueueItem) -> Result<QueueModificationSuccess, QueueRemoveOperationFailureType> {
        if let index = indexOf(item: item) {
            self.items.remove(at: index)
            return Result.success(QueueModificationSuccess(queue: self, item: item, index: index))
        }
        
        return .failure(QueueRemoveOperationFailureType.indexNotFound)
    }
    
    /// shuffle all songs **after** this item
    func shuffle(fromItem item: QueueItem) -> Result<QueueShuffleOperationSuccess, QueueShuffleFailure> {
        if let index = indexOf(item: item) {
            let indexToBeginShuffle = index + 1 // keep starting index in place
            let itemsNotToShuffle: [QueueItem] = Array(items.prefix(indexToBeginShuffle))
            let itemsToShuffle: [QueueItem] = Array(items.suffix(numberOfItems() - (indexToBeginShuffle)))
            
            let shuffled: [QueueItem] = itemsToShuffle.shuffled()
            let newItems: [QueueItem] = itemsNotToShuffle + shuffled
            self.items = newItems
            return Result.success(QueueShuffleOperationSuccess(queue: self, unshuffledItems: itemsNotToShuffle, shuffledItems: shuffled, allItems: newItems))
        }
        return Result.failure(QueueShuffleFailure.indexNotFound)
    }
    
    // MARK: - Helpers
    
    func getTrack(at index: Int) -> QueueItem? {
        guard index < items.count  else {
            return nil
        }
        
        return items[index]
    }
    
    // MARK: - Private
    
    private func indexOf(item: QueueItem) -> Int? {
        return items.firstIndex(where: { playerItem in
            return playerItem.id == item.id
        })
    }
}
