//
//  MusicQueuePlayer.swift
//  TestMusic
//
//  Created by Stephen Bodnar on 3/11/23.
//

import Foundation
import AVKit

private extension AVPlayerItem {
    convenience init?(playableItem: QueueItem) {
        guard let url: URL = Bundle.main.url(forResource: playableItem.fileUrl, withExtension: "m4a")  else {
            return nil
        }
        self.init(url: url)
    }
}

public protocol QueueItem: AnyObject {
    var id: String { get }
    var fileUrl: String { get set }
    var fileExtension: String { get }
}

public protocol MusicPlayerInterface: AnyObject {
    func playAVPlayer()
    func play(startIndex: Int) async
    func pause()
    
    func append(item: QueueItem) async
    func prepend(item: QueueItem) async
    func insert(item: QueueItem, afterItem: QueueItem) async
    func set(items: [QueueItem]) async
    func reorder(item: QueueItem, afterItem otherItem: QueueItem) async
    func shuffle(fromItem item: QueueItem) async
    
    func goBackToPreviousTrack() async
    func advanceToNextTrack() async
    
    var currentTrack: Int { get set }
    var currentPlaybackTime: TimeInterval { get set }
    var playingState: MusicPlayer.PlayingState { get set }
}

public protocol MusicPlayerDelegate: AnyObject {
    
    func musicPlayerShuffleModeDidChange(player: MusicPlayer, shuffleMode: MusicPlayer.ShuffleMode)
    func musicPlayerShuffleQueueDidChange(player: MusicPlayer, shuffleMode: MusicPlayer.QueueMode)
    
    // Playback
    func musicPlayer(player: MusicPlayer, didBeginPlaybackForItem item: QueueItem, atIndex index: Int)
    func musicPlayerDidPause(player: MusicPlayer)
    func musicQueuePlayer(player: MusicPlayer, currentPlaybackTimeDidChange currentPlaybackTime: TimeInterval)
    
    // Queue Modifications
    func musicPlayerDidSetItems(player: MusicPlayer, items: [QueueItem])
    func musicPlayerDidAppendItem(player: MusicPlayer, item: QueueItem)
    func musicPlayerDidPrependItem(player: MusicPlayer, item: QueueItem)
    func musicPlayer(player: MusicPlayer, didInsertItem item: QueueItem, atIndex index: Int)
    func musicPlayer(player: MusicPlayer, didRemoveItem item: QueueItem, atIndex index: Int)
    func musicPlayer(player: MusicPlayer, didReorderItem item: QueueItem, toNewIndex index: Int)
    func musicPlayer(player: MusicPlayer, didFinishShuffleOperation result: Result<QueueShuffleOperationSuccess, QueueShuffleFailure>)
}

public final class MusicPlayer: MusicPlayerInterface {
    
    public enum PlayingState: Equatable {
        case playing
        case paused
    }
    
    public enum ShuffleMode: Equatable {
        case on
        case off
    }
    
    public enum QueueMode: Equatable {
        case normal
        case repeatAll
        case repeatOne
    }
    
    private var player: AVPlayer?
    
    private var currentPlaybackTimeTimer: Timer?
    
    private var queue: QueueInterface = Queue()
    
    public var queueMode: QueueMode = .normal {
        didSet {
            delegate?.musicPlayerShuffleQueueDidChange(player: self, shuffleMode: queueMode)
        }
    }
    
    public var shuffleMode: ShuffleMode = .off {
        didSet {
            delegate?.musicPlayerShuffleModeDidChange(player: self, shuffleMode: shuffleMode)
        }
    }
    
    public var playingState: PlayingState = .paused
    
    public var currentTrack: Int = 0
    public var currentPlaybackTime: TimeInterval = 0
    
    public weak var delegate: MusicPlayerDelegate?
    
    private let dispatchQueue: DispatchQueue = DispatchQueue(label: "com.musicplayerModifications")
    
    public init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(finished),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
    
    public func numberOfItems() async -> Int {
        return await queue.numberOfItems()
    }
    
    public func getTrack(at index: Int) async -> QueueItem? {
        return await queue.getTrack(at: index)
    }gi
    
    // MARK: - Playing / Pausing
    
    /// Only fowards `play()` directly to the underlying AVPlayer.
    /// Does not instantiate the AVPlayer. Should only be used for resuming audio from a paused state
    /// To start playing a new queue, call `setItems(items: ...)` and then `play(startIndex: ..)`
    public func playAVPlayer() {
        player?.play()
        playingState = .playing
    }
    
    public func pause() {
        player?.pause()
        
        playingState = .paused
        delegate?.musicPlayerDidPause(player: self)
    }
    
    /// Call after calling `setItems(items: ..)`
    /// This function will instantiate the underlying AVPlayer
    public func play(startIndex: Int) async {
        if let track = await queue.getTrack(at: startIndex) {
            currentTrack = startIndex
            self.player = AVPlayer(playerItem: AVPlayerItem(playableItem: track))
            await self.playNow()
        }
    }
    
    /// Used to resume playing the AVPlayer, setup the playback timer and invoke the delegate that playback began
    private func playNow() async {
        playAVPlayer()
        setupPlaybackTimeTimer()
        if let unwrappedTrack = await queue.getTrack(at: currentTrack) {
            self.delegate?.musicPlayer(player: self, didBeginPlaybackForItem: unwrappedTrack, atIndex: currentTrack)
        }
    }
    
    // MARK: - Navigate Tracks
    
    public func goBackToPreviousTrack() async {
        if (currentPlaybackTime <= 3) && currentTrack > 0 { // go back to previous track
            currentTrack -= 1
            if let trackToPlay = await queue.getTrack(at: currentTrack) {
                let avItem = AVPlayerItem(playableItem: trackToPlay)
                player?.replaceCurrentItem(with: avItem)
                await playNow()
            }
        } else { // then go back to beginning of existing track
            player?.currentItem?.seek(to: .zero, completionHandler: nil)
        }
    }
    
    public func advanceToNextTrack() async {
        self.currentTrack += 1
        if let trackToPlay = await queue.getTrack(at: currentTrack) {
            let avItem = AVPlayerItem(playableItem: trackToPlay)
            player?.replaceCurrentItem(with: avItem)
            await playNow()
        } else {
            pause()
        }
    }
    
    // MARK: - Queue Modification
    
    public func append(item: QueueItem) async {
        let result = await queue.append(item: item)
        self.delegate?.musicPlayerDidAppendItem(player: self, item: result.item)
    }
    
    public func prepend(item: QueueItem) async {
        let result = await queue.prepend(item: item)
        self.delegate?.musicPlayerDidPrependItem(player: self, item: result.item)
    }
    
    public func insert(item: QueueItem, afterItem: QueueItem) async {
        let result = await queue.insert(item: item, afterItem: afterItem)
        switch result {
        case .success(let success):
            self.delegate?.musicPlayer(player: self, didInsertItem: success.item, atIndex: success.index)
        case .failure:
            break
        }
    }
    
    public func set(items: [QueueItem]) async {
        let result = await queue.set(items: items)
        self.currentTrack = 0
        self.delegate?.musicPlayerDidSetItems(player: self, items: result.items)
    }
    
    /// Takes an existing item in the array, `item`, and places it after the `otherItem`
    public func reorder(item: QueueItem, afterItem otherItem: QueueItem) async {
        let result = await queue.reorder(item: item, afterItem: otherItem)
        switch result {
        case .success(let success):
            self.delegate?.musicPlayer(player: self, didReorderItem: success.item, toNewIndex: success.index)
        case .failure:
            break
        }
    }
    
    /// shuffles the existing array of items starting from the index **after** the currently playing item
    ///
    public func shuffle(fromItem item: QueueItem) async {
        let result = await queue.shuffle(fromItem: item)
        delegate?.musicPlayer(player: self, didFinishShuffleOperation: result)
    }
    
    // MARK: - Helpers
    
    private func setupPlaybackTimeTimer() {
        // InvalidateExisting
        currentPlaybackTimeTimer?.invalidate()
        currentPlaybackTimeTimer = nil
        currentPlaybackTime = 0
        
        // Setup new
        currentPlaybackTimeTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true, block: { _ in
            switch self.playingState {
            case .playing:
                let time: TimeInterval = self.player?.currentItem?.currentTime().seconds ?? 0
                self.currentPlaybackTime = time
                
                self.delegate?.musicQueuePlayer(player: self, currentPlaybackTimeDidChange: time)
            case .paused: break
            }
        })
        
        currentPlaybackTimeTimer?.fire()
    }
    
    // MARK: - Notifications
    
    /// Called when a song finishes playing
    @objc func finished(notification: NSNotification) async {
        switch queueMode {
        case .normal:
            await advanceToNextTrack()
        case .repeatAll:
            let totalQueueCount: Int = await queue.numberOfItems()
            let proposedNewCurrentTrack: Int = currentTrack + 1
            if proposedNewCurrentTrack > totalQueueCount { // go back to the beginning
                self.currentTrack = 0
                await play(startIndex: 0)
            } else { // not reached end yet. just keep going
                await advanceToNextTrack()
            }
        case .repeatOne:
            player?.currentItem?.seek(to: .zero, completionHandler: nil)
            await playNow()
        }
    }
}
