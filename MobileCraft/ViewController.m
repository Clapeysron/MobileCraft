//
//  ViewController.m
//  MobileCraft
//
//  Created by Clapeysron on 19/12/2017.
//  Copyright © 2017 Clapeysron. All rights reserved.
//

#import "ViewController.h"
#import "Shader.h"

@interface ViewController () {
    Shader *Block_Shader;
}

@property (strong, nonatomic) EAGLContext *context;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *) self.view;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [self setupGL];
}

- (void)setupGL {
    [EAGLContext setCurrentContext:self.context];
    Block_Shader = [[Shader alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Block" ofType:@"vs"] fs:[[NSBundle mainBundle] pathForResource:@"Block" ofType:@"fs"]];
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    //glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
