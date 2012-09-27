//
//  HPTextView.m
//
//  Created by Hans Pinckaers on 29-06-10.
//
//	MIT License
//
//	Copyright (c) 2011 Hans Pinckaers
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

#import "HPGrowingTextView.h"
#import "HPTextViewInternal.h"

@interface HPGrowingTextView(private)
-(void)commonInitialiser;
-(void)resizeTextView:(NSInteger)newSizeH;
-(void)growDidStop;
@end

@implementation HPGrowingTextView {
	//class properties
	int _maxNumberOfLines;
	int _minNumberOfLines;
    
    UIEdgeInsets _contentInset;
}


@synthesize internalTextView = _internalTextView;
@synthesize delegate = _delegate;

@synthesize font = _font;
@synthesize textColor = _textColor;
@synthesize textAlignment = _textAlignment; 
@synthesize selectedRange = _selectedRange;
@synthesize editable = _editable;
@synthesize dataDetectorTypes = _dataDetectorTypes; 
@synthesize animateHeightChange = _animateHeightChange;
@synthesize returnKeyType = _returnKeyType;
@synthesize minHeight = _minHeight;
@synthesize maxHeight = _maxHeight;

// having initwithcoder allows us to use HPGrowingTextView in a Nib. -- aob, 9/2011
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        [self commonInitialiser];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self commonInitialiser];
    }
    return self;
}

-(void)commonInitialiser
{
    // Initialization code
    CGRect r = self.frame;
    r.origin.y = 0;
    r.origin.x = 0;
    _internalTextView = [[HPTextViewInternal alloc] initWithFrame:r];
    _internalTextView.delegate = self;
    _internalTextView.scrollEnabled = NO;
    _internalTextView.font = [UIFont fontWithName:@"Helvetica" size:13]; 
    _internalTextView.contentInset = UIEdgeInsetsZero;		
    _internalTextView.showsHorizontalScrollIndicator = NO;
    _internalTextView.text = @"-";
    [self addSubview:_internalTextView];
    
    UIView *internal = (UIView*)[[_internalTextView subviews] objectAtIndex:0];
    _minHeight = internal.frame.size.height;
    _minNumberOfLines = 1;
    
    _animateHeightChange = YES;
    
    _internalTextView.text = @"";
    
    [self setMaxNumberOfLines:3];
}

-(void)sizeToFit
{
	CGRect r = self.frame;
    
    // check if the text is available in text view or not, if it is available, no need to set it to minimum lenth, it could vary as per the text length
    // fix from Ankit Thakur
    if ([self.text length] > 0) {
        return;
    } else {
        r.size.height = _minHeight;
        self.frame = r;
    }
}

-(void)setFrame:(CGRect)aframe
{
	CGRect r = aframe;
	r.origin.y = 0;
	r.origin.x = _contentInset.left;
    r.size.width -= _contentInset.left + _contentInset.right;
    
	_internalTextView.frame = r;
	
	[super setFrame:aframe];
}

-(void)setContentInset:(UIEdgeInsets)inset
{
    _contentInset = inset;
    
    CGRect r = self.frame;
    r.origin.y = inset.top - inset.bottom;
    r.origin.x = inset.left;
    r.size.width -= inset.left + inset.right;
    
    _internalTextView.frame = r;
    
    [self setMaxNumberOfLines:_maxNumberOfLines];
    [self setMinNumberOfLines:_minNumberOfLines];
}

-(UIEdgeInsets)contentInset
{
    return _contentInset;
}

- (void)setMinHeight:(CGFloat)height
{
	_minHeight = height;
	
	[self sizeToFit];
}

- (void)setMaxHeight:(CGFloat)height
{
	_maxHeight = height;
    
    [self sizeToFit];
}

-(void)setMaxNumberOfLines:(int)n
{
    // Use internalTextView for height calculations, thanks to Gwynne <http://blog.darkrainfall.org/>
    NSString *saveText = _internalTextView.text, *newText = @"-";
    
    _internalTextView.delegate = nil;
    _internalTextView.hidden = YES;
    
    for (int i = 1; i < n; ++i)
        newText = [newText stringByAppendingString:@"\n|W|"];
    
    _internalTextView.text = newText;
    
    self.maxHeight = _internalTextView.contentSize.height;
    
    _internalTextView.text = saveText;
    _internalTextView.hidden = NO;
    _internalTextView.delegate = self;
    
    [self sizeToFit];
    
    _maxNumberOfLines = n;
}

-(int)maxNumberOfLines
{
    return _maxNumberOfLines;
}

-(void)setMinNumberOfLines:(int)m
{
	// Use internalTextView for height calculations, thanks to Gwynne <http://blog.darkrainfall.org/>
    NSString *saveText = _internalTextView.text, *newText = @"-";
    
    _internalTextView.delegate = nil;
    _internalTextView.hidden = YES;
    
    for (int i = 1; i < m; ++i)
        newText = [newText stringByAppendingString:@"\n|W|"];
    
    _internalTextView.text = newText;
    
    self.minHeight = _internalTextView.contentSize.height;
    
    _internalTextView.text = saveText;
    _internalTextView.hidden = NO;
    _internalTextView.delegate = self;
    
    [self sizeToFit];
    
    _minNumberOfLines = m;
}

-(int)minNumberOfLines
{
    return _minNumberOfLines;
}


- (void)textViewDidChange:(UITextView *)textView
{	
	//size of content, so we can set the frame of self
	NSInteger newSizeH = _internalTextView.contentSize.height;
	if(newSizeH < _minHeight || !_internalTextView.hasText) newSizeH = _minHeight; //not smalles than minHeight
    
	if (_internalTextView.frame.size.height != newSizeH)
	{
        // [fixed] Pasting too much text into the view failed to fire the height change, 
        // thanks to Gwynne <http://blog.darkrainfall.org/>
        
        if (newSizeH > _maxHeight && _internalTextView.frame.size.height <= _maxHeight) {
            newSizeH = _maxHeight;
        }
        
		if (newSizeH <= _maxHeight) {
            if(_animateHeightChange) {
                
                if ([UIView resolveClassMethod:@selector(animateWithDuration:animations:)]) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
                    [UIView animateWithDuration:0.1f 
                                          delay:0 
                                        options:(UIViewAnimationOptionAllowUserInteraction|
                                                 UIViewAnimationOptionBeginFromCurrentState)                                 
                                     animations:^(void) {
                                         [self resizeTextView:newSizeH];
                                     } completion:nil];
#endif
                } else {
                    [UIView beginAnimations:@"" context:nil];
                    [UIView setAnimationDuration:0.1f];
                    [UIView setAnimationDelegate:self];
                    [UIView setAnimationDidStopSelector:@selector(growDidStop)];
                    [UIView setAnimationBeginsFromCurrentState:YES];
                    [self resizeTextView:newSizeH];
                    [UIView commitAnimations];
                }
            } else {
                [self resizeTextView:newSizeH];
            }
		}
		
        
        // if our new height is greater than the maxHeight
        // sets not set the height or move things
        // around and enable scrolling
		if (newSizeH >= _maxHeight)
		{
			if(!_internalTextView.scrollEnabled){
				_internalTextView.scrollEnabled = YES;
				[_internalTextView flashScrollIndicators];
			}
			
		} else {
			_internalTextView.scrollEnabled = NO;
		}
		
	}
	
	
	if ([_delegate respondsToSelector:@selector(growingTextViewDidChange:)]) {
		[_delegate growingTextViewDidChange:self];
	}
	
}

-(void)resizeTextView:(NSInteger)newSizeH
{
    if ([_delegate respondsToSelector:@selector(growingTextView:willChangeHeight:)]) {
        [_delegate growingTextView:self willChangeHeight:newSizeH];
    }
    
    CGRect internalTextViewFrame = self.frame;
    internalTextViewFrame.size.height = newSizeH; // + padding
    self.frame = internalTextViewFrame;
    
    internalTextViewFrame.origin.y = _contentInset.top - _contentInset.bottom;
    internalTextViewFrame.origin.x = _contentInset.left;
    internalTextViewFrame.size.width = _internalTextView.contentSize.width;
    
    _internalTextView.frame = internalTextViewFrame;
	
	if ([_delegate respondsToSelector:@selector(growingTextView:didChangeHeight:)]) {
		[_delegate growingTextView:self didChangeHeight:newSizeH];
	}
}

-(void)growDidStop
{
	if ([_delegate respondsToSelector:@selector(growingTextView:didChangeHeight:)]) {
		[_delegate growingTextView:self didChangeHeight:self.frame.size.height];
	}
	
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [_internalTextView becomeFirstResponder];
}

- (BOOL)becomeFirstResponder
{
    [super becomeFirstResponder];
    return [self.internalTextView becomeFirstResponder];
}

-(BOOL)resignFirstResponder
{
	[super resignFirstResponder];
	return [_internalTextView resignFirstResponder];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITextView properties
///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setText:(NSString *)newText
{
    _internalTextView.text = newText;
    
    // include this line to analyze the height of the textview.
    // fix from Ankit Thakur
    [self performSelector:@selector(textViewDidChange:) withObject:_internalTextView];
}

-(NSString*) text
{
    return _internalTextView.text;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setFont:(UIFont *)afont
{
	_internalTextView.font= afont;
	
	[self setMaxNumberOfLines:_maxNumberOfLines];
	[self setMinNumberOfLines:_minNumberOfLines];
}

-(UIFont *)font
{
	return _internalTextView.font;
}	

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setTextColor:(UIColor *)color
{
	_internalTextView.textColor = color;
}

-(UIColor*)textColor{
	return _internalTextView.textColor;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setTextAlignment:(UITextAlignment)aligment
{
	_internalTextView.textAlignment = aligment;
}

-(UITextAlignment)textAlignment
{
	return _internalTextView.textAlignment;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setSelectedRange:(NSRange)range
{
	_internalTextView.selectedRange = range;
}

-(NSRange)selectedRange
{
	return _internalTextView.selectedRange;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setEditable:(BOOL)beditable
{
	_internalTextView.editable = beditable;
}

-(BOOL)isEditable
{
	return _internalTextView.editable;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setReturnKeyType:(UIReturnKeyType)keyType
{
	_internalTextView.returnKeyType = keyType;
}

-(UIReturnKeyType)returnKeyType
{
	return _internalTextView.returnKeyType;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setDataDetectorTypes:(UIDataDetectorTypes)datadetector
{
	_internalTextView.dataDetectorTypes = datadetector;
}

-(UIDataDetectorTypes)dataDetectorTypes
{
	return _internalTextView.dataDetectorTypes;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)hasText{
	return [_internalTextView hasText];
}

- (void)scrollRangeToVisible:(NSRange)range
{
	[_internalTextView scrollRangeToVisible:range];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UITextViewDelegate


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
	if ([_delegate respondsToSelector:@selector(growingTextViewShouldBeginEditing:)]) {
		return [_delegate growingTextViewShouldBeginEditing:self];
		
	} else {
		return YES;
	}
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
	if ([_delegate respondsToSelector:@selector(growingTextViewShouldEndEditing:)]) {
		return [_delegate growingTextViewShouldEndEditing:self];
		
	} else {
		return YES;
	}
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)textViewDidBeginEditing:(UITextView *)textView {
	if ([_delegate respondsToSelector:@selector(growingTextViewDidBeginEditing:)]) {
		[_delegate growingTextViewDidBeginEditing:self];
	}
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)textViewDidEndEditing:(UITextView *)textView {		
	if ([_delegate respondsToSelector:@selector(growingTextViewDidEndEditing:)]) {
		[_delegate growingTextViewDidEndEditing:self];
	}
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)atext {
    BOOL delegateAnswer;
    if ([_delegate respondsToSelector:@selector(growingTextView:shouldChangeTextInRange:replacementText:)]) {
        delegateAnswer = [_delegate growingTextView:self shouldChangeTextInRange:range replacementText:atext];
    }
    
	//weird 1 pixel bug when clicking backspace when textView is empty
	if(![textView hasText] && [atext isEqualToString:@""]) return NO;
	
	if ([atext isEqualToString:@"\n"]) {
		if ([_delegate respondsToSelector:@selector(growingTextViewShouldReturn:)]) {
			return (BOOL)[_delegate performSelector:@selector(growingTextViewShouldReturn:) withObject:self];
		}
	}
	
	return delegateAnswer;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)textViewDidChangeSelection:(UITextView *)textView {
	if ([_delegate respondsToSelector:@selector(growingTextViewDidChangeSelection:)]) {
		[_delegate growingTextViewDidChangeSelection:self];
	}
}



@end
