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
let NotificationPlayerDataUpdateKey = "PlayerDataUpdateKey"
let NotificationCentralDidDiscoverPeripheralKey = "CentralDidDiscoverPeripheralKey"


let NotificationCentralDeviceChangedToUnavailable = Notification.Name(rawValue: "CentralDeviceChangedToUnavailable")
let NotificationCentralDidDiscoverPeripheral = Notification.Name(rawValue: "CentralDidDiscoverPeripheral")
let NotificationPeripheralDeviceChangedToUnavailable = Notification.Name(rawValue: "PeripheralDeviceChangedToUnavailable")

let NotificationPeripheralUpdateSubscriber = Notification.Name(rawValue: "PeripheralUpdateSubscriber")
let NotificationPlayerDataUpdate = Notification.Name(rawValue: "PlayerDataUpdate")
