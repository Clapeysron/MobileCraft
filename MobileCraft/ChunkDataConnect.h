//
//  ChunkDataConnect.h
//  MobileCraft
//
//  Created by Clapeysron on 20/12/2017.
//  Copyright © 2017 Clapeysron. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "ChunkData.hpp"

@interface ChunkDataConnect : NSObject {
    Chunk *chunk;
    VisibleChunks *visibleChunks;
    Block *block;
}

@end
