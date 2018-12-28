//
//  UIImage+TurboJPEG.m
//  TurboJPEG
//
//  Created by cntrump@gmail.com on 2018/12/28.
//  Copyright © 2018 vvveiii. All rights reserved.
//

#import "UIImage+TurboJPEG.h"
#import <turbojpeg.h>

static void CGDataProviderReleaseCallback(void *info, const void *data, size_t size) {
    free((void *)data);
}

static unsigned char *BitmapFromCGImageAndIgnoreAlpha(CGImageRef imageRef) {
    if (!imageRef) {
        return NULL;
    }

    size_t w = CGImageGetWidth(imageRef);
    size_t h = CGImageGetHeight(imageRef);
    unsigned char *buf = (unsigned char *)malloc(w * 4 * h);
    if (!buf) {
        return NULL;
    }

    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(buf, w, h, 8, w * 4, colorSpaceRef, kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast);
    if (!context) {
        CGColorSpaceRelease(colorSpaceRef);
        free(buf);

        return NULL;
    }

    CGContextDrawImage(context, CGRectMake(0, 0, w, h), imageRef);
    CGColorSpaceRelease(colorSpaceRef);
    CGContextRelease(context);

    return buf;
}

static CGImageRef CGImageFromBitmapAndIgnoreAlpha(unsigned char *buf, size_t w, size_t h) {
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef rawImageDataProvider = CGDataProviderCreateWithData(nil,
                                                                          buf,
                                                                          w * 4 * h,
                                                                          &CGDataProviderReleaseCallback);
    CGImageRef imageRef = CGImageCreate(w,
                                        h,
                                        8,
                                        8 * 4,
                                        w * 4,
                                        colorspace,
                                        kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast,
                                        rawImageDataProvider,
                                        NULL,
                                        YES,
                                        kCGRenderingIntentDefault);
    CGDataProviderRelease(rawImageDataProvider);
    CGColorSpaceRelease(colorspace);

    return imageRef;
}

@implementation UIImage(TurboJpeg)

+ (UIImage *)imageUsingTurboJpegWithData:(NSData *)data {
    @autoreleasepool {
        if (data.length == 0) {
            return nil;
        }

        tjhandle handle = tjInitDecompress();

        int width, height;
        tjDecompressHeader(handle, (unsigned char *)data.bytes, data.length, &width, &height);

        if (width < 1 || height < 1) {
            tjDestroy(handle);

            return nil;
        }

        CGSize imageSize = CGSizeMake(width, height);
        uint8_t *imageBuffer = (uint8_t *)malloc(imageSize.width * 4 * imageSize.height);
        int success = tjDecompress2(handle, (unsigned char *)data.bytes, data.length, imageBuffer, imageSize.width, imageSize.width * 4, imageSize.height, TJPF_RGBA, TJFLAG_FASTDCT);
        tjDestroy(handle);

        if (success < 0) {
            free(imageBuffer);

            return nil;
        }

        CGImageRef imageRef = CGImageFromBitmapAndIgnoreAlpha(imageBuffer, imageSize.width, imageSize.height);
        if (!imageRef) {
            return nil;
        }

        UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);

        return finalImage;
    }
}

+ (NSData *)dataUsingTurboJpegWithImage:(UIImage *)image jpegQual:(CGFloat)jpegQual {
    @autoreleasepool {
        int qual = MIN(100, MAX(1, (int)(jpegQual * 100)));

        CGImageRef imageRef = image.CGImage;
        unsigned char *buf = BitmapFromCGImageAndIgnoreAlpha(imageRef);
        if (!buf) {
            return nil;
        }

        size_t w = CGImageGetWidth(imageRef);
        size_t h = CGImageGetHeight(imageRef);
        unsigned char *jpegBuf = NULL;
        unsigned long jpegSize = 0;
        tjhandle handle = tjInitCompress();
        int success = tjCompress2(handle, buf, (int)w, 0, (int)h, TJPF_RGBA, &jpegBuf, &jpegSize, TJSAMP_444, qual, TJFLAG_FASTDCT);
        tjDestroy(handle);
        free(buf);

        if (success < 0) {
            if (jpegBuf) {
                tjFree(jpegBuf);
            }

            return nil;
        }

        NSData *imageData = [NSData dataWithBytes:jpegBuf length:jpegSize];
        tjFree(jpegBuf);

        return imageData;
    }
}

@end
