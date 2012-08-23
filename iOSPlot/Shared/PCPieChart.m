/**
 * Copyright (c) 2011 Muh Hon Cheng
 * Created by honcheng on 28/4/11.
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject
 * to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
 * WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR
 * PURPOSE AND NONINFRINGEMENT. IN NO EVENT
 * SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 * IN CONNECTION WITH THE SOFTWARE OR
 * THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * @author 		Muh Hon Cheng <honcheng@gmail.com>
 * @copyright	2011	Muh Hon Cheng
 * @version
 *
 */

#import "PCPieChart.h"
#import "FPPopoverController.h"

#import "PieChartPopover.h"

#define AngleGrad360(angle) (remainderf(angle,360.f) < 0)? remainderf(angle,360.f)+360 : remainderf(angle,360.f)

@interface PCPieComponent()

@property float startDeg, endDeg;

@end

@implementation PCPieComponent

- (id)initWithTitle:(NSString*)title value:(float)value
{
    self = [super init];
    if (self)
    {
        _title = title;
        _value = value;
        _colour = PCColorDefault;
    }
    return self;
}

+ (id)pieComponentWithTitle:(NSString*)title value:(float)value
{
    return [[super alloc] initWithTitle:title value:value];
}

- (NSString*)description
{
    NSMutableString *text = [NSMutableString string];
    [text appendFormat:@"title: %@\n", self.title];
    [text appendFormat:@"value: %f\n", self.value];
    return text;
}

@end

@interface PCPieChart() <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UITapGestureRecognizer  *tapGesture;

@property (nonatomic, unsafe_unretained) CGPoint originCircle;
@property (nonatomic, unsafe_unretained) CGPoint centerCircle;
@property (nonatomic, strong) UIView  *viewCircle;
@property (nonatomic, unsafe_unretained) float deltaRotation;
@property (nonatomic, unsafe_unretained) int diameterInnerCircle;
@property (nonatomic, strong) UIFont *titleFontInnerCircle;
@property (nonatomic, unsafe_unretained) CGFloat detailsAlpha;

- (void)drawCicleBackground;
- (void)drawInnerCircle;
- (void)drawChartPortions;
- (void)drawPercentValues;
- (void)drawPercentValuesOnChart;

+ (NSArray*) sortComponents: (NSArray*)components;

-(void)TapByUser:(id)sender;
-(void)addDeltaAngleTillCenter: (id)obj;

@end

@implementation PCPieChart

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setBackgroundColor:[UIColor clearColor]];
		
        _detailsAlpha = 1.f;
		_titleFont = [UIFont boldSystemFontOfSize:10];
		_percentageFont = [UIFont boldSystemFontOfSize:20];
		_showArrow = YES;
		_sameColorLabel = NO;
        
        _tapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(TapByUser:)];
        _tapGesture.delegate=self;
        _tapGesture.numberOfTapsRequired=1;
        [self addGestureRecognizer:_tapGesture];
        
        self.deltaRotation = 0;
        
	}
    return self;
}

- (void)setDeltaRotation:(float)deltaRotation
{
    _deltaRotation = AngleGrad360(deltaRotation);
}

- (void)setComponents:(NSMutableArray *)components
{
    if (_components) {
        _components = nil;
    }
    _components = components;
    float total = 0;
    for (PCPieComponent *component in self.components)
        total += component.value;
    
    float nextStartDeg = _deltaRotation;
    float endDeg = 0;
    for (PCPieComponent *component in _components) {
        float perc = [component value]/total;
        endDeg = nextStartDeg+perc*360;
        
        [component setStartDeg:nextStartDeg];
        [component setEndDeg:endDeg];
        nextStartDeg = endDeg;
    }
}

- (void)setShowArrow:(BOOL)showArrow
{
    _showArrow = showArrow;
    if (_showArrow) {
        _showValuesInChart = NO;
    }
}

- (void)setShowValuesInChart:(BOOL)showValuesInChart
{
    _showValuesInChart = showValuesInChart;
    if (_showValuesInChart) {
        _showArrow = NO;
    }
}

#define MARGIN 15
#define ARROW_HEAD_LENGTH 6
#define ARROW_HEAD_WIDTH 4

#pragma mark draw methods
- (void)drawCicleBackground
{
    return;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(ctx);
    CGContextSetRGBFillColor(ctx, 1.0f, 1.0f, 1.0f, 1.0f);  // white color
    CGContextSetShadow(ctx, CGSizeMake(0.0f, 0.0f), 15);
    // a white filled circle with a diameter of 100 pixels, centered in (60, 60)
    CGContextFillEllipseInRect(ctx, CGRectMake(_centerCircle.x, _centerCircle.y, self.diameter, self.diameter));
    UIGraphicsPopContext();
    CGContextSetShadow(ctx, CGSizeMake(0.0f, 0.0f), 0);
}

- (void)drawInnerCircle
{
    float x_innerCircle = _centerCircle.x - _diameterInnerCircle * 0.5f;
    float y_innerCircle = _centerCircle.y - _diameterInnerCircle * 0.5f;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(ctx);
    CGContextSetFillColorWithColor(ctx, [PCColorInnerCircle CGColor]);
    CGContextSetShadow(ctx, CGSizeMake(0.3f, 0.2f), MARGIN);
    CGContextFillEllipseInRect(ctx,
                               CGRectMake(x_innerCircle,
                                          y_innerCircle,
                                          _diameterInnerCircle,
                                          _diameterInnerCircle));
    UIGraphicsPopContext();
    
    if (_titleInnerCircle) {
        float width = cosf(25) * _diameterInnerCircle;
        if (width < 8)
            width = 8;
        float height = fabsf(sinf(25) * _diameterInnerCircle);
        int fontSize = height;
        _titleFontInnerCircle = [UIFont boldSystemFontOfSize:fontSize];
        
        CGFloat text_x = x_innerCircle + (_diameterInnerCircle - width) * 0.5f;
        CGFloat text_y = y_innerCircle + (_diameterInnerCircle - height) * 0.5f;
        
        
        CGRect titleFrame = CGRectMake(text_x, text_y, width, height);
        
        UIGraphicsPushContext(ctx);
        CGFloat color[4];
        [PCColorTextInnerCircle getRed:color green:color+1 blue:color+2 alpha:color+3];
        color[3] = _detailsAlpha;
        //CGContextSetFillColorWithColor(ctx, [PCColorTextInnerCircle CGColor]);
        CGContextSetFillColor(ctx, color);
        [_titleInnerCircle drawInRect:titleFrame
                             withFont:_titleFontInnerCircle
                        lineBreakMode:UILineBreakModeWordWrap
                            alignment:UITextAlignmentCenter];
        UIGraphicsPopContext();
    }
}

- (void)drawChartPortions
{
    float radius = self.diameter * 0.5f;
    float gap = 1;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    for (PCPieComponent *component in _components)
    {
        CGContextSetFillColorWithColor(ctx, [component.colour CGColor]);
        CGContextMoveToPoint(ctx, _centerCircle.x, _centerCircle.y);
        CGContextAddArc(ctx, _centerCircle.x, _centerCircle.y, radius,
                        (component.startDeg-90)*M_PI/180.0, (component.endDeg-90)*M_PI/180.0, 0);
        CGContextClosePath(ctx);
        CGContextFillPath(ctx);
        
        CGContextSetRGBStrokeColor(ctx, 1, 1, 1, 1);
        CGContextSetLineWidth(ctx, gap);
        CGContextMoveToPoint(ctx, _centerCircle.x, _centerCircle.y);
        CGContextAddArc(ctx, _centerCircle.x, _centerCircle.y, radius,
                        (component.startDeg-90)*M_PI/180.0, (component.endDeg-90)*M_PI/180.0, 0);
        CGContextClosePath(ctx);
        CGContextStrokePath(ctx);
    }
}

- (void)drawPercentValues
{
    float radius = self.diameter * 0.5f;
    float left_label_y = MARGIN;
    float right_label_y = MARGIN;
    float max_text_width = _originCircle.x -  10;
    float total = 0;
    for (PCPieComponent *component in self.components)
        total += component.value;
    NSArray *sortedArray = [PCPieChart sortComponents:_components];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    for (PCPieComponent *component in sortedArray)
    {
        CGFloat nextStartDeg = component.startDeg + _deltaRotation;
        CGFloat endDeg = component.endDeg + _deltaRotation;
        
        
        if (nextStartDeg > 180 ||  (nextStartDeg < 180 && endDeg> 270) )
        {
            // left
            
            // display percentage label
            if (self.sameColorLabel)
            {
                CGContextSetFillColorWithColor(ctx, [component.colour CGColor]);
            }
            else
            {
                CGContextSetRGBFillColor(ctx, 0.1f, 0.1f, 0.1f, 1.0f);
            }
            CGContextSetShadow(ctx, CGSizeMake(0.0f, 0.0f), 3);
            
            //float text_x = x + 10;
            NSString *percentageText = [NSString stringWithFormat:@"%.1f%%", component.value/total*100];
            CGSize optimumSize = [percentageText sizeWithFont:self.percentageFont constrainedToSize:CGSizeMake(max_text_width,100)];
            CGRect percFrame = CGRectMake(5, left_label_y,  max_text_width, optimumSize.height);
            
            if (self.hasOutline) {
                CGContextSaveGState(ctx);
                
                CGContextSetLineWidth(ctx, 1.0f);
                CGContextSetLineJoin(ctx, kCGLineJoinRound);
                CGContextSetTextDrawingMode (ctx, kCGTextFillStroke);
                CGContextSetRGBStrokeColor(ctx, 0.2f, 0.2f, 0.2f, 0.8f);
                
                [percentageText drawInRect:percFrame withFont:self.percentageFont lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentRight];
                
                CGContextRestoreGState(ctx);
            } else {
                [percentageText drawInRect:percFrame withFont:self.percentageFont lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentRight];
            }
            
            if (self.showArrow)
            {
                // draw line to point to chart
                CGContextSetRGBStrokeColor(ctx, 0.2f, 0.2f, 0.2f, 1);
                CGContextSetRGBFillColor(ctx, 0.0f, 0.0f, 0.0f, 1.0f);
                
                int x1 = radius/4*3*cos((nextStartDeg+component.value/total*360/2-90)*M_PI/180.0)+_centerCircle.x;
                int y1 = radius/4*3*sin((nextStartDeg+component.value/total*360/2-90)*M_PI/180.0)+_centerCircle.y;
                CGContextSetLineWidth(ctx, 1);
                if (left_label_y + optimumSize.height/2 < _originCircle.y)//(left_label_y==LABEL_TOP_MARGIN)
                {
                    
                    CGContextMoveToPoint(ctx, 5 + max_text_width, left_label_y + optimumSize.height/2);
                    CGContextAddLineToPoint(ctx, x1, left_label_y + optimumSize.height/2);
                    CGContextAddLineToPoint(ctx, x1, y1);
                    CGContextStrokePath(ctx);
                    
                    CGContextMoveToPoint(ctx, x1-ARROW_HEAD_WIDTH/2, y1);
                    CGContextAddLineToPoint(ctx, x1, y1+ARROW_HEAD_LENGTH);
                    CGContextAddLineToPoint(ctx, x1+ARROW_HEAD_WIDTH/2, y1);
                    CGContextClosePath(ctx);
                    CGContextFillPath(ctx);
                    
                }
                else
                {
                    
                    CGContextMoveToPoint(ctx, 5 + max_text_width, left_label_y + optimumSize.height/2);
                    if (left_label_y + optimumSize.height/2 > _originCircle.y + self.diameter)
                    {
                        CGContextAddLineToPoint(ctx, x1, left_label_y + optimumSize.height/2);
                        CGContextAddLineToPoint(ctx, x1, y1);
                        CGContextStrokePath(ctx);
                        
                        CGContextMoveToPoint(ctx, x1-ARROW_HEAD_WIDTH/2, y1);
                        CGContextAddLineToPoint(ctx, x1, y1-ARROW_HEAD_LENGTH);
                        CGContextAddLineToPoint(ctx, x1+ARROW_HEAD_WIDTH/2, y1);
                        CGContextClosePath(ctx);
                        CGContextFillPath(ctx);
                    }
                    else
                    {
                        float y_diff = y1 - (left_label_y + optimumSize.height/2);
                        if ( (y_diff < 2*ARROW_HEAD_LENGTH && y_diff>0) || (-1*y_diff < 2*ARROW_HEAD_LENGTH && y_diff<0))
                        {
                            
                            // straight arrow
                            y1 = left_label_y + optimumSize.height/2;
                            
                            CGContextAddLineToPoint(ctx, x1, y1);
                            CGContextStrokePath(ctx);
                            
                            CGContextMoveToPoint(ctx, x1, y1-ARROW_HEAD_WIDTH/2);
                            CGContextAddLineToPoint(ctx, x1+ARROW_HEAD_LENGTH, y1);
                            CGContextAddLineToPoint(ctx, x1, y1+ARROW_HEAD_WIDTH/2);
                            CGContextClosePath(ctx);
                            CGContextFillPath(ctx);
                        }
                        else if (left_label_y + optimumSize.height/2<y1)
                        {
                            // arrow point down
                            
                            y1 -= ARROW_HEAD_LENGTH;
                            CGContextAddLineToPoint(ctx, x1, left_label_y + optimumSize.height/2);
                            CGContextAddLineToPoint(ctx, x1, y1);
                            CGContextStrokePath(ctx);
                            
                            CGContextMoveToPoint(ctx, x1-ARROW_HEAD_WIDTH/2, y1);
                            CGContextAddLineToPoint(ctx, x1, y1+ARROW_HEAD_LENGTH);
                            CGContextAddLineToPoint(ctx, x1+ARROW_HEAD_WIDTH/2, y1);
                            CGContextClosePath(ctx);
                            CGContextFillPath(ctx);
                        }
                        else
                        {
                            // arrow point up
                            
                            y1 += ARROW_HEAD_LENGTH;
                            CGContextAddLineToPoint(ctx, x1, left_label_y + optimumSize.height/2);
                            CGContextAddLineToPoint(ctx, x1, y1);
                            CGContextStrokePath(ctx);
                            
                            CGContextMoveToPoint(ctx, x1-ARROW_HEAD_WIDTH/2, y1);
                            CGContextAddLineToPoint(ctx, x1, y1-ARROW_HEAD_LENGTH);
                            CGContextAddLineToPoint(ctx, x1+ARROW_HEAD_WIDTH/2, y1);
                            CGContextClosePath(ctx);
                            CGContextFillPath(ctx);
                        }
                    }
                }
                
            }
            // display title on the left
            CGContextSetRGBFillColor(ctx, 0.4f, 0.4f, 0.4f, 1.0f);
            left_label_y += optimumSize.height - 4;
            optimumSize = [component.title sizeWithFont:self.titleFont constrainedToSize:CGSizeMake(max_text_width,100)];
            CGRect titleFrame = CGRectMake(5, left_label_y, max_text_width, optimumSize.height);
            if (_showValuesInChart == NO) {
                [component.title drawInRect:titleFrame withFont:self.titleFont lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentRight];
            }
            left_label_y += optimumSize.height + 10;
        }
        else
        {
            // right
            
            // display percentage label
            if (self.sameColorLabel)
                CGContextSetFillColorWithColor(ctx, [component.colour CGColor]);
            else
                CGContextSetRGBFillColor(ctx, 0.1f, 0.1f, 0.1f, 1.0f);
            CGContextSetShadow(ctx, CGSizeMake(0.0f, 0.0f), 2);
            
            float text_x = _originCircle.x + self.diameter + 10;
            NSString *percentageText = [NSString stringWithFormat:@"%.1f%%", component.value/total*100];
            CGSize optimumSize = [percentageText sizeWithFont:self.percentageFont constrainedToSize:CGSizeMake(max_text_width,100)];
            CGRect percFrame = CGRectMake(text_x, right_label_y, optimumSize.width, optimumSize.height);
            
            if (self.hasOutline) {
                CGContextSaveGState(ctx);
                
                CGContextSetLineWidth(ctx, 1.0f);
                CGContextSetLineJoin(ctx, kCGLineJoinRound);
                CGContextSetTextDrawingMode (ctx, kCGTextFillStroke);
                CGContextSetRGBStrokeColor(ctx, 0.2f, 0.2f, 0.2f, 0.8f);
                
                [percentageText drawInRect:percFrame withFont:self.percentageFont];
                
                CGContextRestoreGState(ctx);
            } else {
                [percentageText drawInRect:percFrame withFont:self.percentageFont];
            }
            
            if (self.showArrow)
            {
                // draw line to point to chart
                CGContextSetRGBStrokeColor(ctx, 0.2f, 0.2f, 0.2f, 1);
                CGContextSetRGBFillColor(ctx, 0.0f, 0.0f, 0.0f, 1.0f);
                
                CGContextSetLineWidth(ctx, 1);
                int x1 = radius/4*3*cos((nextStartDeg+component.value/total*360/2-90)*M_PI/180.0)+_centerCircle.x;
                int y1 = radius/4*3*sin((nextStartDeg+component.value/total*360/2-90)*M_PI/180.0)+_centerCircle.y;
                
                
                if (right_label_y + optimumSize.height/2 < _originCircle.y)//(right_label_y==LABEL_TOP_MARGIN)
                {
                    
                    CGContextMoveToPoint(ctx, text_x - 3, right_label_y + optimumSize.height/2);
                    CGContextAddLineToPoint(ctx, x1, right_label_y + optimumSize.height/2);
                    CGContextAddLineToPoint(ctx, x1, y1);
                    CGContextStrokePath(ctx);
                    
                    CGContextMoveToPoint(ctx, x1-ARROW_HEAD_WIDTH/2, y1);
                    CGContextAddLineToPoint(ctx, x1, y1+ARROW_HEAD_LENGTH);
                    CGContextAddLineToPoint(ctx, x1+ARROW_HEAD_WIDTH/2, y1);
                    CGContextClosePath(ctx);
                    CGContextFillPath(ctx);
                }
                else
                {
                    float y_diff = y1 - (right_label_y + optimumSize.height/2);
                    if ( (y_diff < 2*ARROW_HEAD_LENGTH && y_diff>0) || (-1*y_diff < 2*ARROW_HEAD_LENGTH && y_diff<0))
                    {
                        // straight arrow
                        y1 = right_label_y + optimumSize.height/2;
                        
                        CGContextMoveToPoint(ctx, text_x, right_label_y + optimumSize.height/2);
                        CGContextAddLineToPoint(ctx, x1, y1);
                        CGContextStrokePath(ctx);
                        
                        CGContextMoveToPoint(ctx, x1, y1-ARROW_HEAD_WIDTH/2);
                        CGContextAddLineToPoint(ctx, x1-ARROW_HEAD_LENGTH, y1);
                        CGContextAddLineToPoint(ctx, x1, y1+ARROW_HEAD_WIDTH/2);
                        CGContextClosePath(ctx);
                        CGContextFillPath(ctx);
                    }
                    else if (right_label_y + optimumSize.height/2<y1)
                    {
                        // arrow point down
                        
                        y1 -= ARROW_HEAD_LENGTH;
                        
                        CGContextMoveToPoint(ctx, text_x, right_label_y + optimumSize.height/2);
                        CGContextAddLineToPoint(ctx, x1, right_label_y + optimumSize.height/2);
                        //CGContextAddLineToPoint(ctx, x1+5, y1);
                        CGContextAddLineToPoint(ctx, x1, y1);
                        CGContextStrokePath(ctx);
                        
                        CGContextMoveToPoint(ctx, x1+ARROW_HEAD_WIDTH/2, y1);
                        CGContextAddLineToPoint(ctx, x1, y1+ARROW_HEAD_LENGTH);
                        CGContextAddLineToPoint(ctx, x1-ARROW_HEAD_WIDTH/2, y1);
                        CGContextClosePath(ctx);
                        CGContextFillPath(ctx);
                    }
                    else //if (nextStartDeg<180 && endDeg>180)
                    {
                        // arrow point up
                        y1 += ARROW_HEAD_LENGTH;
                        
                        CGContextMoveToPoint(ctx, text_x, right_label_y + optimumSize.height/2);
                        CGContextAddLineToPoint(ctx, x1, right_label_y + optimumSize.height/2);
                        CGContextAddLineToPoint(ctx, x1, y1);
                        CGContextStrokePath(ctx);
                        
                        CGContextMoveToPoint(ctx, x1+ARROW_HEAD_WIDTH/2, y1);
                        CGContextAddLineToPoint(ctx, x1, y1-ARROW_HEAD_LENGTH);
                        CGContextAddLineToPoint(ctx, x1-ARROW_HEAD_WIDTH/2, y1);
                        CGContextClosePath(ctx);
                        CGContextFillPath(ctx);
                    }
                }
            }
            
            // display title on the left
            CGContextSetRGBFillColor(ctx, 0.4f, 0.4f, 0.4f, 1.0f);
            right_label_y += optimumSize.height - 4;
            optimumSize = [component.title sizeWithFont:self.titleFont constrainedToSize:CGSizeMake(max_text_width,100)];
            CGRect titleFrame = CGRectMake(text_x, right_label_y, optimumSize.width, optimumSize.height);
            if (_showValuesInChart == NO) {
                [component.title drawInRect:titleFrame withFont:self.titleFont];
            }
            right_label_y += optimumSize.height + 10;
        }
    }
}

- (void)drawPercentValuesOnChart
{
    float nextStartDeg;
    float endDeg = 0;
    float total = 0;
    for (PCPieComponent *component in self.components)
        total += component.value;
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    for (PCPieComponent *component in _components)
    {
        nextStartDeg = component.startDeg + _deltaRotation;
        endDeg = component.endDeg + _deltaRotation;
        
        float angle_rad = (-nextStartDeg - endDeg + 180)*0.5f / 180.f * M_PI;
        float origin_x_label =  cosf(angle_rad) * _diameter * 0.5f * 0.75f;
        float origin_y_label =  - sinf(angle_rad) * _diameter * 0.5f * 0.75f;
        
        CGContextSetShadow(ctx, CGSizeMake(1.f, 1.0f), .6f);
        CGContextSetRGBFillColor(ctx, 0.4f, 0.4f, 0.4f, _detailsAlpha);
        
        //float text_x = x + 10;
        NSString *percentageText = [NSString stringWithFormat:@"%.1f%%", component.value/total*100];
        CGSize optimumSize = [percentageText sizeWithFont:self.titleFont];
        CGRect percFrame = CGRectMake(_centerCircle.x+origin_x_label - optimumSize.width * 0.5f,
                                      _centerCircle.y+origin_y_label - optimumSize.height * 0.5f,
                                      optimumSize.width,
                                      optimumSize.height);
        [percentageText drawInRect:percFrame withFont:self.titleFont lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentRight];
    }
}

- (void)drawRect:(CGRect)rect
{
    if (self.diameter==0)
    {
        self.diameter = MIN(rect.size.width, rect.size.height) - 2 * MARGIN;
    }
    _diameterInnerCircle = _diameter / 3.f;
    _originCircle = CGPointMake((rect.size.width - self.diameter) * 0.5f,
                                (rect.size.height - self.diameter) * 0.5f);
    _centerCircle = CGPointMake(rect.size.width*0.5f, rect.size.height*0.5f);
    
    if ([self.components count]>0)
    {
        [self drawCicleBackground];

		[self drawChartPortions];
        
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(ctx, _centerCircle.x, _centerCircle.y);
        CGContextRotateCTM(ctx, -_deltaRotation / 180.f * M_PI );
        CGContextTranslateCTM(ctx, -_centerCircle.x, -_centerCircle.y);
        
        if (_showValuesInChart)
            [self drawPercentValuesOnChart];
        else
            [self drawPercentValues];
        if (_showInnerCircle)
            [self drawInnerCircle];
    }
}

+ (NSArray*) sortComponents: (NSArray*)components
{
    NSArray *sortedArray = [components sortedArrayUsingComparator: ^(id obj1, id obj2) {
        PCPieComponent *component1 = obj1;
        PCPieComponent *component2 = obj2;
        if (component1.startDeg < 180) {
            if (component1.startDeg < component2.startDeg)
                return (NSComparisonResult)NSOrderedAscending;
            else
                return (NSComparisonResult)NSOrderedDescending;
        }
        if (component1.startDeg > component2.startDeg)
            return (NSComparisonResult)NSOrderedAscending;
        else
            return (NSComparisonResult)NSOrderedDescending;
    }];
    
    return sortedArray;
}
#pragma mark actions
-(void)TapByUser:(id)sender
{
    //CGRect rect = self.frame;
    //float origin_x = rect.size.width*0.5f;
    //float origin_y = rect.size.height*0.5f;
    
    //Find by what angle it has to rotate
    CGPoint touchPointOnSelf=[(UITapGestureRecognizer *)sender locationInView:self];
    if (_showInnerCircle &&
        powf(touchPointOnSelf.x-_centerCircle.x, 2.f) + powf(touchPointOnSelf.y-_centerCircle.y,2.f) <= powf(_diameterInnerCircle*0.5f,2.f)) {
        NSLog(@"Touch inside Inner Circle");
        return;
    }
    if (powf(touchPointOnSelf.x-_centerCircle.x, 2.f) + powf(touchPointOnSelf.y-_centerCircle.y,2.f) > powf(_diameter*0.5f,2.f)){
        NSLog(@"Touch outside");
        return;
    }
    NSLog(@"Touch inside");
    
    float angle=atan2f((touchPointOnSelf.y - _centerCircle.y), (touchPointOnSelf.x -  _centerCircle.x)) * 180.f / M_PI;
    angle = AngleGrad360(angle);
    angle += 90; // Chart alligment.
    angle = AngleGrad360(angle);
    for (PCPieComponent *component in self.components) {
        if (angle > component.startDeg && angle < component.endDeg) {
            if (_touchAnimated) {
                [NSThread detachNewThreadSelector:@selector(redrawTillAlpha:)
                                         toTarget:self
                                       withObject:[NSNumber numberWithFloat:0.f]];

                float targetAngle =  90 - (component.startDeg + component.endDeg) * 0.5f;
                targetAngle = AngleGrad360(targetAngle);
                targetAngle = AngleGrad360(targetAngle-_deltaRotation);
                [UIView animateWithDuration:1.0
                                      delay:0.7
                                    options:UIViewAnimationCurveEaseOut
                                 animations:^(){
                                     CGAffineTransform currentTransform = self.transform;
                                     CGAffineTransform newTransform = CGAffineTransformRotate(currentTransform,targetAngle/180.f*M_PI);
                                     [self setTransform:newTransform];
                                 }
                                 completion:^(BOOL finished){
                                     _deltaRotation = AngleGrad360(targetAngle + _deltaRotation);
                                     [NSThread detachNewThreadSelector:@selector(redrawTillAlpha:)
                                                              toTarget:self
                                                            withObject:[NSNumber numberWithFloat:1.f]];
                                 }];
            }
            else {
                if (component.delegate) {
                    UIViewController *viewController = [component.delegate ViewController:component];
                    FPPopoverController *popoverController = [[FPPopoverController alloc] initWithViewController:viewController];
                    CGPoint point = CGPointMake(self.frame.origin.x + touchPointOnSelf.x, self.frame.origin.y + touchPointOnSelf.y);
                    CGRect frame = CGRectMake(point.x-self.frame.origin.x, point.y-self.frame.origin.y, 1, 1);
                    UIView *view = [[UIView alloc] initWithFrame:frame];
                    [self addSubview:view];
                    [popoverController presentPopoverFromView:view];
                    [view removeFromSuperview];
                }
            }
            break;
        }
    }
    
}

-(void)popovermethod: (PCPieComponent*)component
{
    
    UIViewController *viewController = [component.delegate ViewController:component];
    FPPopoverController *popoverController = [[FPPopoverController alloc] initWithViewController:viewController];
    CGPoint point = CGPointMake(self.frame.size.width * 0.5f + self.diameter * 0.5f,
                                self.frame.size.height * 0.5f);
    CGRect frame = CGRectMake(point.x, point.y, 1, 1);
    UIView *view = [[UIView alloc] initWithFrame:frame];
    [self addSubview:view];
    [popoverController presentPopoverFromView:view];
    [view removeFromSuperview];
}

-(void)redrawTillAlpha: (NSNumber*)alphaNumber
{
    [NSThread sleepForTimeInterval:0.07f]; //minimun delay for iPad
    CGFloat alpha = alphaNumber.floatValue;
    if (_detailsAlpha != alpha) {
        if (_detailsAlpha < alpha) {
            _detailsAlpha += 0.107;
            if (_detailsAlpha > alpha)
                _detailsAlpha = alpha;
        }
        if (_detailsAlpha > alpha) {
            _detailsAlpha -= 0.107;
            if (_detailsAlpha < alpha)
                _detailsAlpha = alpha;
        }
        [NSThread detachNewThreadSelector:@selector(redrawTillAlpha:)
                                 toTarget:self
                               withObject:alphaNumber];
    }
    [self setNeedsDisplay];
}

-(void)addDeltaAngleTillCenter: (id)obj
{
    [NSThread sleepForTimeInterval:0.07f]; //minimun delay for iPad
    PCPieComponent *component = obj;
    float targetAngle = 360 - (component.startDeg + component.endDeg) * 0.5f + 90;
    targetAngle = AngleGrad360(targetAngle);
    if (ceilf(_deltaRotation) == ceilf(targetAngle)) {
        if (component.delegate)
            [self performSelectorOnMainThread:@selector(popovermethod:)
                                   withObject:component waitUntilDone:NO];
        return;
    }
    self.deltaRotation = _deltaRotation + 1;
    [self setNeedsDisplay];

    [NSThread detachNewThreadSelector:@selector(addDeltaAngleTillCenter:)
                             toTarget:self
                           withObject:component];
    
}

@end
