/*
 *  InstrumentScene.m
 *  Noisemusick
 *
 *  Created by Shawn Wallace on 10/1/11.
 *  Copyright (c) 2011-2012 by Shawn Wallace of the Fluxama Group. 
 *  For information on usage and redistribution, and for a DISCLAIMER OF ALL
 *  WARRANTIES, see the file, "Noisemusick-LICENSE.txt," in this distribution.  */

#import "RevoicerAppDelegate.h"
#import "InstrumentScene.h"
#import "ccMacros.h"
#import "Control.h"
#import "Instrument.h"
#import "Sequence.h"
#import "Pot.h"

#define NUM_STEPS 16
#define BASEBEATS 30.0f

@implementation InstrumentScene
@synthesize instrument_name;

-(id) init {
    self = [super init];
    if (self != nil) {
	    layer = [InstrumentLayer node];
        [self addChild:layer z:1 ]; 
		instrument_name = [NSString alloc];
        /*
         nav_menu = [NavMenu node];
         if (IS_IPAD()) {
         //[nav_menu setPosition:ccp(455*IPAD_MULT, 25*IPAD_MULT)]; 
         [nav_menu setPosition:ccp(1000, 65)];
         } else {
         //[nav_menu setPosition:ccp(455, 25)];
         //[nav_menu setScale:.9];
         [nav_menu setPosition:ccp(465, 50)];
         }
         [self addChild:nav_menu z:50];
         [nav_menu moveToClosedState];
         
         helpMenu = [CCMenu menuWithItems:nil ];
         
         CCMenuItemImage *exitHelpButton = [CCMenuItemImage 
         itemWithNormalImage:@"navMenuExit.png"
         selectedImage:@"navMenuExit.png"
         target:self
         selector:@selector(toggleHelp:)];
         
         [helpMenu addChild:exitHelpButton];
         if (IS_IPAD()) {
         [helpMenu setPosition:ccp(1000, 25)]; 
         } else {
         [helpMenu setPosition:ccp(465, 20)];
         }
         [helpMenu setVisible:false];
         [self addChild:helpMenu z:150];
         
         helpLayer = [CCSprite spriteWithFile:@"AboutLayer.png"];
         [helpLayer setPosition:ccp(SCREEN_CENTER_X, SCREEN_CENTER_Y)];
         [helpLayer setVisible:false];
         [self addChild:helpLayer z:100];
         */
        
    }
    return self;
}

-(void) loadInstrument {
    [layer loadInstrument:instrument_name];
    CCSprite *background = [CCSprite spriteWithFile:[NSString stringWithFormat:@"%@.png",instrument_name]];
    [background setAnchorPoint:ccp(0.0f, 0.0f)];
    [layer addChild:background z:2];
}

-(void) toggleHelp: (id)sender {
    helpMenu.visible = !helpLayer.visible;
    helpLayer.visible = !helpLayer.visible;
    layer.visible = !layer.visible;
    nav_menu.visible = !nav_menu.visible;
}

- (void) dealloc
{	
    //CCLOG(@"Dealloc InstrumentScene");
    [instrument_name release];
    //CCLOG(@"call super");
    //layer = nil;
	[super dealloc];
}

@end

@implementation InstrumentLayer

//@synthesize audioController = _audioController;
//@synthesize fileReference = fileReference_;
@synthesize dispatcher = _dispatcher;


void lookup_tilde_setup(); 
void kink_tilde_setup();

Instrument *instrument_def;
int selectedControl;

-(id) init {
	if( (self=[super init] )) {
        
		// enable touches
        [self setIsTouchEnabled:YES];
        
		// enable accelerometer
        [self setIsAccelerometerEnabled:YES];
        
        touchCount = 0;
        touchList = CFDictionaryCreateMutable(NULL, 0, 
                                              &kCFTypeDictionaryKeyCallBacks, 
                                              &kCFTypeDictionaryValueCallBacks);
        beats = BASEBEATS;
		[self schedule: @selector(tick:) ];
        
	}
	return self;
}

- (void) loadInstrument: (NSString *) name {
	instrument_def = [[Instrument alloc] initWithName:name];
    
	for (int i=0; i<[instrument_def.interactive_inputs count]; i++) {
		Control *c = [instrument_def.interactive_inputs objectAtIndex:i];
		c.position = ccp(c.control_x, c.control_y);
        c.tag = CONTROL_TAG;
		[self addChild:c z:4];
        //[c autorelease];
	}
	//[self openPatch:instrument_def.patch_name];
    
       
    
    //[(RevoicerAppDelegate*)[[UIApplication sharedApplication] delegate] turnOnSound];
    RingLayer = [CCSprite spriteWithFile:@"RevoicerRing.png"];
    if (IS_IPAD()) {
        RingLayer.position = ccp(158*IPAD_MULT-1,160*IPAD_MULT+IPAD_BOT_TRIM-1); 
    } else {
        RingLayer.position = ccp(158,160);
    }
    LEDState = FALSE;
    [self addChild:RingLayer z:1];
    
    RecordButton = [CCSprite spriteWithFile:@"ButtonOff.png"];
    PlayButton= [CCSprite spriteWithFile:@"ButtonOff.png"];
    
    [RecordButton setPosition:ccp(239, 80)];
    [PlayButton setPosition:ccp(239, 239)];
    
    [self addChild:RecordButton z:50];
    [self addChild:PlayButton z:50];
    turnRing=NO;
    RingDirection=0;
}

- (void) draw {
    [super draw];
}

-(void) tick: (ccTime) dt {
    if (turnRing) {
        RingLayer.rotation+=RingDirection;
    }
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint location;
    if (self.visible) {
        CCLOG(@"Touch Began");
        for (UITouch *touch in touches) {
            location = [touch locationInView: [touch view]];
            location  = [[CCDirector sharedDirector] convertToGL:location ];
            bool touchedAlready = FALSE;
            for (int i=0; i<[instrument_def.interactive_inputs count]; i++) {
                Control *c = [instrument_def.interactive_inputs objectAtIndex:i];
                if ([c withinBounds:location] && !touchedAlready) {
                    if ([c.control_id isEqualToString:@"playButton"]) {
                        CCLOG(@"Playing");
                        turnRing = YES;
                        RingDirection =-1;
                        [PdBase sendBangToReceiver:@"normalize"];
                        [PdBase sendBangToReceiver:@"startPlaying"];
                    }
                    if ([c.control_id isEqualToString:@"recordButton"]) {
                        CCLOG(@"Recording");
                        turnRing = YES;
                        RingDirection =1;
                        [PdBase sendBangToReceiver:@"startRecording"];
                    }
                    CFDictionarySetValue(touchList, touch, c);
                    [c showHighlight];
                    //[c sendOnValues];
                    [c touchAdded:touch];
                    //[c updateView:location];
                    //[c sendControlValues]; 
                    touchedAlready = TRUE;
                }
            }   
        }
    }
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint location;
    
    for (UITouch *touch in touches) {
        location = [touch locationInView: [touch view]];
        location  = [[CCDirector sharedDirector] convertToGL:location ];
        Control *c = (Control*)CFDictionaryGetValue(touchList, touch);
        if (c != NULL) {
            if ([c.control_id isEqualToString:@"pot1"]) {
                beats = (1.05-c.control_value)*BASEBEATS;
                //CCLOG(@"beats %@, %4f",c.control_id, beats);
            }
            if ((c.control_type == TOUCH_AREA) || (c.control_type == ROUND_TOUCH_AREA) || 
                (c.control_type == TOGGLE_TOUCH) || (c.control_type == PLASMA_MULTI_TOUCH))  {
                if ([c withinBounds:location]) {
                    [c updateView:location];
                    [c sendControlValues]; 
                }
            } else {
                [c updateView:location];
                if (c.control_sequenced_by == 0) {
                    [c sendControlValues];
                }   
            }
        }
    }
}


- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches) {
        Control *c = (Control*)CFDictionaryGetValue(touchList, touch);
        if (c != NULL) {
            [c touchRemoved:touch];
            if (c.control_type == TOGGLE_TOUCH) {   
                c.control_value = 0;
                [c sendOffValues];
                turnRing=NO;
                RingDirection=0;
                //[PdBase sendFloat:0 toReceiver:[NSString stringWithFormat:@"%@OFF", c.control_id]];
            }
            [c hideHighlight];
            CFDictionaryRemoveValue(touchList, touch);
        }
    }
}

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{
}

- (void) openPatch:(NSString *) patch {  
    // Note: no longer used
    /* //dispatcher = [[PdDispatcher alloc] init]; 
     //[PdBase setDelegate:dispatcher]; 
     //[dispatcher autorelease];
     _audioController = [[PdAudioController alloc] init];
     if ([self.audioController configureAmbientWithSampleRate:44100 
     numberChannels:2 
     mixingEnabled:YES] != PdAudioOK) {
     NSLog(@"failed to initialize audio components");
     }
     lookup_tilde_setup();
     kink_tilde_setup();
     self.audioController.active = YES;
     
     void *ptr = [PdBase openFile:patch
     path:[[NSBundle mainBundle] resourcePath]];
     if (ptr) { 
     self.fileReference = [NSValue valueWithPointer:ptr];
     } else {
     NSLog(@"Failed to open patch!");
     }
     */
}

- (void) closePatch {
    /* CCLOG(@"Closing patch");
     void *ptr = [self.fileReference pointerValue];
     [PdBase closeFile:ptr];
     */
}

-(void) toggleHelp: (id)sender {
}

-(void) record: (id)sender {
    CCLOG(@"Recording");
    [PdBase sendBangToReceiver:@"StartRecording"];
}

-(void) play: (id)sender {
    CCLOG(@"Playing");
    [PdBase sendBangToReceiver:@"normalize"];
    [PdBase sendBangToReceiver:@"StartPlaying"];
}

-(void) nothing:(id)sender {
    //CCLOG(@"Do nothing");
}

- (void) dealloc
{	
    for (int i=0; i<[instrument_def.interactive_inputs count]; i++) {
        [[instrument_def.interactive_inputs objectAtIndex:i] sendOffValues];
		[[instrument_def.interactive_inputs objectAtIndex:i] sendZeroValues];
	}
    [(RevoicerAppDelegate*)[[UIApplication sharedApplication] delegate] turnOffSound];
    [PdBase sendFloat:0.0f toReceiver:@"kit_number"];
    //CCLOG(@"Dealloc InstrumentLayer");
    //[self closePatch];
    //self.fileReference = nil;
    //CCLOG(@"remove all children");
    [self removeAllChildrenWithCleanup:YES];
    //dispatcher =nil;
    //self.audioController = nil;
    //[self.audioController release];
    //CCLOG(@"release touchlist");
    [(id)touchList release];
    //CCLOG(@"release instrument def");
    [instrument_def dealloc];
	// don't forget to call "super dealloc"
    //CCLOG(@"call super");
	[super dealloc];
    
}
@end
