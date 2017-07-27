//
//  GLNotification.swift
//  Swifter
//
//  Created by George on 2017/6/29.
//  Copyright © 2017年 George. All rights reserved.
//

import Foundation

let NotificationErrorKey = "ReasonForError"
let NotificationUpdatedSubscriberUUIDStringKey = "UpdatedSubscriberUUIDStringKey"
let NotificationCentralDidDiscoverPeripheralKey = "CentralDidDiscoverPeripheralKey"

let NotificationCentralDidConnect = NSNotification.Name(rawValue: "CentralDidConnect")
let NotificationCentralStateChangedToUnavailable = Notification.Name(rawValue: "CentralStateChangedToUnavailable")
let NotificationCentralDidDiscoverPeripheral = Notification.Name(rawValue: "CentralDidDiscoverPeripheral")
let NotificationPeripheralDeviceChangedToUnavailable = Notification.Name(rawValue: "PeripheralDeviceChangedToUnavailable")

let NotificationPeripheralUpdateSubscriber = Notification.Name(rawValue: "PeripheralUpdateSubscriber")


let NotificationDidReceiveOtherPlayerName = Notification.Name(rawValue: "ReceivePlayerName")
let NotificationOtherPlayerReadyStateDidChange = Notification.Name(rawValue: "PlayerReadyStateDidChange")
let NotificationOtherPlayerFinishRateDidChange = Notification.Name(rawValue: "PlayerFinishRateDidChange")
let NotificationOtherPlayerNameKey = "OtherPlayerNameKey"
let NotificationOtherPlayerReadyStateKey = "OtherPlayerReadyStateKey"
let NotificationOtherPlayerFinishRateKey = "OtherPlayerFinishRateKey"
