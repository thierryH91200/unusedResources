//
//  Searcher.swift
//  unusedResources
//
//  Created by thierryH24 on 02/10/2018.
//  Copyright © 2018 thierryH24. All rights reserved.
//

import AppKit

@objc public protocol SearcherDelegate
{
    func searcherDidStartSearch()
    func searcher( didFindUnusedImage imagePath: String)
    func searcher( didFinishSearch results: [String])
}

final class Searcher: NSObject {
    
    // Arrays
    var projectImageFiles = [String]()
    var results = [String]()
    var retinaImagePaths =  [String]()
    var queue: OperationQueue?
    var isSearching = false
    
    // Stores the file data to avoid re-reading files, using a lock to make it thread-safe.
    var fileData: [String : Any] = [:]
    var fileDataLock: NSLock?
    
    weak var delegate: SearcherDelegate?
    var projectPath = ""
    var mSearch = false
    var xibSearch = false
    var storyboardSearch = false
    var cppSearch = false
    var headerSearch = false
    var htmlSearch = false
    var mmSearch = false
    var plistSearch = false
    var cssSearch = false
    var swiftSearch = false
    var enumFilter = false
    
    var supportedRetinaImagePostfixes : [String] {
        return ["@2x", "@3x"]
    }
    
    override init() {
        super.init()
        
        // Setup the results array
        results = [String]()
        
        // Setup the retina images array
        retinaImagePaths = [String]()
        
        // Setup the queue
        queue = OperationQueue()
        
        // Setup data lock
        fileData = [String : Any]()
        fileDataLock = NSLock()
    }
    
    func start() {
        self.runImageSearch( projectPath)
    }
    
    func stop() {
        //implement me!
    }
    
    func runImageSearch(_ searchPath: String) {
        
        // Start the search
        delegate?.searcherDidStartSearch()
        
        // Find all the image files in the folder
        projectImageFiles = FileUtil.shared.imageFiles(inDirectory: searchPath)
        
        // Find all the image files in the folder
        var imageFiles = projectImageFiles
        
        if enumFilter == true {
            var mutablePngFiles = imageFiles
            
            // Trying to filter image names like: "Section_0.png", "Section_1.png", etc
            //(these names can possibly be created by [NSString stringWithFormat:@"Section_%d", (int)] constructions) to just "Section_" item
            var index = 0
            while index < mutablePngFiles.count {
                let imageName = mutablePngFiles[index]
                
                let regExp = try? NSRegularExpression(pattern: "[_-].*\\d.*.png", options: .caseInsensitive)
                let newImageName = regExp?.stringByReplacingMatches(in: imageName , options: .reportProgress, range: NSRange(location: 0, length: imageName.count ), withTemplate: "")
                if newImageName != nil {
                    mutablePngFiles[index] = newImageName ?? ""
                }
                index += 1
            }
            // Remove duplicates and update pngFiles array
            imageFiles = Array(Set<String>(mutablePngFiles))
        }
        
        // Setup all the retina image firstly
        // DISCUSSION: performance vs extensibility. Is a n^2 loop better for extensibility or is a large if statement with better effency
        for projectImageFile in projectImageFiles where projectImageFile != "" {
            
            let strFile = "file://" +  projectImageFile
            let folderWithFilenameAndEncoding: String? = strFile.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            
            let path = URL(string : folderWithFilenameAndEncoding!)
            let imageName = path!.lastPathComponent
            
            // Does the image have a retina version
            let supportedRetina = supportedRetinaImagePostfixes
            for retinaRangeString in supportedRetina {
                
                let retinaRange = (imageName as NSString?)?.range(of: retinaRangeString )
                if Int(retinaRange?.location ?? 0) != NSNotFound {
                    // Add to retina image paths
                    retinaImagePaths.append(projectImageFile )
                    break
                }
            }
        }
        
        DispatchQueue.global(qos: .background).async {
            print("This is run on the background queue")
            
            let startTime = Date()
            for imageFile in imageFiles where imageFile != "" {
                
                let strFile = "file://" +  imageFile
                let folderWithFilenameAndEncoding = strFile.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                
                let imagePath = URL(string: folderWithFilenameAndEncoding!)
                
                // Check that it's not a retina image or reserved image name
                let isValidImage = self.ValidImage(atPath: imagePath!)
                if isValidImage == true {
                    
                    // Grab the file name
                    let imageName = imagePath!.lastPathComponent
                    
                    // Settings items
                    let settingsItems = self.searchSettings
                    var isSearchCancelled = false
                    
                    let startTime = Date()
                    for ext in settingsItems {
                        
                        // Run the check
                        if isSearchCancelled == false  && self.occurancesOfImageNamed(imageName, directoryPath: searchPath, typeExtension: ext) > 0 {
                            isSearchCancelled = true
                        }
                    }
                    let time: TimeInterval = Date().timeIntervalSince(startTime)
                    print(time)

                    
                    if isSearchCancelled == false {
                        DispatchQueue.main.async { [unowned self] in
                            self.delegate?.searcher( didFindUnusedImage: strFile)
                        }
                    }
                }
            }
            let time: TimeInterval = Date().timeIntervalSince(startTime)
            print(time)

            DispatchGroup().notify(queue: DispatchQueue.main) {
                DispatchQueue.main.async {
                    print("This is run on the main queue, after the previous code in outer block")
                    self.delegate?.searcher( didFinishSearch: self.results)
                    self.fileData.removeAll()
                    self.isSearching = false
                }
            }
        }
        
    }
    
    var searchSettings : [String] {
        var settings: [String] = []
        if mSearch {
            settings.append("m")
        }
        if xibSearch {
            settings.append("xib")
        }
        if storyboardSearch {
            settings.append("storyboard")
        }
        if cppSearch {
            settings.append("cpp")
        }
        if headerSearch {
            settings.append("h")
        }
        if htmlSearch {
            settings.append("html")
        }
        if mmSearch {
            settings.append("mm")
        }
        if plistSearch {
            settings.append("plist")
        }
        if cssSearch {
            settings.append("css")
        }
        if swiftSearch {
            settings.append("swift")
        }
        return settings
    }
    
    
    func ValidImage(atPath imagePath: URL) -> Bool {
        // Grab image name
        let imageName = imagePath.lastPathComponent
        let imagePathStr = imagePath.path
        
        // Check if is retina
        let supportedRetina = supportedRetinaImagePostfixes
        for retinaRangeString in supportedRetina {
            let retinaRange: NSRange? = (imageName as NSString?)?.range(of: retinaRangeString )
            if Int(retinaRange?.location ?? 0) != NSNotFound {
                return false
            }
        }
        
        // Check for reserved names
        let isThirdPartyBundle: Bool = Int((imagePathStr as NSString).range(of: ".bundle").length ) > 0
        let isNamedDefault: Bool = imageName == "Default.png"
        let isNamedIcon: Bool = (imageName == "Icon.png") || (imageName == "Icon@2x.png") || (imageName == "Icon-72.png")
        let isUniversalImage: Bool = Int((imagePathStr as NSString?)?.range(of: "~ipad", options: .caseInsensitive).length ?? 0) > 0
        return !(isThirdPartyBundle && isNamedDefault && isNamedIcon && isUniversalImage)
    }
    
    func occurancesOfImageNamed(_ imageName: String,  directoryPath: String,  typeExtension: String) -> Int {
        
        fileDataLock = NSLock()
        var data = fileData[directoryPath] as? Data
        if data == nil {
            
            // Setup the call
            var name = URL(fileURLWithPath: imageName, isDirectory: false).deletingPathExtension().lastPathComponent
            if typeExtension == "swift" {
                name = "\"" + name + "\""
            }
            
            let cmd = "IFS=\"$(printf '\n\t')\";file=\"\(directoryPath)\";name='\(name)'; for filename in `find $file -name '*.\(typeExtension)'`; do cat $filename 2>/dev/null | grep -o $name; done"
            //NSString *cmd = [NSString stringWithFormat:@"for filename in `find %@ -name '*.%@'`; do cat $filename 2>/dev/null | grep -o %@ ; done", directoryPath, extension, [imageName stringByDeletingPathExtension]];
            
 //           print(cmd)
            
            let process = Process()
            process.launchPath = "/bin/sh"

            let argvals = ["-c", cmd]
            process.arguments = argvals
            let pipe = Pipe()
            process.standardOutput = pipe
            process.launch()
            
            // Read the response
            data = pipe.fileHandleForReading.readDataToEndOfFile()
            let key = "\(directoryPath )/\(imageName )"
            fileData[key] = data
        }
        fileDataLock!.unlock()
        
        let string = String(data: data!, encoding: .utf8)
        var count = 0
        if string != "" {
            
            // Calculate the count
            string?.enumerateLines{ (str, _) in
                count += 1
            }
        }
        return count
    }
    
}
