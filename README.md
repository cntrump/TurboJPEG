## TurboJPEG

an Objective-C wrapper for libjpeg-turbo.

useage:

`#import <TurboJPEG/TurboJPEG.h>`

`encode` UIImage to JPEG data

```objc
UIImage *image = ...;
NSData *jpegData = [UIImage dataUsingTurboJpegWithImage:image jpegQual:0.75];
```

`decode` JPEG data to UIImage

```objc
NSData *jpegData = ...;
UIImage *image = [UIImage imageUsingTurboJpegWithData:jpegData];
```
