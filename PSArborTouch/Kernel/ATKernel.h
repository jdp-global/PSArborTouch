//
//  ATKernel.h
//  PSArborTouch
//
//  Created by Ed Preston on 22/09/11.
//  Copyright 2011 Preston Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <dispatch/dispatch.h>

@class ATPhysics;
@class ATParticle;
@class ATSpring;
@class ATSystemEnergy;

@interface ATKernel : NSObject
{

@private
    dispatch_source_t   _timer;
    dispatch_queue_t    _queue;
    
    BOOL                _paused;
    BOOL                _running;
    
    ATPhysics          *_physics;
    ATSystemEnergy     *_lastEnergy;
}


// ? Know when results are ready and call the render code ?


#pragma mark - Simulation Control

- (void) physicsUpdate;
- (void) start:(BOOL)unpause;
- (void) stop;


#pragma mark - Cached Physics Properties

@property (nonatomic, readonly, copy) ATSystemEnergy *energy;


#pragma mark - Protected Physics Interface

// Physics methods protected by a GCD queue to ensure serial execution.
// TODO: Move into protocol / interface definition

- (void)addParticle:(ATParticle *)particle;
- (void)removeParticle:(ATParticle *)particle;

- (void)addSpring:(ATSpring *)spring;
- (void)removeSpring:(ATSpring *)spring;


@end