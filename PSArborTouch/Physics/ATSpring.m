//
//  ATSpring.m
//  PSArborTouch
//
//  Created by Ed Preston on 19/09/11.
//  Copyright 2011 Preston Software. All rights reserved.
//

#import "ATSpring.h"
#import "ATParticle.h"


@interface ATSpring ()
// reserved
@end


@implementation ATSpring

@synthesize stiffness = stiffness_;

- (id) init
{
    self = [super init];
    if (self) {
        stiffness_ = 1000.0;
    }
    return self;
}

- (ATParticle *)point1
{
    return (ATParticle *)self.source; 
}

- (ATParticle *)point2
{
    return (ATParticle *)self.target; 
}


#pragma mark - Geometry

- (CGFloat) distanceToParticle:(ATParticle *)particle 
{
    NSParameterAssert(particle != nil);
    
    return [self distanceToNode:particle];
}



#pragma mark - Internal Interface


@end
