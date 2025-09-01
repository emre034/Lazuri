//
//  LazuriReport.swift
//  LazuriReport
//
//  Created by Emre Kulaber on 08/07/2025.
//

import DeviceActivity
import SwiftUI

// Report extension entry point
@main
struct LazuriReport: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { totalActivity in
            TotalActivityView(activityReport: totalActivity)
        }
    }
}
