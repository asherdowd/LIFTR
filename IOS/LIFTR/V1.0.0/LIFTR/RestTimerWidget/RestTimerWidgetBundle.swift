//
//  RestTimerWidgetBundle.swift
//  RestTimerWidget
//
//  Created by Seth Dowd on 1/31/26.
//

import WidgetKit
import SwiftUI

@main
struct RestTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        RestTimerWidget()
        RestTimerWidgetLiveActivity()
    }
}
