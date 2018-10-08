//
//  FileUtil.swift
//  unusedResources
//
//  Created by thierryH24 on 02/10/2018.
//  Copyright © 2018 thierryH24. All rights reserved.
//

import Cocoa

class FileUtil: NSObject {
    
    static let shared = FileUtil()

    
    func stringFromFileSize( fileSize: Int) ->String {
        if fileSize < 1023 {
             return String(format: "%i bytes", fileSize)
        }
        var floatSize = Float(fileSize / 1024)
        if floatSize < 1023 {
            return (String(format: "%1.1f KB", floatSize))
        }
        floatSize = floatSize / 1024
        if floatSize < 1023 {
            return String(format: "%1.1f MB", floatSize)
        }
        floatSize = floatSize / 1024
        return String(format: "%1.1f GB", floatSize)
    }
    
    func imageFiles(inDirectory directoryPath: String?) -> [String]? {
        var images: [String] = []
        // jpg
        let jpg = self.searchDirectory(directoryPath, forFiletype: "jpg")
        if let aJpg = jpg {
            images.append(contentsOf: aJpg)
        }
        // jpeg
        let jpeg = self.searchDirectory(directoryPath, forFiletype: "jpeg")
        if let aJpeg = jpeg {
            images.append(contentsOf: aJpeg)
        }
        // png
        let png = self.searchDirectory(directoryPath, forFiletype: "png")
        if let aPng = png {
            images.append(contentsOf: aPng)
        }
        // gif
        let gif = self.searchDirectory(directoryPath, forFiletype: "gif")
        if let aGif = gif {
            images.append(contentsOf: aGif)
        }
        return images
    }
    
    func searchDirectory(_ directoryPath: String?, forFiletype filetype: String) -> [String]? {
        
        // Create a find task
        let task = Process()
        task.launchPath = "/usr/bin/find"
        
        // Search for all png files
        let argvals = [directoryPath, "-name", "*.\(filetype)"]
        task.arguments = (argvals as! [String])
        let pipe = Pipe()
        task.standardOutput = pipe
        
        // Run task
        task.launch()
        
        // Read the response
        let file = pipe.fileHandleForReading
        let data = file.readDataToEndOfFile()
        let string = String(data: data, encoding: .utf8)
        
        // See if we can create a lines array
        let lines = string?.components(separatedBy: "\n")
        return lines
    }
}
