//
//  Extensions.swift
//  BorgMachine
//
//  Created by Brendan Molloy on 1/4/17.
//  Copyright © 2017 Brendan Molloy. All rights reserved.
//

import Cocoa
import RxSwift

infix operator =>

func =>(lhs: Disposable, rhs: DisposeBag) {
    rhs.insert(lhs)
}

func +=(lhs: DisposeBag, rhs: Disposable) {
    lhs.insert(rhs)
}

extension JSONSerialization {
    static func jsonDict(with data: Data) -> [String: Any]? {
        let anyObj = try? JSONSerialization.jsonObject(with: data, options: [])
        
        if let anyObj = anyObj {
            return anyObj as? [String: Any]
        }
        
        return nil
    }
}

extension NSMenuItem {
    convenience init(title: String, action: Selector? = nil) {
        self.init(title: title, action: action, keyEquivalent: "")
    }
}

protocol Nibbable {}

extension Nibbable where Self: NSView {
    static var nibName: String {
        return String(describing: self)
    }
    
    static func loadFromNib() -> Self {
        let bundle = Bundle(for: Self.self)
        
        var views = NSArray()
        bundle.loadNibNamed(nibName, owner: Self.self, topLevelObjects: &views)
        
        guard let view = views.first(where: { $0 is Self }) as? Self else {
            fatalError("Nib could not be loaded for nibName: \(self.nibName); check that the XIB owner has been set to the given view: \(self)")
        }
        
        return view
    }
}

class ViewController<T: NSView>: NSViewController where T: Nibbable {
    let contentView = T.loadFromNib()
    
    override func loadView() {
        view = contentView
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)!
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Date {
    func iso8601String() -> String {
        let formatter = DateFormatter()
        let locale = Locale(identifier: "en_US_POSIX")
        formatter.locale = locale
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        return formatter.string(from: self)
    }
}


extension FileManager {
    // http://stackoverflow.com/a/28660040
    // https://gist.github.com/NikolaiRuhe/eeb135d20c84a7097516
    func allocatedDirectorySize(at directoryURL: URL) throws -> Int64 {
        var accumulatedSize = Int64(0)
        
        let prefetchedProperties: [URLResourceKey] = [
            .isRegularFileKey,
            .fileAllocatedSizeKey,
            .totalFileAllocatedSizeKey,
        ]
        
        var errorDidOccur: Error?
        let errorHandler: (URL, Error) -> Bool = { _, error in
            errorDidOccur = error
            return false
        }
        
        let enumerator = self.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: prefetchedProperties,
            options: [],
            errorHandler: errorHandler)!
        
        for item in enumerator {
            let contentItemURL = item as! URL
            
            if let error = errorDidOccur { throw error }
            
            guard let isRegularFile = try contentItemURL.resourceValues(forKeys: [URLResourceKey.isRegularFileKey]).isRegularFile else {
                preconditionFailure()
            }
            
            guard isRegularFile else {
                continue
            }
            
            let res = try contentItemURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .totalFileSizeKey])
            let size = Int64(res.totalFileSize ?? res.fileSize ?? 0)
            
            accumulatedSize += size
        }
        
        if let error = errorDidOccur { throw error }
        
        return accumulatedSize
    }
}
