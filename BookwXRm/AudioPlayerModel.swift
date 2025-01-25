//
//  File.swift
//  BookwXRm
//
//  Created by Ananya on 1/25/25.
//

/*
 import Foundation
 import AVFoundation
 
 class AudioPlayerModel: ObservableObject {
 
 func configureAudioSession() {
 do {
 let session = AVAudioSession.sharedInstance()
 // Configure the app for playback of long-form movies.
 try session.setCategory(.playback, mode: .moviePlayback)
 } catch {
 // Handle error.
 }
 }
 func playMedia(at url: URL) {
 let asset = AVURLAsset(url: url)
 let playerItem = AVPlayerItem(
 asset: asset,
 automaticallyLoadedAssetKeys: [.tracks, .duration, .commonMetadata]
 )
 // Register to observe the status property before associating with player.
 playerItem.publisher(for: \.status)
 .removeDuplicates()
 .receive(on: DispatchQueue.main)
 .sink { [weak self] status in
 guard let self else { return }
 switch status {
 case .readyToPlay:
 // Ready to play. Present playback UI.
 break
 case .failed:
 // A failure while loading media occurred.
 break
 default:
 break
 }
 }
 .store(in: &subscriptions)
 
 // Set the item as the player's current item.
 player.replaceCurrentItem(with: playerItem)
 }
 
 @Published var isPlaying = false
 
 private func observePlayingState() {
 player.publisher(for: \.timeControlStatus)
 .receive(on: DispatchQueue.main)
 .map { $0 == .playing }
 .assign(to: &$isPlaying)
 }
 
 // Observe changes to the playback rate asynchronously.
 private func observeRateChanges() async {
 let name = AVPlayer.rateDidChangeNotification
 for await notification in NotificationCenter.default.notifications(named: name) {
 guard let reason = notification.userInfo?[AVPlayer.rateDidChangeReasonKey] as? AVPlayer.RateDidChangeReason else {
 continue
 }
 switch reason {
 case .appBackgrounded:
 // The app transitioned to the background.
 case .audioSessionInterrupted:
 // The system interrupts the app’s audio session.
 case .setRateCalled:
 // The app set the player’s rate.
 case .setRateFailed:
 // An attempt to change the player’s rate failed.
 default:
 break
 }
 }
 }
 
 // Handle time update request from user interface.
 func seek(to timeInterval: TimeInterval) async {
 // Create a CMTime value for the passed in time interval.
 let time = CMTime(seconds: timeInterval, preferredTimescale: 600)
 await avPlayer.seek(to: time);
 }
 
 
 
 }
 */
