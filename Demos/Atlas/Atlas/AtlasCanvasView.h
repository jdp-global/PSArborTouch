//
//  AtlasCanvasView.h
//  Atlas
//
//  Created by Ed Preston on 4/10/11.
//  Copyright 2011 Preston Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATSystem;

@interface AtlasCanvasView : UIScrollView
{
@private
    ATSystem *system_;
    BOOL debugDrawing_;
    UIFont *font_;
    UIImage *ball;
}

@property (nonatomic, retain) ATSystem *system;
@property (nonatomic, assign, getter=isDebugDrawing) BOOL debugDrawing;
-(void)updateParticleViews;
@end
