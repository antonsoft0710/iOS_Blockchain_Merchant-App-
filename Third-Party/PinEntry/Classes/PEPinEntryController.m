/********************************************************************************
*                                                                               *
* Copyright (c) 2010 Vladimir "Farcaller" Pouzanov <farcaller@gmail.com>        *
*                                                                               *
* Permission is hereby granted, free of charge, to any person obtaining a copy  *
* of this software and associated documentation files (the "Software"), to deal *
* in the Software without restriction, including without limitation the rights  *
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell     *
* copies of the Software, and to permit persons to whom the Software is         *
* furnished to do so, subject to the following conditions:                      *
*                                                                               *
* The above copyright notice and this permission notice shall be included in    *
* all copies or substantial portions of the Software.                           *
*                                                                               *
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    *
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,      *
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE   *
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER        *
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, *
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN     *
* THE SOFTWARE.                                                                 *
*                                                                               *
********************************************************************************/

#import "PEPinEntryController.h"

#define PS_VERIFY	0
#define PS_ENTER1	1
#define PS_ENTER2	2

static PEViewController *EnterController()
{
	PEViewController *c = [[PEViewController alloc] init];
	c.prompt = BC_STRING_PLEASE_ENTER_PIN;
	c.title = @"";
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
    NSString *version = infoDictionary[@"CFBundleShortVersionString"];
    c.versionLabel.text = [NSString stringWithFormat:@"v%@", version];
    
	return c;
}

static PEViewController *NewController()
{
	PEViewController *c = [[PEViewController alloc] init];
	c.prompt = BC_STRING_PLEASE_ENTER_NEW_PIN;
	c.title = @"";

    NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
    NSString *version = infoDictionary[@"CFBundleShortVersionString"];
    c.versionLabel.text = [NSString stringWithFormat:@"v%@", version];

    return c;
}

static PEViewController *VerifyController()
{
	PEViewController *c = [[PEViewController alloc] init];
	c.prompt = BC_STRING_CONFIRM_PIN;
	c.title = @"";

    NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
    NSString *version = infoDictionary[@"CFBundleShortVersionString"];
    c.versionLabel.text = [NSString stringWithFormat:@"v%@", version];

	return c;
}

@implementation PEPinEntryController

@synthesize pinDelegate, verifyOnly;

+ (PEPinEntryController *)pinVerifyController
{
	PEViewController *c = EnterController();
	PEPinEntryController *n = [[self alloc] initWithRootViewController:c];
	c.delegate = n;
    n->pinController = c;
	n->pinStage = PS_VERIFY;
	n->verifyOnly = YES;
	return n;
}

+ (PEPinEntryController *)pinChangeController
{
	PEViewController *c = EnterController();
	PEPinEntryController *n = [[self alloc] initWithRootViewController:c];
	c.delegate = n;
    c.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:BC_STRING_CANCEL style:UIBarButtonItemStylePlain target:n action:@selector(cancelController)];
    n->pinController = c;
	n->pinStage = PS_VERIFY;
	n->verifyOnly = NO;
	return n;
}

+ (PEPinEntryController *)pinCreateController
{
	PEViewController *c = NewController();
	PEPinEntryController *n = [[self alloc] initWithRootViewController:c];
	c.delegate = n;
    n->pinController = c;
	n->pinStage = PS_ENTER1;
	n->verifyOnly = NO;
	return n;
}

-(void)setActivityIndicatorAnimated:(BOOL)animated {
    
    pinController->keyboard.isEnabled = !animated;
    
    pinController->pin0.alpha = animated ? 0.75f : 1.0f;
    pinController->pin1.alpha = animated ? 0.75f : 1.0f;
    pinController->pin2.alpha = animated ? 0.75f : 1.0f;
    pinController->pin3.alpha = animated ? 0.75f : 1.0f;

    if (animated)
        [pinController.activityIndicator startAnimating];
    else
        [pinController.activityIndicator stopAnimating];
}

- (void)reset
{
    [self setActivityIndicatorAnimated:NO];
    
    [pinController resetPin];
}

- (void)pinEntryControllerDidEnteredPin:(PEViewController *)controller
{
	switch (pinStage) {
		case PS_VERIFY: {
			[self.pinDelegate pinEntryController:self shouldAcceptPin:[controller.pin intValue] callback:^(BOOL yes) {
                if (yes) {
                    if(verifyOnly == NO) {
                        PEViewController *c = NewController();
                        c.delegate = self;
                        pinStage = PS_ENTER1;
                        [[self navigationController] pushViewController:c animated:NO];
                        self.viewControllers = [NSArray arrayWithObject:c];
                    }
                } else {
                    controller.prompt = BC_STRING_INCORRECT_PIN_RETRY;
                    [controller resetPin];
                }
            }];
			break;
        }
		case PS_ENTER1: {
			pinEntry1 = [controller.pin intValue];
			PEViewController *c = VerifyController();
			c.delegate = self;
			[[self navigationController] pushViewController:c animated:NO];
			self.viewControllers = [NSArray arrayWithObject:c];
			pinStage = PS_ENTER2;
			break;
		}
		case PS_ENTER2:
			if([controller.pin intValue] != pinEntry1) {
                [self.pinDelegate pinEntryControllerInvalidSecondPinEntry:self];
				PEViewController *c = NewController();
				c.delegate = self;
				self.viewControllers = [NSArray arrayWithObjects:c, [self.viewControllers objectAtIndex:0], nil];
				[self popViewControllerAnimated:NO];
			} else {
				[self.pinDelegate pinEntryController:self changedPin:[controller.pin intValue]];
			}
			break;
		default:
			break;
	}
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
	pinStage = PS_ENTER1;
	return [super popViewControllerAnimated:animated];
}

- (void)cancelController
{
	[self.pinDelegate pinEntryControllerDidCancel:self];
}

@end
