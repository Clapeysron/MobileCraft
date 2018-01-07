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
- (id) initWithPath: (NSString *)vertexPath fs:(NSString *)fragPath id_num:(int) id_num;
- (void)use;
- (void)setBool:(NSString *)name value:(BOOL)value;
- (void)setInt:(NSString *)name value:(int)value;
- (void)setFloat:(NSString *)name value:(float)value;
- (void)setVec2:(NSString *)name value:(GLKVector2)value;
- (void)setVec2:(NSString *)name x:(float)x y:(float)y;
- (void)setVec3:(NSString *)name value:(GLKVector3)value;
- (void)setVec3:(NSString *)name x:(float)x y:(float)y z:(float)z;
- (void)setVec4:(NSString *)name value:(GLKVector3)value;
- (void)setVec4:(NSString *)name x:(float)x y:(float)y z:(float)z w:(float)w;
- (void)setMat2:(NSString *)name value:(GLKMatrix2)value;
- (void)setMat3:(NSString *)name value:(GLKMatrix3)value;
- (void)setMat4:(NSString *)name value:(GLKMatrix4)value;
@end
