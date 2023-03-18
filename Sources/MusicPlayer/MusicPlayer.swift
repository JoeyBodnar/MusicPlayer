//
//  MusicQueuePlayer.swift
//  TestMusic
//
//  Created by Stephen Bodnar on 3/11/23.
//

import Foundation
import AVKit

private extension AVPlayerItem {
    convenience init(playableItem: PlayableItem) {
        self.init(url: Bundle.main.url(forResource: playableItem.fileUrl, withExtension: "m4a")!)
    }
}

public protocol PlayableItem: AnyObject {
    var id: String { get }
    var fileUrl: String { get set }
}

public protocol MusicQueuePlayerInterface: AnyObject {
    func playAVPlayer()
    func play(startIndex: Int)
    func pause()
    
    func append(item: PlayableItem)
    func prepend(item: PlayableItem)
    func insert(item: PlayableItem, afterItem: PlayableItem)
    func set(items: [PlayableItem])
    func reorder(item: PlayableItem, afterItem otherItem: PlayableItem)
    func shuffle(fromItem item: PlayableItem)
    
    func goBackToPreviousTrack()
    func advanceToNextTrack()
    
    var currentTrack: Int { get set }
    var currentPlaybackTime: TimeInterval { get set }
    var playingState: MusicPlayer.PlayingState { get set }
}

public protocol MusicQueuePlayerDelegate: AnyObject {
    
    func musicQueuePlayerShuffleModeDidChange(queuPlayer: MusicPlayer, shuffleMode: MusicPlayer.ShuffleMode)
    func musicQueuePlayerShuffleQueueDidChange(queuePlayer: MusicPlayer, shuffleMode: MusicPlayer.QueueMode)
    
    // Playback
    func musicQueuePlayer(queuePlayer: MusicPlayer, didBeginPlaybackForItem item: PlayableItem, atIndex index: Int)
    func musicQueuePlayerDidPause(queuePlayer: MusicPlayer)
    func musicQueuePlayer(queuePlayer: MusicPlayer, currentPlaybackTimeDidChange currentPlaybackTime: TimeInterval)
    
    // Queue Modifications
    func musicQueuePlayerDidSetItems(queuePlayer: MusicPlayer, items: [PlayableItem])
    func musicQueuePlayerDidAppendItem(queuePlayer: MusicPlayer, item: PlayableItem)
    func musicQueuePlayerDidPrependItem(queuePlayer: MusicPlayer, item: PlayableItem)
    func musicQueuePlayer(queuePlayer: MusicPlayer, didInsertItem item: PlayableItem, atIndex index: Int)
    func musicQueuePlayer(queuePlayer: MusicPlayer, didRemoveItem item: PlayableItem, atIndex index: Int)
    func musicQueuePlayer(queuePlayer: MusicPlayer, didReorderItem item: PlayableItem, toNewIndex index: Int)
}

public final class MusicPlayer: MusicQueuePlayerInterface {
    
    public enum PlayingState {
        case playing
        case paused
    }
    
    public enum ShuffleMode {
        case on
        case off
    }
    
    public enum QueueMode {
        case normal
        case repeatAll
        case repeatOne
    }
    
    private var player: AVPlayer?
    
    private var currentPlaybackTimeTimer: Timer?
    
    private var queue: QueueInterface = Queue()
    
    public var queueMode: QueueMode = .normal {
        didSet {
            delegate?.musicQueuePlayerShuffleQueueDidChange(queuePlayer: self, shuffleMode: queueMode)
        }
    }
    
    public var shuffleMode: ShuffleMode = .off {
        didSet {
            delegate?.musicQueuePlayerShuffleModeDidChange(queuPlayer: self, shuffleMode: shuffleMode)
        }
    }
    
    public var playingState: PlayingState = .paused
    
    public var currentTrack: Int = 0
    public var currentPlaybackTime: TimeInterval = 0
    
    public weak var delegate: MusicQueuePlayerDelegate?
    
    private let dispatchQueue: DispatchQueue = DispatchQueue(label: "com.musicplayerModifications")
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(finished),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
    
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
        delegate?.musicQueuePlayerDidPause(queuePlayer: self)
    }
    
    /// Call after calling `setItems(items: ..)`
    /// This function will instantiate the underlying AVPlayer
    public func play(startIndex: Int) {
        if let track = queue.getTrack(at: startIndex) {
            currentTrack = startIndex
            self.player = AVPlayer(playerItem: AVPlayerItem(playableItem: track))
            self.playNow()
        }
    }
    
    /// Used to resume playing the AVPlayer, setup the playback timer and invoke the delegate that playback began
    private func playNow() {
        playAVPlayer()
        setupPlaybackTimeTimer()
        if let unwrappedTrack = queue.getTrack(at: currentTrack) {
            self.delegate?.musicQueuePlayer(queuePlayer: self, didBeginPlaybackForItem: unwrappedTrack, atIndex: currentTrack)
        }
    }
    
    // MARK: - Navigate Tracks
    
    public func goBackToPreviousTrack() {
        if (currentPlaybackTime < 3) && currentTrack > 0 { // go back to previous track
            currentTrack -= 1
            if let trackToPlay = queue.getTrack(at: currentTrack) {
                let avItem = AVPlayerItem(playableItem: trackToPlay)
                player?.replaceCurrentItem(with: avItem)
                playNow()
            }
        } else { // then go back to beginning of existing track
            player?.currentItem?.seek(to: .zero, completionHandler: nil)
        }
    }
    
    public func advanceToNextTrack() {
        self.currentTrack += 1
        if let trackToPlay = queue.getTrack(at: currentTrack) {
            let avItem = AVPlayerItem(playableItem: trackToPlay)
            player?.replaceCurrentItem(with: avItem)
            playNow()
        } else {
            pause()
        }
    }
    
    // MARK: - Queue Modification
    
    public func append(item: PlayableItem) {
        queue.append(item: item) { queue, item in
            self.delegate?.musicQueuePlayerDidAppendItem(queuePlayer: self, item: item)
        }
    }
    
    public func prepend(item: PlayableItem) {
        queue.prepend(item: item) { queue, item in
            self.delegate?.musicQueuePlayerDidPrependItem(queuePlayer: self, item: item)
        }
    }
    
    public func insert(item: PlayableItem, afterItem: PlayableItem) {
        queue.insert(item: item, afterItem: afterItem) { queue, item, index in
            self.delegate?.musicQueuePlayer(queuePlayer: self, didInsertItem: item, atIndex: index)
        }
    }
    
    public func set(items: [PlayableItem]) {
        queue.set(items: items) { queue, items in
            self.currentTrack = 0
            self.delegate?.musicQueuePlayerDidSetItems(queuePlayer: self, items: items)
        }
    }
    
    /// Takes an existing item in the array, `item`, and places it after the `otherItem`
    public func reorder(item: PlayableItem, afterItem otherItem: PlayableItem) {
        queue.reorder(item: item, afterItem: otherItem) { result in
            switch result {
            case .success(_, let item, let newIndex):
                self.delegate?.musicQueuePlayer(queuePlayer: self, didReorderItem: item, toNewIndex: newIndex)
            case .failure:
                break
            }
        }
    }
    
    /// shuffles the existing array of items starting from the index **after** the currently playing item
    ///
    public func shuffle(fromItem item: PlayableItem) {
        queue.shuffle(fromItem: item) { queue, unshuffledItems, shuffledItems, allItems in
            
        }
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
                
                self.delegate?.musicQueuePlayer(queuePlayer: self, currentPlaybackTimeDidChange: time)
            case .paused: break
            }
            
        })
        
        currentPlaybackTimeTimer?.fire()
    }
    
    // MARK: - Notifications
    
    /// Called when a song finishes playing
    @objc func finished(notification: NSNotification) {
        switch queueMode {
        case .normal:
            advanceToNextTrack()
        case .repeatAll:
            let totalQueueCount: Int = queue.numberOfItems
            let proposedNewCurrentTrack: Int = currentTrack + 1
            if proposedNewCurrentTrack > totalQueueCount { // go back to the beginning
                self.currentTrack = 0
                if let track = queue.getTrack(at: currentTrack) {
                    let avItem = AVPlayerItem(playableItem: track)
                    player?.replaceCurrentItem(with: avItem)
                    playNow()
                }
                
            } else { // not reached end yet. just keep going
                advanceToNextTrack()
            }
        case .repeatOne:
            player?.currentItem?.seek(to: .zero, completionHandler: nil)
            playNow()
        }
    }
}








