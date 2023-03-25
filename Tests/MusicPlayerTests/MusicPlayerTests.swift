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
        let items: [PlayableItem] = createMockQueue(count: 100)
        let player = MusicPlayer()
        let mockDelegate = MockMusicPlayerDelegate()
        player.delegate = mockDelegate
        
        XCTAssertFalse(mockDelegate.musicPlayerDidSetItems)
        
        let _ = await player.set(items: items)
        
        XCTAssertTrue(mockDelegate.musicPlayerDidSetItems)
    }
    
    func testPlayFromStartIndex() async{
        let items: [PlayableItem] = createMockQueue(count: 100)
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
        let trackAt400: PlayableItem? = await player.getTrack(at: 400)
        XCTAssertNil(trackAt400)
        
        let itemToAppend: PlayableItem = MockPlayableItem(id: "x", fileUrl: "...", fileExtension: "ext")
        await player.append(item: itemToAppend)
        
        let newCount: Int = await player.numberOfItems()
        XCTAssertEqual(newCount, 401)
        
        guard let track: PlayableItem = await player.getTrack(at: 400) else {
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
        let firstTrack: PlayableItem? = await player.getTrack(at: 0)
        XCTAssertEqual(firstTrack?.id, "0")
        
        let itemToPrepend: PlayableItem = MockPlayableItem(id: "x", fileUrl: "...", fileExtension: "ext")
        await player.prepend(item: itemToPrepend)
        
        let newCount: Int = await player.numberOfItems()
        XCTAssertEqual(newCount, 401)
        
        guard let track: PlayableItem = await player.getTrack(at: 0) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(track.id, "x")
        XCTAssertEqual(track.fileUrl, "...")
        XCTAssertEqual(track.fileExtension, "ext")
    }
    
    private func createMockQueue(count: Int) -> [PlayableItem] {
        var items: [PlayableItem] = []
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
    
    func musicPlayerShuffleModeDidChange(player: MusicPlayer, shuffleMode: MusicPlayer.ShuffleMode) {
        
    }
    
    func musicPlayerShuffleQueueDidChange(player: MusicPlayer, shuffleMode: MusicPlayer.QueueMode) {
        
    }
    
    func musicPlayer(player: MusicPlayer, didBeginPlaybackForItem item: PlayableItem, atIndex index: Int) {
        didBeginPlaybackForItemInvoked = true
    }
    
    func musicPlayerDidPause(player: MusicPlayer) {
        pauseDelegateInvoked = true
    }
    
    func musicQueuePlayer(player: MusicPlayer, currentPlaybackTimeDidChange currentPlaybackTime: TimeInterval) {
        
    }
    
    func musicPlayerDidSetItems(player: MusicPlayer, items: [PlayableItem]) {
        musicPlayerDidSetItems = true
    }
    
    func musicPlayerDidAppendItem(player: MusicPlayer, item: PlayableItem) {
        
    }
    
    func musicPlayerDidPrependItem(player: MusicPlayer, item: PlayableItem) {
        
    }
    
    func musicPlayer(player: MusicPlayer, didInsertItem item: PlayableItem, atIndex index: Int) {
        
    }
    
    func musicPlayer(player: MusicPlayer, didRemoveItem item: PlayableItem, atIndex index: Int) {
        
    }
    
    func musicPlayer(player: MusicPlayer, didReorderItem item: PlayableItem, toNewIndex index: Int) {
        
    }
}

private final class MockPlayableItem: PlayableItem {
    let id: String
    var fileUrl: String
    var fileExtension: String
    
    init(id: String, fileUrl: String, fileExtension: String) {
        self.id = id
        self.fileUrl = fileUrl
        self.fileExtension = fileExtension
    }
}
