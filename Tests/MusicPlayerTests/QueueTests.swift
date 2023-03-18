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
    
  /*  func testShuffled2() {
        let items: [PlayableItem] = createMockQueue(count: 15)
        
        let queue = Queue()
    
        let setItemsExpectation = self.expectation(description: "wait")
        queue.set(items: items) { queue, items in
            setItemsExpectation.fulfill()
        }
       
        wait(for: [setItemsExpectation], timeout: 5)
        XCTAssertEqual(queue.numberOfItems, 15)
        XCTAssertEqual(queue.getTrack(at: 0)?.id, "0")
        XCTAssertEqual(queue.getTrack(at: 1)?.id, "1")
        XCTAssertEqual(queue.getTrack(at: 2)?.id, "2")
        XCTAssertEqual(queue.getTrack(at: 3)?.id, "3")
        XCTAssertEqual(queue.getTrack(at: 4)?.id, "4")
        XCTAssertEqual(queue.getTrack(at: 5)?.id, "5")
        XCTAssertEqual(queue.getTrack(at: 6)?.id, "6")
        XCTAssertEqual(queue.getTrack(at: 7)?.id, "7")
        XCTAssertEqual(queue.getTrack(at: 8)?.id, "8")
        XCTAssertEqual(queue.getTrack(at: 9)?.id, "9")
        XCTAssertEqual(queue.getTrack(at: 10)?.id, "10")
        XCTAssertEqual(queue.getTrack(at: 11)?.id, "11")
        XCTAssertEqual(queue.getTrack(at: 12)?.id, "12")
        XCTAssertEqual(queue.getTrack(at: 13)?.id, "13")
        XCTAssertEqual(queue.getTrack(at: 14)?.id, "14")
        
        let shuffleExpectation1 = self.expectation(description: "wait")
        var unshuffled: [PlayableItem] = []
        var shuffledCount: Int?
        
        queue.shuffle(fromItem: items[9]) { queue, unshuffledItems, shuffledItems, allItems in
            unshuffled = unshuffledItems
            shuffledCount = shuffledItems.count
            shuffleExpectation1.fulfill()
        }
        
        wait(for: [shuffleExpectation1], timeout: 5)
        
        XCTAssertEqual(queue.numberOfItems, 15)
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
    
    func testNumberOfItems() {
        let items: [PlayableItem] = createMockQueue(count: 30)
        let queue: Queue = Queue()
        
        let expectation1 = self.expectation(description: "wait")
        queue.set(items: items) { queue, items in
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 5)
        XCTAssertEqual(queue.numberOfItems, 30)
    }
    
    func testInsert() {
        let items: [PlayableItem] = createMockQueue(count: 10)
        let queue: Queue = Queue()
        
        let setQueueExpectation = self.expectation(description: "wait")
        queue.set(items: items) { queue, items in
            setQueueExpectation.fulfill()
        }
        
        wait(for: [setQueueExpectation], timeout: 5)
        
        XCTAssertEqual(queue.numberOfItems, 10)
        
        let expectation = self.expectation(description: "wait")
        let itemToInsert = MockPlayableItem(id: "11", fileUrl: "-")
        
        // insert after item at index 3. so now it should be at index 4
        var newItemIndex: Int?
        var insertedItem: PlayableItem?
        queue.insert(item: itemToInsert, afterItem: items[3]) { queue, item, index in
            insertedItem = item
            newItemIndex = index
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
        
        XCTAssertEqual(newItemIndex, 4)
        XCTAssertEqual(insertedItem?.id, itemToInsert.id)
        XCTAssertEqual(queue.numberOfItems, 11)
        XCTAssertEqual(queue.getTrack(at: 3)?.id, items[3].id)
        XCTAssertEqual(queue.getTrack(at: 4)?.id, itemToInsert.id)
        XCTAssertEqual(queue.getTrack(at: 5)?.id, items[4].id)
    }
    
    func testRemove() {
        let items: [PlayableItem] = createMockQueue(count: 5)
        let queue: Queue = Queue()
        
        let setQueueExpectation = self.expectation(description: "wait")
        queue.set(items: items) { queue, items in
            setQueueExpectation.fulfill()
        }
        
        wait(for: [setQueueExpectation], timeout: 5)
        
        XCTAssertEqual(queue.numberOfItems, 5)
        
        let itemToRemove: PlayableItem = items[3]
        let removeExpectation = self.expectation(description: "wait")
        var removedItem: PlayableItem?
        var removedIndex: Int?
        
        queue.remove(item: itemToRemove) { queue, item, index in
            removedItem = item
            removedIndex = index
            removeExpectation.fulfill()
        }
        
        wait(for: [removeExpectation], timeout: 5)
        
        XCTAssertEqual(removedItem?.id, itemToRemove.id)
        XCTAssertEqual(queue.numberOfItems, 4)
        XCTAssertEqual(removedIndex, 3)
        
        XCTAssertEqual(queue.getTrack(at: 0)?.id, items[0].id)
        XCTAssertEqual(queue.getTrack(at: 1)?.id, items[1].id)
        XCTAssertEqual(queue.getTrack(at: 2)?.id, items[2].id)
        // we removed the 4th item. so the 4th index from the original array should have moved up to 3rd index now
        XCTAssertEqual(queue.getTrack(at: 3)?.id, items[4].id)
    }
    
    func testAppend() {
        let items: [PlayableItem] = createMockQueue(count: 5)
        let queue: Queue = Queue()
        
        let setQueueExpectation = self.expectation(description: "wait")
        queue.set(items: items) { queue, items in
            setQueueExpectation.fulfill()
        }
        
        wait(for: [setQueueExpectation], timeout: 5)
        
        XCTAssertEqual(queue.getTrack(at: 4)?.id, items[4].id)
        XCTAssertEqual(queue.numberOfItems, 5)
        
        let itemToAppend: PlayableItem = MockPlayableItem(id: "6", fileUrl: "--")
        let appendExpectation = self.expectation(description: "wait")
        queue.append(item: itemToAppend) { queue, item in
            appendExpectation.fulfill()
        }
        
        wait(for: [appendExpectation], timeout: 5)
        
        // Now we have added 1 item
        XCTAssertEqual(queue.numberOfItems, 6)
        // previous indices should be the same
        XCTAssertEqual(queue.getTrack(at: 4)?.id, items[4].id)
        XCTAssertEqual(queue.getTrack(at: 5)?.id, itemToAppend.id)
    }
    
    func testPrepend() {
        let items: [PlayableItem] = createMockQueue(count: 5)
        let queue: Queue = Queue()
        
        let setQueueExpectation = self.expectation(description: "wait")
        queue.set(items: items) { queue, items in
            setQueueExpectation.fulfill()
        }
        
        wait(for: [setQueueExpectation], timeout: 5)
        
        XCTAssertEqual(queue.getTrack(at: 4)?.id, items[4].id)
        XCTAssertEqual(queue.numberOfItems, 5)
        
        let itemToPrepend: PlayableItem = MockPlayableItem(id: "6", fileUrl: "--")
        let appendExpectation = self.expectation(description: "wait")
        queue.prepend(item: itemToPrepend) { queue, item in
            appendExpectation.fulfill()
        }
        
        wait(for: [appendExpectation], timeout: 5)
        
        // Now we have added 1 item
        XCTAssertEqual(queue.numberOfItems, 6)
        // previous indices have increased by 1 since we prepended an item
        XCTAssertEqual(queue.getTrack(at: 0)?.id, itemToPrepend.id)
        XCTAssertEqual(queue.getTrack(at: 1)?.id, items[0].id)
        XCTAssertEqual(queue.getTrack(at: 2)?.id, items[1].id)
        XCTAssertEqual(queue.getTrack(at: 3)?.id, items[2].id)
    }
    
    func testGetTrackInvalidIndex() {
        let items: [PlayableItem] = createMockQueue(count: 5)
        let queue: Queue = Queue()
        
        let setQueueExpectation = self.expectation(description: "wait")
        await queue.set(items: items) { queue, items in
            setQueueExpectation.fulfill()
        }
        
        wait(for: [setQueueExpectation], timeout: 5)
        
        XCTAssertEqual(queue.getTrack(at: 4)?.id, items[4].id)
        XCTAssertNil(queue.getTrack(at: 5))
    }*/
    
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
