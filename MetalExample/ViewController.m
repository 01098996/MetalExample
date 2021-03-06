//
//  ViewController.m
//  MetalExample
//
//  Created by ZhangXiaoJun on 2017/10/15.
//  Copyright © 2017年 XiaoJunZhang. All rights reserved.
//

#import "ViewController.h"
#import <MetalKit/MetalKit.h>

@interface ViewController () <MTKViewDelegate>
@property (weak, nonatomic) IBOutlet MTKView *displayView;
@property (nonatomic, strong) id<MTLTexture> texutre;
@property (nonatomic, strong) id<MTLCommandQueue> commnadQueue;
@property (nonatomic, strong) id<MTLComputePipelineState> computePipelineState;
@property (nonatomic, strong) id<MTLBuffer> resultBuffer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    self.displayView.device = device;
    self.displayView.delegate = self;
    
    // framebufferOnly表示view的framebuffer只能用作显示，不能作为离屏渲染与并行计算的写入
    [self.displayView setFramebufferOnly:NO];
    
    self.commnadQueue = [device newCommandQueue];
    
    MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:device];
    NSError *error;
    self.texutre = [textureLoader newTextureWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"IMG_0365" withExtension:@"png"]
                                                      options:nil
                                                        error:&error];
    
    NSAssert(!error && self.texutre, @"加载纹理出错");
    
    id<MTLLibrary> library = [device newDefaultLibrary];
    id<MTLFunction> function = [library  newFunctionWithName:@"grayKernel"];
    self.computePipelineState = [device newComputePipelineStateWithFunction:function
                                                                      error:&error];
    NSAssert(!error && self.computePipelineState, @"加载脚本出错");
    
    switch (self.texutre.pixelFormat) {
        case MTLPixelFormatRGBA16Unorm:
            self.resultBuffer = [device newBufferWithLength:self.texutre.width * self.texutre.height * 4 * sizeof(GLubyte)
                                                    options:MTLResourceOptionCPUCacheModeDefault];
            break;
        default:
            NSAssert(NO, @"pixelFormat is unsupport !!!!");
            break;
    }
}

- (IBAction)save:(id)sender{
    CGSize size = CGSizeMake(self.texutre.width, self.texutre.height);
    GLubyte *imageBytes = [self.resultBuffer contents];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext = CGBitmapContextCreate(imageBytes,
                                                      size.width,
                                                      size.height,
                                                      8,
                                                      size.width * 4,
                                                      colorSpace,
                                                      kCGImageAlphaPremultipliedLast);
    
    
    CGContextTranslateCTM(imageContext, 0, size.height);
    CGContextScaleCTM(imageContext, 1, -1);
    
    CGImageRef imageRef = CGBitmapContextCreateImage(imageContext);
    UIImage *resultImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(colorSpace);
    UIImageWriteToSavedPhotosAlbum(resultImage, nil, nil, nil);
}

- (void)drawInMTKView:(nonnull MTKView *)view {
    
    id<MTLTexture> outputTexture = [[view currentDrawable] texture];
    id<MTLCommandBuffer> commandBuffer = [self.commnadQueue commandBuffer];
    id<MTLComputeCommandEncoder> computeCommandEncoder = [commandBuffer computeCommandEncoder];
    [computeCommandEncoder setComputePipelineState:self.computePipelineState];
    [computeCommandEncoder setTexture:self.texutre atIndex:0];
    [computeCommandEncoder setTexture:outputTexture atIndex:1];
    
    NSUInteger threadExecutionWidth = [self.computePipelineState threadExecutionWidth];
    NSUInteger maxTotalThreadsPerThreadgroup = [self.computePipelineState maxTotalThreadsPerThreadgroup];
    MTLSize threadgroupCounts = MTLSizeMake(threadExecutionWidth * 2, threadExecutionWidth * 2, 1);
    MTLSize threadsPerThreadGroup = MTLSizeMake([self.texutre width] / threadgroupCounts.width + 1,
                                                [self.texutre height] / threadgroupCounts.height + 1,
                                                1);
    NSAssert(threadsPerThreadGroup.width * threadsPerThreadGroup.height < maxTotalThreadsPerThreadgroup, @"单个线程组超出最大线程数");
    [computeCommandEncoder setBuffer:self.resultBuffer offset:0 atIndex:0];
    [computeCommandEncoder dispatchThreadgroups:threadgroupCounts
                          threadsPerThreadgroup:threadsPerThreadGroup];
    [computeCommandEncoder endEncoding];
    [commandBuffer presentDrawable:[view currentDrawable]];
    [commandBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
 
}

@end
