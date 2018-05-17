# FastSwiftBlur

## About

This is demo project with very fast blurring image through Apple Accelerate framework

## Technology

There are many ways for image processing on `iPhone`. One of them is very popular `CIFilter`, and other is `vImage` from `Accelerate` framework. `vImage` manipulates large images using CPU's vector processor. You can read about `vImage` [here](https://developer.apple.com/documentation/accelerate/vimage).

In this project we used some optimization magic. First of all image is downscaled for showing size via `vImageScale`, then it is cached in buffer. For blur we use `vImageTentConvolve`. Repetitive blur operations are putted in queue with background priority, and we delete unnecessary ones.

## Using

- You can use `FastBlurImageView` instead of `UIImageView` and set blurRadius in it.

```
    let imageView = FastBlurImageView()
    imageView.blurRadius = 5
```

- You can use `FastBlurManager` directly.

```
    FastBlurManager.renderBlur(for: blurWorker, with: self, radius: blurRadius,
            callback: { [weak self] blurredImage in
                self?.setImage(image: blurredImage)
            })
```

- You can use `UIImage` extension.

```
    let myImage = UIImage(named: "blur_me")
    let blurredResult = myImage.fastBlur(radius: 10, scaledTo: CGSize(width: 100, height: 100))
```
 
## License

`FastSwiftBlur` is available under the `MIT license`.