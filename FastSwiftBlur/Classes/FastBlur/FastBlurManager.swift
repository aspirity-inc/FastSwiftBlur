//
// In this file implemented external point for working with very fast cached blurring method
// For use it just call FastBlurManager.renderBlur()
//
// Created by Maxim on 07/05/2018.
// Copyright (c) 2018 Aspirity. All rights reserved.
//

import UIKit

/*
* This manager gives ability for fast blurring of image in queue
* It is singleton, so use "renderBlur" method
*/
public class FastBlurManager {

    // --
    fileprivate static let sharedInstance: FastBlurManager = FastBlurManager()

    // --
    fileprivate var isRendering: Bool = false
    fileprivate var tasks: SynchronizedArray<FastBlurTask> = SynchronizedArray()
    fileprivate let blurQueue: DispatchQueue = DispatchQueue(label: "ru.aspirity.fastblurmanager", qos: .background)

    // --
    init() {
    }

}

/*
* Static methods for using this manager
*/
public extension FastBlurManager {

    /*
    * Blurring only image, without optimized cache
    */
    static func renderBlur(for image: UIImage?, with imageView: UIImageView?, radius: Float, callback: ((UIImage?) -> Void)?) {
        guard image != nil else {
            callback?(nil)
            return
        }

        let task = FastBlurTask(image: image, imageView: imageView, blurRadius: radius, blurCallback: callback)
        sharedInstance.addTask(task: task)
        sharedInstance.startRendering()
    }


    /*
    * Blurring image with optimized cache
    */
    static func renderBlur(for worker: FastBlurWorker?, with imageView: UIImageView?, radius: Float, callback: ((UIImage?) -> Void)?) {
        guard worker?.image != nil else {
            callback?(nil)
            return
        }

        let task = FastBlurTask(worker: worker, imageView: imageView, blurRadius: radius, blurCallback: callback)
        sharedInstance.addTask(task: task)
        sharedInstance.startRendering()
    }

}

/*
* Queue implementation for blurring
*/
fileprivate extension FastBlurManager {

    func addTask(task: FastBlurTask) {
        log("add task")
        tasks.add(task)
    }

    func startRendering() {
        guard !isRendering else {
            return
        }

        log("start rendering")
        isRendering = true
        renderNextImage()
    }

    func renderNextImage() {
        guard tasks.count != 0 else {
            log("stop rendering")
            isRendering = false
            return
        }

        guard let last: FastBlurTask = tasks.removeLast() else {
            renderNextImage()
            return
        }
        tasks.filter(by: { (element: FastBlurTask ) in
            return (element.imageView == nil || element.imageView != last.imageView)
        })
        execute(task: last)
    }

    func execute(task: FastBlurTask) {
        guard let _ = task.image, task.blurRadius > 0.0 else {
            log("skip task with blurRadius=\(task.blurRadius)")
            complete(task: task, blurredImage: task.image)
            renderNextImage()
            return
        }

        blurQueue.async { () in
            let blurred: UIImage? = task.getBlurredImage()

            DispatchQueue.main.async { [unowned self] () in
                self.complete(task: task, blurredImage: blurred)
                self.renderNextImage()
            }
        }
    }

    func complete(task: FastBlurTask, blurredImage: UIImage?) {
        log("complete task with blurRadius=\(task.blurRadius)")
        if let blurCallback = task.blurCallback {
            blurCallback(blurredImage)
        } else if let imageView = task.imageView {
            imageView.image = blurredImage
        }
    }

}

// --

/*
* Item for blurring queue
*/
fileprivate class FastBlurTask: CustomStringConvertible {

    // --
    weak var image: UIImage?
    weak var blurWorker: FastBlurWorker?
    weak var imageView: UIImageView?
    var blurRadius: Float
    var blurCallback: ((UIImage?) -> Void)?

    // --
    init(image: UIImage?, imageView: UIImageView?, blurRadius: Float, blurCallback: ((UIImage?) -> Void)?) {
        self.image = image
        self.blurRadius = blurRadius
        self.imageView = imageView
        self.blurCallback = blurCallback
    }

    // --
    init(worker: FastBlurWorker?, imageView: UIImageView?, blurRadius: Float, blurCallback: ((UIImage?) -> Void)?) {
        self.image = worker?.image
        self.imageView = imageView
        self.blurWorker = worker
        self.blurRadius = blurRadius
        self.blurCallback = blurCallback
    }

    // --
    var description: String {
        return "AsyncBlurTask{ blurRadius=\(blurRadius) }"
    }

    // -- methods

    /*
    * Calls blurring method.
    * Depends of image holder it calculates size for image scale
    */
    func getBlurredImage() -> UIImage? {
        let imageViewSizeInPixels: CGSize

        if let imageView = imageView {
            let scale = UIScreen.main.scale
            let imageViewSizeInPoints: CGSize = imageView.frame.size
            imageViewSizeInPixels = CGSize(width: imageViewSizeInPoints.width * scale, height: imageViewSizeInPoints.height * scale)
        } else {
            let screenSize = UIScreen.main.bounds.size
            let scale = UIScreen.main.scale
            imageViewSizeInPixels = CGSize(width: screenSize.width * scale, height: screenSize.height * scale)
        }

        if let blurWorker = blurWorker {
            return blurWorker.fastBlur(with: blurRadius, scaledTo: imageViewSizeInPixels)
        } else {
            return image?.fastBlur(radius: blurRadius, scaledTo: imageViewSizeInPixels)
        }
    }

}

// --

/*
* Utility class for synchronized working with array
*/
fileprivate class SynchronizedArray<Element> {

    private let innerQueue: DispatchQueue = DispatchQueue(label: "ru.apsirity.fastblurtasks", qos: .background)
    private var array: [Element] = []

    init() {
    }

    var count: Int {
        var result = 0
        innerQueue.sync { () in
            result = self.array.count
        }
        return result
    }

    func add(_ task: Element) {
        innerQueue.async { () in
            self.array.append(task)
        }
    }

    func filter(by isIncluded: @escaping (Element) -> Bool) {
        innerQueue.async { () in
            self.array = self.array.filter(isIncluded)
        }
    }

    func removeLast() -> Element? {
        var task: Element?
        innerQueue.sync { () in
            task = self.array.removeLast()
        }
        return task
    }

}
