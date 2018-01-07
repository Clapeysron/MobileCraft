//
//  Shader.m
//  MobileCraft
//
//  Created by Clapeysron on 19/12/2017.
//  Copyright © 2017 Clapeysron. All rights reserved.
//

#import "Shader.h"

@implementation Shader

- (id) init {
    self = [super init];
    if(self) {
    }
    return self;
}

- (id) initWithPath: (NSString *)vertexPath fs:(NSString *)fragPath id_num:(int)id_num {
    GLuint vertex, fragment = 0;
    if (![self compileShader:&vertex type:GL_VERTEX_SHADER file:vertexPath]) {
        NSLog(@"Failed to compile vertex shader");
        return nil;
    }
    
    if (![self compileShader:&fragment type:GL_FRAGMENT_SHADER file:fragPath]) {
        NSLog(@"Failed to compile fragment shader");
        return nil;
    }
    ID = glCreateProgram();
    glAttachShader(ID, vertex);
    glAttachShader(ID, fragment);
    if (id_num == 1) {
        glBindAttribLocation(ID, 0, "aPos");
    } else if (id_num == 2) {
        glBindAttribLocation(ID, 0, "aPos");
        glBindAttribLocation(ID, 1, "aNormal");
    } else if (id_num == 3) {
        glBindAttribLocation(ID, 0, "aPos");
        glBindAttribLocation(ID, 1, "aNormal");
        glBindAttribLocation(ID, 2, "aTexCoord");
    } else if (id_num == 4) {
        glBindAttribLocation(ID, 0, "aPos");
        glBindAttribLocation(ID, 1, "aNormal");
        glBindAttribLocation(ID, 2, "aTexCoord");
        glBindAttribLocation(ID, 3, "aShadow");
    } else if (id_num == 5) {
        glBindAttribLocation(ID, 0, "aPos");
        glBindAttribLocation(ID, 1, "aNormal");
        glBindAttribLocation(ID, 2, "aTexCoord");
        glBindAttribLocation(ID, 3, "aShadow");
        glBindAttribLocation(ID, 4, "aBrightness");
    }
    if(![self linkProgram:ID]) {
        NSLog(@"Failed to link program: %d", ID);
        if (vertex) {
            glDeleteShader(vertex);
            vertex = 0;
        }
        if (fragment) {
            glDeleteShader(fragment);
            fragment = 0;
        }
        if (ID) {
            glDeleteProgram(ID);
            ID = 0;
        }
        return nil;
    }
    if (vertex) {
        glDetachShader(ID, vertex);
        glDeleteShader(vertex);
    }
    if (fragment) {
        glDetachShader(ID, fragment);
        glDeleteShader(fragment);
    }
    return self;
}

- (void)use {
    glUseProgram(ID);
}

- (void)setBool:(NSString *)name value:(BOOL)value {
    glUniform1i(glGetUniformLocation(ID, [name UTF8String]), (int)value);
}

- (void)setInt:(NSString *)name value:(int)value {
    glUniform1i(glGetUniformLocation(ID, [name UTF8String]), value);
}

- (void)setFloat:(NSString *)name value:(float)value {
    glUniform1f(glGetUniformLocation(ID, [name UTF8String]), value);
}

- (void)setVec2:(NSString *)name value:(GLKVector2)value {
    glUniform2fv(glGetUniformLocation(ID, [name UTF8String]), 1, value.v);
}

- (void)setVec2:(NSString *)name x:(float)x y:(float)y {
    glUniform2f(glGetUniformLocation(ID, [name UTF8String]), x, y);
}

- (void)setVec3:(NSString *)name value:(GLKVector3)value {
        glUniform3fv(glGetUniformLocation(ID, [name UTF8String]), 1, value.v);
}

- (void)setVec3:(NSString *)name x:(float)x y:(float)y z:(float)z {
    glUniform3f(glGetUniformLocation(ID, [name UTF8String]), x, y, z);
}

- (void)setVec4:(NSString *)name value:(GLKVector3)value {
    glUniform4fv(glGetUniformLocation(ID, [name UTF8String]), 1, value.v);
}

- (void)setVec4:(NSString *)name x:(float)x y:(float)y z:(float)z w:(float)w {
    glUniform4f(glGetUniformLocation(ID, [name UTF8String]), x, y, z, w);
}

- (void)setMat2:(NSString *)name value:(GLKMatrix2)value {
    glUniformMatrix2fv(glGetUniformLocation(ID, [name UTF8String]), 1, GL_FALSE, value.m);
}

- (void)setMat3:(NSString *)name value:(GLKMatrix3)value {
    glUniformMatrix3fv(glGetUniformLocation(ID, [name UTF8String]), 1, GL_FALSE, value.m);
}

- (void)setMat4:(NSString *)name value:(GLKMatrix4)value {
    glUniformMatrix4fv(glGetUniformLocation(ID, [name UTF8String]), 1, GL_FALSE, value.m);
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}
@end
