//
//  Shader.h
//  MobileCraft
//
//  Created by Clapeysron on 19/12/2017.
//  Copyright © 2017 Clapeysron. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface Shader : NSObject
{
    unsigned int ID;
}

- (id) init;
- (id) initWithPath: (NSString *)vertexPath fs:(NSString *)fragPath;
@end
