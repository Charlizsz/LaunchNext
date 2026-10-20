import Foundation
import SwiftData
import Observation
import os
@main struct Check {
    @MainActor static func main() throws {
        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        let config = ModelConfiguration(url: url)
        let container = try ModelContainer(for: TopItemData.self, PageEntryData.self, configurations: config)
        let context = ModelContext(container)
        if CommandLine.arguments[2] == "write" {
            let top = TopItemData(folderId: "test-folder", folderName: "中文 Folder", appPaths: ["/Applications/Safari.app"], orderIndex: 2)
            let page = PageEntryData(slotId:"page-0-pos-0", pageIndex:0, position:0, kind:"folder", folderId:"test-folder", folderName:"中文 Folder", appPaths:["/Applications/Safari.app"], pinnedAppPaths:["/Applications/Safari.app"])
            context.insert(top); context.insert(page); try context.save()
            let observed = OSAllocatedUnfairLock(initialState: false)
            withObservationTracking { _ = page.folderName } onChange: { observed.withLock { $0 = true } }
            page.folderName = "Renamed 中文"; page.pinnedAppPaths = nil
            page.appPaths.append("/Applications/Test.app")
            precondition(observed.withLock { $0 })
            try context.save()
        } else {
            let tops = try context.fetch(FetchDescriptor<TopItemData>())
            let pages = try context.fetch(FetchDescriptor<PageEntryData>())
            if CommandLine.arguments[2] == "verify" {
                precondition(tops.count == 1 && tops[0].folderName == "中文 Folder")
                precondition(tops[0].appPaths == ["/Applications/Safari.app"])
                precondition(pages[0].appPaths == ["/Applications/Safari.app", "/Applications/Test.app"])
                precondition(pages.count == 1 && pages[0].folderName == "Renamed 中文" && pages[0].pinnedAppPaths == nil)
            }
            for p in pages { _ = (p.slotId,p.pageIndex,p.position,p.kind,p.appPath,p.appDisplayName,p.folderId,p.folderName,p.appPaths,p.pinnedAppPaths,p.removableSource,p.createdAt,p.updatedAt) }
            print("Read OK: \(tops.count) top items, \(pages.count) page entries")
        }
    }
}
