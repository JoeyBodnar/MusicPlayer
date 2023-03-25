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
