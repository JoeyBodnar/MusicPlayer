//
//  MusicPlayer.swift
//  
//
//  Created by Stephen Bodnar on 3/18/23.
//

import XCTest
@testable import MusicPlayer

final class MusicPlayerTests: XCTestCase {
    
    func testPlayAVPlayerSetsPlayingStateToPlaying() {
        let player = MusicPlayer()
        
        XCTAssertEqual(player.playingState, .paused)
        
        player.playAVPlayer()
        
        XCTAssertEqual(player.playingState, .playing)
    }
    
    func testPauseSetsPlayerStateAndInvokesDelegate() {
        let player = MusicPlayer()
        let mockDelegate = MockMusicPlayerDelegate()
        player.delegate = mockDelegate
        XCTAssertEqual(player.playingState, .paused)
        XCTAssertEqual(mockDelegate.pauseDelegateInvoked, false)
        
        player.playAVPlayer()
        
        XCTAssertEqual(player.playingState, .playing)
        XCTAssertEqual(mockDelegate.pauseDelegateInvoked, false)
        
        player.pause()
        XCTAssertEqual(mockDelegate.pauseDelegateInvoked, true)
        
        XCTAssertEqual(player.playingState, .paused)
    }
    
    func testSetItems() async {
        let items: [QueueItem] = createMockQueue(count: 100)
        let player = MusicPlayer()
        let mockDelegate = MockMusicPlayerDelegate()
        player.delegate = mockDelegate
        
        XCTAssertFalse(mockDelegate.musicPlayerDidSetItems)
        
        let _ = await player.set(items: items)
        
        XCTAssertTrue(mockDelegate.musicPlayerDidSetItems)
    }
    
    func testPlayFromStartIndex() async{
        let items: [QueueItem] = createMockQueue(count: 100)
        let player = MusicPlayer()
        let mockDelegate = MockMusicPlayerDelegate()
        player.delegate = mockDelegate
        
        XCTAssertFalse(mockDelegate.musicPlayerDidSetItems)
        let _ = await player.set(items: items)
        
        await player.play(startIndex: 5)
        XCTAssertEqual(player.currentTrack, 5)
        XCTAssertTrue(mockDelegate.didBeginPlaybackForItemInvoked)
    }
    
    func testQueueModeSet() {
        let player = MusicPlayer()
        let mockDelegate = MockMusicPlayerDelegate()
        
        XCTAssertNil(mockDelegate.queueMode)
        player.queueMode = .repeatAll
        
        XCTAssertEqual(player.queueMode, .repeatAll)
    }
    
    func testShuffleModeSet() {
        let player = MusicPlayer()
        let mockDelegate = MockMusicPlayerDelegate()
        
        XCTAssertNil(mockDelegate.shuffleMode)
        player.shuffleMode = .on
        
        XCTAssertEqual(player.shuffleMode, .on)
    }
    
    func testGoBackToPreviousTrack() async {
        let player: MusicPlayer = MusicPlayer()
        let items = createMockQueue(count: 20)
        await player.set(items: items)
        await player.play(startIndex: 5)
        
        // should be 5 to start with
        XCTAssertEqual(player.currentTrack, 5)
        
        // right now `currentPlaybackTime` is 0, so it should go back to track 4
        await player.goBackToPreviousTrack()
        
        XCTAssertEqual(player.currentTrack, 4)
        
        // set to 3. if going back with <3 seconds then it should go to the previous track
        player.currentPlaybackTime = 3
        await player.goBackToPreviousTrack()
        
        XCTAssertEqual(player.currentTrack, 3)
        
        // set to 4. should not affect current track
        player.currentPlaybackTime = 4
        await player.goBackToPreviousTrack()
        
        XCTAssertEqual(player.currentTrack, 3)
    }
    
    func testGoToNextTrack() async {
        let player: MusicPlayer = MusicPlayer()
        let items = createMockQueue(count: 20)
        await player.set(items: items)
        await player.play(startIndex: 5)
        
        // should be 5 to start with
        XCTAssertEqual(player.currentTrack, 5)
        
        await player.advanceToNextTrack()
        XCTAssertEqual(player.currentTrack, 6)
        
        await player.advanceToNextTrack()
        XCTAssertEqual(player.currentTrack, 7)
        
        await player.advanceToNextTrack()
        XCTAssertEqual(player.currentTrack, 8)
        
        await player.advanceToNextTrack()
        XCTAssertEqual(player.currentTrack, 9)
        
        // Test advance beyond all tracks
        
        // queue has 20 items
        player.currentTrack = 19
        XCTAssertEqual(player.playingState, .playing)
        await player.advanceToNextTrack()
        XCTAssertEqual(player.playingState, .paused)
    }
    
    func testAppend() async {
        let player: MusicPlayer = MusicPlayer()
        let items = createMockQueue(count: 400)
        await player.set(items: items)
        await player.play(startIndex: 5)
        
        let count = await player.numberOfItems()
        XCTAssertEqual(count, 400)
        let trackAt400: QueueItem? = await player.getTrack(at: 400)
        XCTAssertNil(trackAt400)
        
        let itemToAppend: QueueItem = MockPlayableItem(id: "x", fileUrl: "...", fileExtension: "ext")
        await player.append(item: itemToAppend)
        
        let newCount: Int = await player.numberOfItems()
        XCTAssertEqual(newCount, 401)
        
        guard let track: QueueItem = await player.getTrack(at: 400) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(track.id, "x")
        XCTAssertEqual(track.fileUrl, "...")
        XCTAssertEqual(track.fileExtension, "ext")
    }
    
    func testPrepend() async {
        let player: MusicPlayer = MusicPlayer()
        let items = createMockQueue(count: 400)
        await player.set(items: items)
        await player.play(startIndex: 5)
        
        let count = await player.numberOfItems()
        XCTAssertEqual(count, 400)
        let firstTrack: QueueItem? = await player.getTrack(at: 0)
        XCTAssertEqual(firstTrack?.id, "0")
        
        let itemToPrepend: QueueItem = MockPlayableItem(id: "x", fileUrl: "...", fileExtension: "ext")
        await player.prepend(item: itemToPrepend)
        
        let newCount: Int = await player.numberOfItems()
        XCTAssertEqual(newCount, 401)
        
        guard let track: QueueItem = await player.getTrack(at: 0) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(track.id, "x")
        XCTAssertEqual(track.fileUrl, "...")
        XCTAssertEqual(track.fileExtension, "ext")
    }
    
    func testItemFinishedQueueModeRepeat1() async {
        let player: MusicPlayer = MusicPlayer()
        let items = createMockQueue(count: 400)
        await player.set(items: items)
        await player.play(startIndex: 5)
        
        player.queueMode = .repeatOne
        player.currentPlaybackTime = 50
        XCTAssertEqual(player.currentTrack, 5)
        
        await player.finished(notification: NSNotification(name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil))
        
        // current track should not have changed
        XCTAssertEqual(player.currentTrack, 5)
        // playback time should be set to 0
        XCTAssertEqual(player.currentPlaybackTime, 0)
    }
    
    func testItemFinishedQueueModeNormal() async {
        let player: MusicPlayer = MusicPlayer()
        let items = createMockQueue(count: 400)
        await player.set(items: items)
        await player.play(startIndex: 5)
        
        player.queueMode = .normal
        player.currentPlaybackTime = 50
        XCTAssertEqual(player.currentTrack, 5)
        
        await player.finished(notification: NSNotification(name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil))
        
        // current track should increase by 1
        XCTAssertEqual(player.currentTrack, 6)
        // playback time should be set to 0
        XCTAssertEqual(player.currentPlaybackTime, 0)
    }
    
    func testItemFinishedQueueModeRepeatAll() async {
        let player: MusicPlayer = MusicPlayer()
        let items = createMockQueue(count: 4)
        await player.set(items: items)
        await player.play(startIndex: 0)
        
        player.queueMode = .repeatAll
        XCTAssertEqual(player.currentTrack, 0)
        
        await player.finished(notification: NSNotification(name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil))
        
        // current track should increase by 1
        XCTAssertEqual(player.currentTrack, 1)
        XCTAssertEqual(player.currentPlaybackTime, 0)
        
        await player.finished(notification: NSNotification(name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil))
        
        XCTAssertEqual(player.currentTrack, 2)
        XCTAssertEqual(player.currentPlaybackTime, 0)
        
        await player.finished(notification: NSNotification(name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil))
        
        // current track should increase by 1
        XCTAssertEqual(player.currentTrack, 3)
        XCTAssertEqual(player.currentPlaybackTime, 0)
        
        await player.finished(notification: NSNotification(name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil))
        
        // current track should increase by 1
        XCTAssertEqual(player.currentTrack, 4)
        XCTAssertEqual(player.currentPlaybackTime, 0)
        
        await player.finished(notification: NSNotification(name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil))
        
        // end of queue, should go back to the end
        XCTAssertEqual(player.currentTrack, 0)
        XCTAssertEqual(player.currentPlaybackTime, 0)
    }
    
    func testInsert() async {
        let player: MusicPlayer = MusicPlayer()
        let items = createMockQueue(count: 4)
        await player.set(items: items)
        
        let numberOfItems = await player.numberOfItems()
        XCTAssertEqual(numberOfItems, 4)
        
        let item1before = await player.getTrack(at: 0)
        let item2before = await player.getTrack(at: 1)
        let item3before = await player.getTrack(at: 2)
        let item4before = await player.getTrack(at: 3)
        
        XCTAssertEqual(item1before?.id, "0")
        XCTAssertEqual(item2before?.id, "1")
        XCTAssertEqual(item3before?.id, "2")
        XCTAssertEqual(item4before?.id, "3")
        
        // then insert item
        let itemToInsert: QueueItem = MockPlayableItem(id: "inserted", fileUrl: "", fileExtension: "")
        await player.insert(item: itemToInsert, afterItem: item2before!)
        
        let newNumberOfItems = await player.numberOfItems()
        XCTAssertEqual(newNumberOfItems, 5)
        
        let item1after = await player.getTrack(at: 0)
        let item2after = await player.getTrack(at: 1)
        let item3after = await player.getTrack(at: 2)
        let item4after = await player.getTrack(at: 3)
        let item5after = await player.getTrack(at: 4)
        
        XCTAssertEqual(item1after?.id, "0")
        XCTAssertEqual(item2after?.id, "1")
        XCTAssertEqual(item3after?.id, "inserted")
        XCTAssertEqual(item4after?.id, "2")
        XCTAssertEqual(item5after?.id, "3")
    }
    
    func testReorder() async {
        let player: MusicPlayer = MusicPlayer()
        let items: [QueueItem] = createMockQueue(count: 15)
        await player.set(items: items)
        
        let numberOfItems = await player.numberOfItems()
        XCTAssertEqual(numberOfItems, 15)
        
        let thirdIndexItem = items[3]
        let tenthIndexItem = items[10]
        
        let _ = await player.reorder(item: thirdIndexItem, afterItem: tenthIndexItem)
        
        // item at third index should now be reordered
        let tenthTrack = await player.getTrack(at: 10)
        XCTAssertEqual(tenthTrack?.id, thirdIndexItem.id)
        
        // item at index 10 has moved up in queue
        let ninthTrack = await player.getTrack(at: 9)
        XCTAssertEqual(ninthTrack?.id, tenthIndexItem.id)
    }
    
    func testShuffleDidFinishInvoked() async {
        let player: MusicPlayer = MusicPlayer()
        let items: [QueueItem] = createMockQueue(count: 15)
        await player.set(items: items)
        
        let mockDelegate = MockMusicPlayerDelegate()
        player.delegate = mockDelegate
        
        XCTAssertFalse(mockDelegate.shuffleDidFinishInvoked)
        
        await player.shuffle(fromItem: items[5])
        
        XCTAssertTrue(mockDelegate.shuffleDidFinishInvoked)
    }
    
    private func createMockQueue(count: Int) -> [QueueItem] {
        var items: [QueueItem] = []
        for i in 0..<count {
            let mockPlayableItem = MockPlayableItem(id: "\(i)", fileUrl: "file-url-string", fileExtension: "")
            items.append(mockPlayableItem)
        }
        
        return items
    }
}

final class MockMusicPlayerDelegate: MusicPlayerDelegate {
    var pauseDelegateInvoked: Bool = false
    var musicPlayerDidSetItems: Bool = false
    var didBeginPlaybackForItemInvoked: Bool = false
    var queueMode: MusicPlayer.QueueMode?
    var shuffleMode: MusicPlayer.ShuffleMode?
    
    var shuffleDidFinishInvoked: Bool = false
    
    func musicPlayer(player: MusicPlayer, didFinishShuffleOperation result: Result<QueueShuffleOperationSuccess, QueueShuffleFailure>) {
        shuffleDidFinishInvoked = true
    }
    
    func musicPlayerShuffleModeDidChange(player: MusicPlayer, shuffleMode: MusicPlayer.ShuffleMode) {
        
    }
    
    func musicPlayerShuffleQueueDidChange(player: MusicPlayer, shuffleMode: MusicPlayer.QueueMode) {
        
    }
    
    func musicPlayer(player: MusicPlayer, didBeginPlaybackForItem item: QueueItem, atIndex index: Int) {
        didBeginPlaybackForItemInvoked = true
    }
    
    func musicPlayerDidPause(player: MusicPlayer) {
        pauseDelegateInvoked = true
    }
    
    func musicQueuePlayer(player: MusicPlayer, currentPlaybackTimeDidChange currentPlaybackTime: TimeInterval) {
        
    }
    
    func musicPlayerDidSetItems(player: MusicPlayer, items: [QueueItem]) {
        musicPlayerDidSetItems = true
    }
    
    func musicPlayerDidAppendItem(player: MusicPlayer, item: QueueItem) {
        
    }
    
    func musicPlayerDidPrependItem(player: MusicPlayer, item: QueueItem) {
        
    }
    
    func musicPlayer(player: MusicPlayer, didInsertItem item: QueueItem, atIndex index: Int) {
        
    }
    
    func musicPlayer(player: MusicPlayer, didRemoveItem item: QueueItem, atIndex index: Int) {
        
    }
    
    func musicPlayer(player: MusicPlayer, didReorderItem item: QueueItem, toNewIndex index: Int) {
        
    }
}

private final class MockPlayableItem: QueueItem {
    let id: String
    var fileUrl: String
    var fileExtension: String
    
    init(id: String, fileUrl: String, fileExtension: String) {
        self.id = id
        self.fileUrl = fileUrl
        self.fileExtension = fileExtension
    }
}
