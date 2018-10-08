//
//  MainWindowExtension.swift
//  unusedResources
//
//  Created by thierryH24 on 07/10/2018.
//  Copyright © 2018 thierryH24. All rights reserved.
//

import AppKit


extension MainWindowController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return unusedData.count
    }
    
}

extension MainWindowController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if let column = tableColumn {
            let id = column.identifier
            if let cellView = tableView.makeView(withIdentifier: id, owner: self) as? NSTableCellView {
                
                let pngPath = unusedData[row]
                
                if column.identifier.rawValue == kTableColumnImageIcon {
                    let folderWithFilenameAndEncoding: String? = pngPath.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
                    let imagePath = URL(string: folderWithFilenameAndEncoding!)
                    
                    let image = NSImage(byReferencing : imagePath!)
                    cellView.imageView?.image = image
                    return cellView
                }
                if column.identifier.rawValue == kTableColumnImageShortName {
                    let folderWithFilenameAndEncoding: String? = pngPath.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
                    let imagePath = URL(string: folderWithFilenameAndEncoding!)
                    
                    cellView.textField?.stringValue = imagePath?.lastPathComponent ?? "defaut"
                    return cellView
                }
                if column.identifier.rawValue == kTableColumnImageFullPath {
                    cellView.textField?.stringValue = pngPath
                    return cellView
                }
            }
            if let cellView = tableView.makeView(withIdentifier: id, owner: self) as? SelectCellView {
                if column.identifier.rawValue == kSelect {
                    cellView.select.state = .off
                    return cellView
                }
                
            }
            
        }
        return nil
    }
    
}

extension MainWindowController: SearcherDelegate {
    
    // MARK: - <SearcherDelegate>
    public func searcherDidStartSearch() {
    }
    
    func searcher( didFindUnusedImage imagePath: String) {
        // Add and reload
        unusedData.append(imagePath )
        
        // Reload
        DispatchQueue.main.async { [unowned self] in
            self.resultsTableView.reloadData()
        }
        
        // Scroll to the bottom
        scrollTableView(resultsTableView, toBottom: true)
    }
    
    func searcher( didFinishSearch results: [String]) {
        
        // Ensure all data is displayed
        resultsTableView.reloadData()
        status.removeAll()
        
        // Calculate how much file size we saved and update the label
        var size = UInt64(0)
        for path in self.unusedData {
            let folderWithFilenameAndEncoding: String? = path.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            let pathUrl = URL(string: folderWithFilenameAndEncoding!)
            
            size += (pathUrl?.fileSize)!
            status.append(false)
        }
        
        statusLabel.stringValue = "Completed Found : " + String(self.unusedData.count) + " images - Size " + FileUtil.shared.stringFromFileSize(fileSize: Int(size))
        
        // Enable the ui
        self.setUIEnabled( true)
    }
}

extension URL {
    var attributes: [FileAttributeKey : Any]? {
        do {
            return try FileManager.default.attributesOfItem(atPath: path)
        } catch let error as NSError {
            print("FileAttribute error: \(error)")
        }
        return nil
    }
    
    var fileSize: UInt64 {
        return attributes?[.size] as? UInt64 ?? UInt64(0)
    }
    
    var creationDate: Date? {
        return attributes?[.creationDate] as? Date
    }
}

final class SelectCellView: NSTableCellView {
    
    @IBOutlet weak var select: NSButton!
}

extension NSUserInterfaceItemIdentifier {
    static let ImageIcon       = NSUserInterfaceItemIdentifier("ImageIcon")
    static let ImageShortName       = NSUserInterfaceItemIdentifier("ImageShortName")
    static let ImageFullPath         = NSUserInterfaceItemIdentifier("ImageFullPath")
    static let Select         = NSUserInterfaceItemIdentifier("Select")
    
}

