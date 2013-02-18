//
//  AtlasViewController.m
//  Atlas - PSArborTouch Example
//
//  Created by Ed Preston on 3/10/11.
//  Copyright 2011 Preston Software. All rights reserved.
//

#import "AtlasViewController.h"
#import "AtlasCanvasView.h"

#import "PSArborTouch.h"
#import "CJSONDeserializer.h"


@interface AtlasViewController ()

- (void) loadMapData;

- (void) addGestureRecognizersToCanvas:(UIView *)canvas;
- (void) showLongTouchMenu:(UILongPressGestureRecognizer *)gestureRecognizer;
//- (void) resetHandler:(UIMenuController *)controller;
- (void) debugHandler:(UIMenuController *)controller;
- (void) panHandler:(UIPanGestureRecognizer *)gestureRecognizer;
//- (void) rotateHandler:(UIRotationGestureRecognizer *)gestureRecognizer;
//- (void) pinchHandler:(UIPinchGestureRecognizer *)gestureRecognizer;

@end


@implementation AtlasViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
       
    CGRect frame = self.view.bounds;
    frame.origin.y =44;
    frame.size.height -=44;
    frame.size.width -=100;
    
    canvas_ = [[AtlasCanvasView alloc]initWithFrame:frame];
    canvas_.autoresizesSubviews = YES;
   
    canvas_.autoresizingMask = UIViewAutoresizingFlexibleHeight |UIViewAutoresizingFlexibleWidth;
    
    //scrollview
    canvas_.delegate = self;
    canvas_.showsHorizontalScrollIndicator = YES;
    canvas_.showsVerticalScrollIndicator = YES;
    [canvas_ setContentSize:CGSizeMake(6000,6000)];
    [canvas_ setMinimumZoomScale:0.5];
    [canvas_ setMaximumZoomScale:3.0];
    [canvas_ setBackgroundColor:[UIColor blueColor]];
    
    
    [self.view addSubview:canvas_];
    UIButton *addNode = [UIButton buttonWithType:UIButtonTypeCustom];
    [addNode setFrame:CGRectMake(10, 50, 44, 44)];
    [addNode setBackgroundColor:[UIColor redColor]];
    [addNode addTarget:self action:@selector(addNodeClicked)  forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:addNode];
    
  
    UIButton *removeNode = [UIButton buttonWithType:UIButtonTypeCustom];
    [removeNode setFrame:CGRectMake(10, 100, 44, 44)];
    [removeNode setBackgroundColor:[UIColor redColor]];
    [removeNode addTarget:self action:@selector(removeNodeClicked)  forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:removeNode];

    
    // Create our particle system
    system_ = [[ATSystem alloc] init];
    
    
    // Configure simulation parameters, (take a copy, modify it, update the system when done.)
    ATSystemParams *params = system_.parameters;
    
    params.repulsion = 100.0;
    params.stiffness = 10.0;
    params.friction  = 0.2;
    params.precision = 0.6;
    
    system_.parameters = params;
    
    // Setup the view bounds
    system_.viewBounds = canvas_.bounds;
    
    // leave some space at the bottom and top for text
    system_.viewPadding = UIEdgeInsetsMake(60.0, 60.0, 60.0, 60.0);
    
    // have the ‘camera’ zoom somewhat slowly as the graph unfolds 
    system_.viewTweenStep = 0.2;
    
    // set this controller as the system's delegate
    system_.delegate = self;
    
    // DEBUG
    canvas_.system = system_;
    canvas_.debugDrawing = NO;  // Do long press gesture to toggle.
    
    // load the map data
    [self loadMapData];
    [canvas_ performSelector:@selector(updateParticleViews) withObject:nil afterDelay:5];
//    [canvas_ updateParticleViews];
    
    // start the simulation
    [system_ start:YES];
    
    // set up touch event handling
    //[self addGestureRecognizersToCanvas:canvas_];
}


- (void) viewDidUnload
{
   
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [system_ release];
}



- (void)dealloc {
    [canvas_ release];
    [super dealloc];
}



#pragma mark - Data Loading

-(void) loadMapData
{
    // Find the file
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"usofa" ofType:@"json"];
    if (filePath) {
        // Load data in the file
        NSData *theJSONData = [NSData dataWithContentsOfFile:filePath];
        if (theJSONData) {
            // Parse the file
            NSError *theError = nil;
            NSDictionary *theObject = [[CJSONDeserializer deserializer] deserializeAsDictionary:theJSONData 
                                                                                          error:&theError];
            if (theObject) {
                
                // Add Nodes and Edges
                
                // Issue with concurrent loading is the potential for duplicate nodes. Load the nodes first.
                // For example, node creation might be in the GCD queue but when we query if it exists, it
                // has not made it there yet.
                
               /* NSDictionary *nodes = [theObject objectForKey:@"nodes"];
                
                [nodes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    
                    [system_ addNode:key withData:nil];
                    
                }];*/
                
                // Comment out the code above to see this example.
                // Instead of loading the nodes, lets just load the edges and have the system construct
                // the nodes when it finds they have not been previously defined.  Not the optimal way to 
                // go about things but easy.
                
                NSMutableDictionary *edges = [NSMutableDictionary dictionaryWithDictionary:[theObject objectForKey:@"edges"]];
                
                NSLog(@"edges:%@",edges);
                // Lets see how the system handles concurrent graph loading (NSEnumerationConcurrent)
                // The simulation should handle this correctly.
              
                [edges enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id key, id obj, BOOL *stop) {
                   
                    NSString *source = key;
                    NSDictionary *targets = obj;
                    
                    // How about an extra measure of concurrency within the concurrency.
                    NSLog(@"source:%@",source);
                    NSLog(@"targets:%@",targets);
                    
                    NSMutableDictionary *userDataDict = [targets objectForKey:@"userData"];
                    
                    [targets enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id key, id obj, BOOL *stop) {
                        
                        NSLog(@"Source %@ -> %@", source, key);
                        
                        if (![key isEqualToString:@"userData"]) {
                            // Create the edge, and by proxy, create the nodes
                            [system_ addEdgeFromNode:source toNode:key withData:userDataDict];
                        }
                        
           
                    }];
                
                }];
                
            } else {
                NSLog(@"Could not parse JSON file.");
            }
        } else {
            NSLog(@"Could not load NSData from file.");
        }
    } else {
        NSLog(@"Please include america.json in the project resources.");
    }
}


#pragma mark - Rendering

- (void) redraw
{
    // Sync with screen refresh
    [canvas_ setNeedsDisplay];
}


#pragma mark - Interface Actions

- (IBAction) launchSourceURL:(id)sender
{
    // launch a URL in Safari
    [[UIApplication sharedApplication] openURL:[NSURL 
    URLWithString:@"http://www.statemaster.com/graph/geo_lan_bou_bor_cou-geography-land-borders"]];
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer 
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // ensure that the pinch, pan and rotate gesture recognizers on a particular view can all recognize 
    // simultaneously prevent other gesture recognizers from recognizing simultaneously
    
    // if the gesture recognizers's view isn't ours, don't allow simultaneous recognition
    if (gestureRecognizer.view != canvas_)
        return NO;
    
    // if the gesture recognizers are on different views, don't allow simultaneous recognition
    if (gestureRecognizer.view != otherGestureRecognizer.view)
        return NO;
    
    // if either of the gesture recognizers is the long press, don't allow simultaneous recognition
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] || 
        [otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]])
        return NO;
    
    
    // if either of the gesture recognizers is the pan, don't allow simultaneous recognition
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] || 
        [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
        return NO;
    
    return YES;
}


#pragma mark - Touch Handleing

- (void) addGestureRecognizersToCanvas:(UIView *)canvas
{
  
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self 
                                                                                 action:@selector(panHandler:)]; // LOL !
    [panGesture setMaximumNumberOfTouches:2];
    [panGesture setDelegate:self];
    [canvas addGestureRecognizer:panGesture];
    [panGesture release];
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self 
                                                                                                   action:@selector(showLongTouchMenu:)];
    [canvas addGestureRecognizer:longPressGesture];
    [longPressGesture release];
}

- (void) showLongTouchMenu:(UILongPressGestureRecognizer *)gestureRecognizer
{
    // display a menu with a single item to allow the simulation to be reset
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
        UIMenuController *menuController = [UIMenuController sharedMenuController];
//        UIMenuItem *resetMenuItem = [[UIMenuItem alloc] initWithTitle:@"Reset" action:@selector(resetHandler:)];
        UIMenuItem *debugMenuItem = [[UIMenuItem alloc] initWithTitle:@"Debug" action:@selector(debugHandler:)];
        
        CGPoint location = [gestureRecognizer locationInView:[gestureRecognizer view]];
        
        [self becomeFirstResponder];
        [menuController setMenuItems:[NSArray arrayWithObject:debugMenuItem]];
        [menuController setTargetRect:CGRectMake(location.x, location.y, 0, 0) inView:[gestureRecognizer view]];
        [menuController setMenuVisible:YES animated:YES];
        
//        [resetMenuItem release];
        [debugMenuItem release];
    }
}

//- (void) resetHandler:(UIMenuController *)controller
//{
//    // Reset the simulation
//}

- (void) debugHandler:(UIMenuController *)controller
{
    canvas_.debugDrawing = !canvas_.debugDrawing;
}

- (BOOL) canBecomeFirstResponder
{
    // UIMenuController requires that we can become first responder or it won't display
    return YES;
}

- (void) panHandler:(UIPanGestureRecognizer *)gestureRecognizer
{
    // move the closest node from the touch position
    static ATNode *node = nil;
    UIView *piece = [gestureRecognizer view];
    CGPoint translation = [gestureRecognizer locationInView:piece];
    
    switch ([gestureRecognizer state]) {
        case UIGestureRecognizerStateBegan:
            node = [system_ nearestNodeToPoint:translation withinRadius:30.0];
            node.fixed = YES;
            break;
        case UIGestureRecognizerStateChanged:
            node.position = [system_ fromViewPoint:translation];
            break;
        default:
            node.fixed = NO;
            
            // [node setTempMass:100.0];
            
            break;
    }
    
    // start the simulation
    [system_ start:YES];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
   // NSLog(@"scrollViewWillBeginDragging");

}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return YES;
}


-(void)removeNodeClicked{
    
    uint32_t rnd0 = arc4random_uniform([system_.state.nodes count]);
    ATNode *randomNode0 = [system_.state.nodes objectAtIndex:rnd0];
    [system_ removeNode:randomNode0.name];
    [canvas_ layoutSubviews];
}
-(void)addNodeClicked{
    NSLog(@"test");

    uint32_t rnd0 = arc4random_uniform([system_.state.nodes count]);
    uint32_t rnd1 = arc4random_uniform([system_.state.nodes count]);
    ATNode *randomNode0 = [system_.state.nodes objectAtIndex:rnd0];
    ATNode *randomNode1 = [system_.state.nodes objectAtIndex:rnd1];
    
    NSNumber *src = randomNode0.index;
    NSNumber *dst = randomNode1.index;
    NSString *srcName = randomNode0.name;
    NSString *dstName = randomNode1.name;
    
    NSMutableDictionary *from = [system_.state getAdjacencyObjectForKey:src];
    
    // Does the edge already exist?
    ATEdge *to = [from objectForKey:dst];
     if (to != nil) {
         
     }else{
         [system_ addEdgeFromNode:[srcName copy] toNode:[dstName copy] withData:nil];
         [canvas_ layoutSubviews];
     }
    
    
}




@end
