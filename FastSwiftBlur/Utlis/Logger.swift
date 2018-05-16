//
// Created by Maxim on 16/05/2018.
// Copyright (c) 2018 Aspirity. All rights reserved.
//

import Foundation

public func log(_ message: Any = "", path: String = #file, lineNumber: Int = #line, function: String = #function) {
#if DEBUG
    let thread = Thread.current
    var threadName = "";
    if thread.isMainThread {
        threadName = "Main";
    } else if let name = thread.name, !name.isEmpty {
        threadName = name;
    } else {
        threadName = String(format: "%p", thread);
    }

    if let fileName = NSURL(fileURLWithPath: path).deletingPathExtension?.lastPathComponent {
        print("[\(threadName)] \(fileName).\(function):\(lineNumber) -- \(message)");
    } else {
        print("[\(threadName)] \(path).\(function):\(lineNumber) -- \(message)");
    }
#endif
}