//
//  TestMusicTests.swift
//  TestMusicTests
//
//  Created by Stephen Bodnar on 3/11/23.
//

import XCTest
@testable import MusicPlayer

private final class MockPlayableItem: PlayableItem {
    let id: String
    var fileUrl: String
    
    init(id: String, fileUrl: String) {
        self.id = id
        self.fileUrl = fileUrl
    }
}

final class QueueTests: XCTestCase {
    
    func testSetItems() async {
        let items: [PlayableItem] = createMockQueue(count: 1000)
        let queue = Queue()
    
        let _ = await queue.set(items: items)
       
        let numberOfItems = await queue.numberOfItems()
        
        XCTAssertEqual(numberOfItems, 1000)
        let track1 = await queue.getTrack(at: 0)
        let track499 = await queue.getTrack(at: 499)
        let track999 = await queue.getTrack(at: 999)
        
        XCTAssertEqual(track1?.id, items.first?.id)
        XCTAssertEqual(track499?.id, items[499].id)
        XCTAssertEqual(track999?.id, items.last?.id)
    }
    
    func testReorder() async {
        let items: [PlayableItem] = createMockQueue(count: 1000)
        let queue = Queue()
    
        let _ = await queue.set(items: items)
        let numberOfItems = await queue.numberOfItems()
        XCTAssertEqual(numberOfItems, 1000)
        
        let thirdIndexItem = items[3]
        let tenthIndexItem = items[10]
        
        let _ = await queue.reorder(item: thirdIndexItem, afterItem: tenthIndexItem)
        
        // item at third index should now be reordered
        let tenthTrack = await queue.getTrack(at: 10)
        XCTAssertEqual(tenthTrack?.id, thirdIndexItem.id)
        
        // item at index 10 has moved up in queue
        let ninthTrack = await queue.getTrack(at: 9)
        XCTAssertEqual(ninthTrack?.id, tenthIndexItem.id)
    }
    
    func testQueue() async {
        let items: [PlayableItem] = createMockQueue(count: 20)
        let queue = Queue()
    
        let _ = await queue.set(items: items)
        
        let newItem = MockPlayableItem(id: "234", fileUrl: "...")
        let afterItem = items[19] // last item in queue
        
        let _ = await queue.insert(item: newItem, afterItem: afterItem)
        
        let twentiethTrack = await queue.getTrack(at: 20)
        XCTAssertEqual(twentiethTrack?.id, newItem.id)
    }
    
    func testShuffled() async {
        let items: [PlayableItem] = createMockQueue(count: 6)
        let queue = Queue()
    
        let _ = await queue.set(items: items)
        
        let firstTrack = await queue.getTrack(at: 0)
        let secondTrack = await queue.getTrack(at: 1)
        let thirdTrack = await queue.getTrack(at: 2)
        let fourthTrack = await queue.getTrack(at: 3)
        let fifthTrack = await queue.getTrack(at: 4)
        let sixthTrack = await queue.getTrack(at: 5)
        
        XCTAssertEqual(firstTrack?.id, "0")
        XCTAssertEqual(secondTrack?.id, "1")
        XCTAssertEqual(thirdTrack?.id, "2")
        XCTAssertEqual(fourthTrack?.id, "3")
        XCTAssertEqual(fifthTrack?.id, "4")
        XCTAssertEqual(sixthTrack?.id, "5")
        
        let originalItemsHash = hashForItems(items: items)
        
        let queueItemsHash = hashForItems(items: [firstTrack!, secondTrack!, thirdTrack!, fourthTrack!, fifthTrack!, sixthTrack!])
        
        // hash should be equal before shuffling
        XCTAssertEqual(originalItemsHash, queueItemsHash)
        
        var unshuffled: [PlayableItem] = []
        var newItems: [PlayableItem] = []
        
        let result = await queue.shuffle(fromItem: items[2])
        switch result {
        case .success(let successOperation):
            unshuffled = successOperation.unshuffledItems
            newItems = successOperation.allItems
        case .failure:
            break
        }
        
        // hash should now not be equal because other items in array changed
        XCTAssertNotEqual(originalItemsHash, hashForItems(items: newItems))
        
        let numberOfItemsAfter = await queue.numberOfItems()
        XCTAssertEqual(numberOfItemsAfter, 6)
        
        // first 3 items (up to index 2) should remain unchanged
        XCTAssertEqual(unshuffled[0].id, "0")
        XCTAssertEqual(unshuffled[1].id, "1")
        XCTAssertEqual(unshuffled[2].id, "2")
    }
    
    func testShuffled2() async {
        let items: [PlayableItem] = createMockQueue(count: 15)
        
        let queue = Queue()
        let _ = await queue.set(items: items)
        
        let initialNumberOfItems = await queue.numberOfItems()
        XCTAssertEqual(initialNumberOfItems, 15)
        
        let firstTrack = await queue.getTrack(at: 0)
        let secondTrack = await queue.getTrack(at: 1)
        let thirdTrack = await queue.getTrack(at: 2)
        let fourthTrack = await queue.getTrack(at: 3)
        let fifthTrack = await queue.getTrack(at: 4)
        let sixthTrack = await queue.getTrack(at: 5)
        let seventhTrack = await queue.getTrack(at: 6)
        let eighthTrack = await queue.getTrack(at: 7)
        let ninthTrack = await queue.getTrack(at: 8)
        let tenthTrack = await queue.getTrack(at: 9)
        let eleventhTrack = await queue.getTrack(at: 10)
        let twelfthTrack = await queue.getTrack(at: 11)
        let thirteenthTrack = await queue.getTrack(at: 12)
        let fourteenthTrack = await queue.getTrack(at: 13)
        let fifteenthTrack = await queue.getTrack(at: 14)
        
        XCTAssertEqual(firstTrack?.id, "0")
        XCTAssertEqual(secondTrack?.id, "1")
        XCTAssertEqual(thirdTrack?.id, "2")
        XCTAssertEqual(fourthTrack?.id, "3")
        XCTAssertEqual(fifthTrack?.id, "4")
        XCTAssertEqual(sixthTrack?.id, "5")
        XCTAssertEqual(seventhTrack?.id, "6")
        XCTAssertEqual(eighthTrack?.id, "7")
        XCTAssertEqual(ninthTrack?.id, "8")
        XCTAssertEqual(tenthTrack?.id, "9")
        XCTAssertEqual(eleventhTrack?.id, "10")
        XCTAssertEqual(twelfthTrack?.id, "11")
        XCTAssertEqual(thirteenthTrack?.id, "12")
        XCTAssertEqual(fourteenthTrack?.id, "13")
        XCTAssertEqual(fifteenthTrack?.id, "14")
        
        var unshuffled: [PlayableItem] = []
        var shuffledCount: Int?
        
        let result = await queue.shuffle(fromItem: items[9])
        switch result {
        case .success(let operationSuccess):
            unshuffled = operationSuccess.unshuffledItems
            shuffledCount = operationSuccess.shuffledItems.count
        case .failure:
            break
        }
        
        let newNumberOfItems = await queue.numberOfItems()
        XCTAssertEqual(newNumberOfItems, 15)
        XCTAssertEqual(shuffledCount, 5)
        XCTAssertEqual(unshuffled.count, 10)
        // first 10 items (up to index 9) should remain unchanged
        XCTAssertEqual(unshuffled[0].id, "0")
        XCTAssertEqual(unshuffled[1].id, "1")
        XCTAssertEqual(unshuffled[2].id, "2")
        XCTAssertEqual(unshuffled[3].id, "3")
        XCTAssertEqual(unshuffled[4].id, "4")
        XCTAssertEqual(unshuffled[5].id, "5")
        XCTAssertEqual(unshuffled[6].id, "6")
        XCTAssertEqual(unshuffled[7].id, "7")
        XCTAssertEqual(unshuffled[8].id, "8")
        XCTAssertEqual(unshuffled[9].id, "9")
    }
    
    func testNumberOfItems() async {
        let items: [PlayableItem] = createMockQueue(count: 30)
        let queue: Queue = Queue()
        
        let _ = await queue.set(items: items)
        
        let numberOfitems = await queue.numberOfItems()
        XCTAssertEqual(numberOfitems, 30)
    }
    
    func testInsert() async {
        let items: [PlayableItem] = createMockQueue(count: 10)
        let queue: Queue = Queue()
        
        let _ = await queue.set(items: items)
        let initialNumberOfitems = await queue.numberOfItems()
        XCTAssertEqual(initialNumberOfitems, 10)
        
        let itemToInsert = MockPlayableItem(id: "11", fileUrl: "-")
        
        // insert after item at index 3. so now it should be at index 4
        var newItemIndex: Int?
        var insertedItem: PlayableItem?
        let result = await queue.insert(item: itemToInsert, afterItem: items[3])
        switch result {
        case .success(let modificationSuccess):
            insertedItem = modificationSuccess.item
            newItemIndex = modificationSuccess.index
        case .failure:
            break
        }
        
        XCTAssertEqual(newItemIndex, 4)
        XCTAssertEqual(insertedItem?.id, itemToInsert.id)
        
        let newNumberOfItems = await queue.numberOfItems()
        XCTAssertEqual(newNumberOfItems, 11)
        let track3 = await queue.getTrack(at: 3)
        let track4 = await queue.getTrack(at: 4)
        let track5 = await queue.getTrack(at: 5)
        
        XCTAssertEqual(track3?.id, items[3].id)
        XCTAssertEqual(track4?.id, itemToInsert.id)
        XCTAssertEqual(track5?.id, items[4].id)
    }
    
    func testRemove() async {
        let items: [PlayableItem] = createMockQueue(count: 5)
        let queue: Queue = Queue()
        
        let _ = await queue.set(items: items)
        let initialNumberOfitems = await queue.numberOfItems()
        XCTAssertEqual(initialNumberOfitems, 5)
        
        let itemToRemove: PlayableItem = items[3]
        
        var removedItem: PlayableItem?
        var removedIndex: Int?
        
        let result = await queue.remove(item: itemToRemove)
        switch result {
        case .success(let modificationSuccess):
            removedItem = modificationSuccess.item
            removedIndex = modificationSuccess.index
        case .failure:
            break
        }
        
        let afterNumberOfItems = await queue.numberOfItems()
        XCTAssertEqual(removedItem?.id, itemToRemove.id)
        XCTAssertEqual(afterNumberOfItems, 4)
        XCTAssertEqual(removedIndex, 3)
        
        let track1 = await queue.getTrack(at: 0)
        let track2 = await queue.getTrack(at: 1)
        let track3 = await queue.getTrack(at: 2)
        let track4 = await queue.getTrack(at: 3)
        
        XCTAssertEqual(track1?.id, items[0].id)
        XCTAssertEqual(track2?.id, items[1].id)
        XCTAssertEqual(track3?.id, items[2].id)
        // we removed the 4th item. so the 4th index from the original array should have moved up to 3rd index now
        XCTAssertEqual(track4?.id, items[4].id)
    }
    
    func testAppend() async {
        let items: [PlayableItem] = createMockQueue(count: 5)
        let queue: Queue = Queue()
        
        let _ = await queue.set(items: items)
        let initialNumberOfitems = await queue.numberOfItems()
        XCTAssertEqual(initialNumberOfitems, 5)
        
        let initial5thTrack = await queue.getTrack(at: 4)
        XCTAssertEqual(initial5thTrack?.id, items[4].id)
        
        let itemToAppend: PlayableItem = MockPlayableItem(id: "6", fileUrl: "--")
        
        let _ = await queue.append(item: itemToAppend)
        
        
        // Now we have added 1 item
        let afterNumberOfItems = await queue.numberOfItems()
        XCTAssertEqual(afterNumberOfItems, 6)
        
        // previous indices should be the same
        let fifthTrack = await queue.getTrack(at: 4)
        let sixthTrack = await queue.getTrack(at: 5)
        XCTAssertEqual(fifthTrack?.id, items[4].id)
        XCTAssertEqual(sixthTrack?.id, itemToAppend.id)
    }
    
    func testPrepend() async {
        let items: [PlayableItem] = createMockQueue(count: 5)
        let queue: Queue = Queue()
        
        let _ = await queue.set(items: items)
        let initialNumberOfitems = await queue.numberOfItems()
        XCTAssertEqual(initialNumberOfitems, 5)
        
        let initial5thTrack = await queue.getTrack(at: 4)
        XCTAssertEqual(initial5thTrack?.id, items[4].id)
        
        let itemToPrepend: PlayableItem = MockPlayableItem(id: "6", fileUrl: "--")
        let _ = await queue.prepend(item: itemToPrepend)
        
        // Now we have added 1 item
        let afterNumberOfItems = await queue.numberOfItems()
        XCTAssertEqual(afterNumberOfItems, 6)
        
        // previous indices have increased by 1 since we prepended an item
        let track1 = await queue.getTrack(at: 0)
        let track2 = await queue.getTrack(at: 1)
        let track3 = await queue.getTrack(at: 2)
        let track4 = await queue.getTrack(at: 3)
        
        XCTAssertEqual(track1?.id, itemToPrepend.id)
        XCTAssertEqual(track2?.id, items[0].id)
        XCTAssertEqual(track3?.id, items[1].id)
        XCTAssertEqual(track4?.id, items[2].id)
    }
    
    func testGetTrackInvalidIndex() async {
        let items: [PlayableItem] = createMockQueue(count: 5)
        let queue: Queue = Queue()
        
        let _ = await queue.set(items: items)
        
        let track5 = await queue.getTrack(at: 4)
        let track6 = await queue.getTrack(at: 5)
        XCTAssertEqual(track5?.id, items[4].id)
        XCTAssertNil(track6)
    }
    
    private func createMockQueue(count: Int) -> [PlayableItem] {
        var items: [PlayableItem] = []
        for i in 0..<count {
            let mockPlayableItem = MockPlayableItem(id: "\(i)", fileUrl: "file-url-string")
            items.append(mockPlayableItem)
        }
        
        return items
    }
    
    private func hashForItems(items: [PlayableItem]) -> [Int] {
        return items.map { $0.id.hashValue }
    }
}
