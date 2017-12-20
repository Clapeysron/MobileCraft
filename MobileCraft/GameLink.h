//
//  GameLink.h
//  MobileCraft
//
//  Created by Clapeysron on 20/12/2017.
//  Copyright © 2017 Clapeysron. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#include "Game.hpp"
#include "glm/glm.hpp"

@interface GameLink : NSObject {
    @public Game *gameCPP;
}

- (GLKVector3)vec3: (glm::vec3)in;

@end
