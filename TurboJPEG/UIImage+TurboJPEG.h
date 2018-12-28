//
//  UIImage+TurboJPEG.h
//  TurboJPEG
//
//  Created by cntrump@gmail.com on 2018/12/28.
//  Copyright © 2018 vvveiii. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (TurboJpeg)

+ (UIImage *)imageUsingTurboJpegWithData:(NSData *)data;

+ (NSData *)dataUsingTurboJpegWithImage:(UIImage *)image jpegQual:(CGFloat)jpegQual;

@end
