//
//  ViewController.m
//  MobileCraft
//
//  Created by Clapeysron on 19/12/2017.
//  Copyright © 2017 Clapeysron. All rights reserved.
//

#import "ViewController.h"
#import "GameLink.h"
#import "Shader.h"

@interface CraftViewController () {
    GameLink *game;
    GLKMatrix4 steve_view;
    GLKMatrix4 steve_projection;
    GLKVector3 cameraFront;
    GLKVector3 cameraUP;
    GLKVector3 steve_position;
    float yaw;
    float pitch;
    float fov;
    Shader *Block_Shader;
}
@property (strong, nonatomic) EAGLContext *context;

@end

@implementation CraftViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *) self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    game = [[GameLink alloc] init];
    [self setupGL];
    [self render_initial];
    game->gameCPP->chunk.generateMap();
}

- (void)setupGL {
    [EAGLContext setCurrentContext:self.context];
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    //glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
}

- (void)render_initial {
    steve_position = [game vec3:game->gameCPP->steve_position];
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    steve_view = GLKMatrix4MakeLookAt(steve_position.x, steve_position.y, steve_position.z, steve_position.x + cameraFront.x, steve_position.y + cameraFront.y, steve_position.z + cameraFront.z, cameraFront.x, cameraFront.y, cameraFront.z);
    steve_projection = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(fov), aspect, 0.1f, 1000.0f);
    Block_Shader = [[Shader alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Block" ofType:@"vs"] fs:[[NSBundle mainBundle] pathForResource:@"Block" ofType:@"fs"]];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(0.2f, 0.2f, 0.2f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    steve_projection = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(fov), aspect, 0.1f, 1000.0f);
    steve_position = [game vec3:game->gameCPP->steve_position];
    steve_view = GLKMatrix4MakeLookAt(steve_position.x, steve_position.y, steve_position.z, steve_position.x + cameraFront.x, steve_position.y + cameraFront.y, steve_position.z + cameraFront.z, cameraFront.x, cameraFront.y, cameraFront.z);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
