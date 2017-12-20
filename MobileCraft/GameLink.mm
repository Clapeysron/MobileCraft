//
//  GameLink.m
//  MobileCraft
//
//  Created by Clapeysron on 20/12/2017.
//  Copyright © 2017 Clapeysron. All rights reserved.
//

#import "GameLink.h"

@implementation GameLink

-(id)init {
    self = [super init];
    if (self) {
        gameCPP = new Game();
    }
    return self;
}

- (GLKVector3)vec3: (glm::vec3)in {
    return GLKVector3Make(in.x, in.y, in.z);
}

@end
