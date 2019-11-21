//
//  MainWindowController.swift
//  unusedResources
//
//  Created by thierryH24 on 02/10/2018.
//  Copyright © 2018 thierryH24. All rights reserved.
//

// https://github.com/jeffhodnett/Unused

import Cocoa

final class MainWindowController: NSWindowController   {
    
    let lastFolderPath = "LastFolderPath"
    
    let cppCheck       = "cppCheck"
    let cssCheck       = "cssCheck"
    let headerCheck    = "headerCheck"
    let htmlCheck      = "htmlCheck"
    let mCheck         = "mCheck"
    let mmCheck        = "mmCheck"
    let plistCheck     = "plistCheck"
    let sbCheck        = "sbCheck"
    let swiftCheck     = "swiftCheck"
    let xibCheck       = "xibCheck"

    let kTableColumnImageIcon = "ImageIcon"
    let kTableColumnImageShortName = "ImageShortName"
    let kTableColumnImageFullPath = "ImageFullPath"
    let kSelect = "Select"

    var unusedData: [String] = []
    var status = [Bool]()
    var searcher : Searcher!
    
    var startTime: Date?
    
    @IBOutlet var resultsTableView: NSTableView!
    @IBOutlet var processIndicator: NSProgressIndicator!
    @IBOutlet var statusLabel: NSTextField!
    @IBOutlet var browseButton: NSButton!
    @IBOutlet var pathTextField: NSTextField!
    @IBOutlet var searchButton: NSButton!
    @IBOutlet var exportButton: NSButton!
    
    @IBOutlet var cppCheckbox: NSButton!
    @IBOutlet var cssCheckbox: NSButton!
    @IBOutlet var headerCheckbox: NSButton!
    @IBOutlet var htmlCheckbox: NSButton!
    @IBOutlet var mCheckbox: NSButton!
    @IBOutlet var mmCheckbox: NSButton!
    @IBOutlet var plistCheckbox: NSButton!
    @IBOutlet var sbCheckbox: NSButton!
    @IBOutlet var swiftCheckbox: NSButton!
    @IBOutlet var xibCheckbox: NSButton!
    
    @IBOutlet var enumCheckbox: NSButton!
    @IBOutlet weak var deleteButton: NSButton!
    
    override var windowNibName: NSNib.Name? {
        return  "MainWindowController"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Setup the results array
        unusedData = [String]()
        
        // Setup double click
        resultsTableView.doubleAction = #selector(self.tableViewDoubleClicked)
        
        // Setup labels
        statusLabel.textColor = NSColor.lightGray
        
        // Setup search button
        searchButton.bezelStyle = .rounded
        searchButton.keyEquivalent = "\r"
        
        // Setup the searcher
        searcher = Searcher()
        searcher.delegate = self
        
        setupDefaultFolderPath()
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    // MARK: - Actions
    @IBAction func browseButtonSelected(_ sender: Any) {
        // Show an open panel
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        let okButtonPressed = openPanel.runModal() == .OK
        if okButtonPressed {
            // Update the path text field
            let path = openPanel.url?.path
            pathTextField.stringValue = path!
            saveToDefaultFolderPath()
        }
    }
    
    @IBAction func exportButtonSelected(_ sender: Any) {
        let save = NSSavePanel()
        save.allowedFileTypes = ["txt"]
        let okButtonPressed = save.runModal() == .OK
        if okButtonPressed {
            let selectedFile = save.url?.path
            var outputResults = ""
            let projectPath = pathTextField.stringValue
            outputResults += String(format: NSLocalizedString("ExportSummaryTitle", comment: ""), projectPath)
            for path in unusedData {
                outputResults += "\(path )\n"
            }
            // Output
            let writeError: Error? = nil
            try? outputResults.write(toFile: selectedFile ?? "", atomically: true, encoding: .utf8)
            
            // Check write result
            if writeError == nil {
                showAlert(with: .informational, title: NSLocalizedString("ExportCompleteTitle", comment: ""), subtitle: NSLocalizedString("ExportCompleteSubtitle", comment: ""))
            } else {
                if let anError = writeError {
                    print("Unused write error:: \(anError)")
                }
                showAlert(with: .critical, title: NSLocalizedString("ExportErrorTitle", comment: ""), subtitle: NSLocalizedString("ExportErrorSubtitle", comment: ""))
            }
        }
    }
    
    @IBAction func startSearch(_ sender: Any) {
        
        startTime = Date()
        
        // Check if user has selected or entered a path
        let projectPath = pathTextField.stringValue

        if projectPath.isEmpty {
            showAlert(with: .warning, title: NSLocalizedString("MissingPathErrorTitle", comment: ""), subtitle: NSLocalizedString("ProjectFolderPathErrorMessage", comment: ""))
            return
        }
        // Check the path exists
        let pathExists = FileManager.default.fileExists(atPath: projectPath)
        if !pathExists {
            showAlert(with: .warning, title: NSLocalizedString("InvalidPathErrorTitle", comment: ""), subtitle: NSLocalizedString("ProjectFolderPathErrorMessage", comment: ""))
            return
        }
        
        // Reset
        unusedData.removeAll()
        resultsTableView.reloadData()
        
        // Start the ui
        self.setUIEnabled( false )
        
        // Pass search folder
        searcher.projectPath = projectPath
        
        // Pass settings
        searcher.mSearch = mCheckbox.state == .on
        searcher.xibSearch = xibCheckbox.state == .on
        searcher.storyboardSearch = sbCheckbox.state == .on
        searcher.cppSearch = cppCheckbox.state == .on
        searcher.headerSearch = headerCheckbox.state == .on
        searcher.htmlSearch = htmlCheckbox.state == .on
        searcher.mmSearch = mmCheckbox.state == .on
        searcher.plistSearch = plistCheckbox.state == .on
        searcher.cssSearch = cssCheckbox.state == .on
        searcher.swiftSearch = swiftCheckbox.state == .on
        searcher.enumFilter = enumCheckbox.state == .on
        
        // Start the search
        searcher.start()
        
    }
    
    // MARK: - Helpers
    func showAlert(with style: NSAlert.Style, title: String?, subtitle: String?) {
        let alert = NSAlert()
        alert.alertStyle = style
        alert.messageText = title ?? ""
        alert.informativeText = subtitle ?? ""
        alert.runModal()
    }
    
    func scrollTableView(_ tableView: NSTableView, toBottom bottom: Bool) {
        if bottom == true {
            let numberOfRows = tableView.numberOfRows
            if numberOfRows > 0 {
                tableView.scrollRowToVisible((numberOfRows ) - 1)
            }
        } else {
            tableView.scrollRowToVisible(0)
        }
    }
    
    func setUIEnabled(_ state: Bool) {
        // Individual
        if state {
            searchButton.title = NSLocalizedString("Search", comment: "")
            searchButton.keyEquivalent = "\r"
            processIndicator.stopAnimation(self)
        } else {
            searchButton.keyEquivalent = ""
            processIndicator.startAnimation(self)
            statusLabel.stringValue = NSLocalizedString("Searching", comment: "")
        }
        
        // Button groups
        searchButton.isEnabled = state
        processIndicator.isHidden = state
        mCheckbox.isEnabled = state
        xibCheckbox.isEnabled = state
        sbCheckbox.isEnabled = state
        cppCheckbox.isEnabled = state
        mmCheckbox.isEnabled = state
        headerCheckbox.isEnabled = state
        htmlCheckbox.isEnabled = state
        plistCheckbox.isEnabled = state
        cssCheckbox.isEnabled = state
        swiftCheckbox.isEnabled = state
        browseButton.isEnabled = state
        pathTextField.isEnabled = state
        exportButton.isHidden = !state
        deleteButton.isHidden = !state
    }
    
    @objc func tableViewDoubleClicked() {
        
        guard resultsTableView.clickedRow > 0 else { return }
        
        // Open finder
        let path = unusedData[resultsTableView.clickedRow]
        let folderWithFilenameAndEncoding: String? = path.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        let imagePath = URL(string: folderWithFilenameAndEncoding!)!.resolvingSymlinksInPath
        
        let pathFinder = imagePath().path
        NSWorkspace.shared.selectFile(pathFinder, inFileViewerRootedAtPath: "")
    }
    
    @IBAction func selectClick(_ sender: NSButton) {
        

        let row = resultsTableView.row(for: sender as NSView)
        guard  row != -1 else { return }
        
        let state = sender.state
        status[row] = state == .on

    }
    
    @IBAction func deletePressed(_ sender: Any) {
        
        guard self.unusedData.count != 0 else  { return }
        
        let data = self.unusedData
        for i in 0 ..< data.count where status[i] == true {
            for path in unusedData {
                var needDeletePath = path
                var needSkip = false
                if path.contains("imageset") {
                    needDeletePath = path.replacingOccurrences(of: path.components(separatedBy: "/").last!, with: "")
                    needSkip = true
                }
                do {
                    print("try to delete : " + needDeletePath)
                    try FileManager.default.removeItem(atPath: needDeletePath)
                } catch let error as NSError  {
                    self.showAlert(title: "Error", subtitle: "Delete get error" + error.domain)
                    print(error)
                    return
                }
                if needSkip == true {
                    break
                }
            }
        }
        self.startSearch(searchButton)
    }
    
    func showAlert(title: String , subtitle:String) {
        let alert = NSAlert();
        alert.alertStyle = NSAlert.Style.informational;
        alert.messageText = title;
        alert.informativeText = subtitle;
        alert.runModal();
    }

    func setupDefaultFolderPath() {
        if let path = UserDefaults.standard.object(forKey: lastFolderPath) {
            pathTextField.stringValue = path as! String
            
            cppCheckbox.state = UserDefaults.standard.bool(forKey: cppCheck) ? .on : .off
            cssCheckbox.state = UserDefaults.standard.bool(forKey: cssCheck) ? .on : .off
            headerCheckbox.state = UserDefaults.standard.bool(forKey: headerCheck) ? .on : .off
            htmlCheckbox.state = UserDefaults.standard.bool(forKey: htmlCheck) ? .on : .off
            mCheckbox.state = UserDefaults.standard.bool(forKey: mCheck) ? .on : .off
            mmCheckbox.state = UserDefaults.standard.bool(forKey: mmCheck) ? .on : .off
            plistCheckbox.state = UserDefaults.standard.bool(forKey: plistCheck) ? .on : .off
            sbCheckbox.state = UserDefaults.standard.bool(forKey: sbCheck) ? .on : .off
            swiftCheckbox.state = UserDefaults.standard.bool(forKey: swiftCheck) ? .on : .off
            xibCheckbox.state = UserDefaults.standard.bool(forKey: xibCheck) ? .on : .off
        }
    }
    
    func saveToDefaultFolderPath() {
        UserDefaults.standard.setValue(pathTextField.stringValue , forKey: lastFolderPath)
        
        UserDefaults.standard.setValue(cppCheckbox.state == . on, forKey: cppCheck)
        UserDefaults.standard.setValue(cssCheckbox.state == . on, forKey: cssCheck)
        UserDefaults.standard.setValue(headerCheckbox.state == . on, forKey: headerCheck)
        UserDefaults.standard.setValue(htmlCheckbox.state == . on, forKey: htmlCheck)
        UserDefaults.standard.setValue(mCheckbox.state == . on, forKey: mCheck)
        UserDefaults.standard.setValue(mmCheckbox.state == . on, forKey: mmCheck)
        UserDefaults.standard.setValue(plistCheckbox.state == . on, forKey: plistCheck)
        UserDefaults.standard.setValue(sbCheckbox.state == . on, forKey: sbCheck)
        UserDefaults.standard.setValue(swiftCheckbox.state == . on, forKey: swiftCheck)
        UserDefaults.standard.setValue(xibCheckbox.state == . on, forKey: xibCheck)
        UserDefaults.standard.synchronize()
    }
}

