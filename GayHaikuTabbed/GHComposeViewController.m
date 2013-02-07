//
//  GHComposeViewController.m
//  Gay Haiku
//
//  Created by Joel Derfner on 12/2/12.
//  Copyright (c) 2012 Joel Derfner. All rights reserved.
//

#import "GHComposeViewController.h" 
#import "GHVerify.h"
#import "GHAppDefaults.h"
#import "GHVerify.h"

@interface GHComposeViewController () <UITextViewDelegate,UIAlertViewDelegate,UITextFieldDelegate,UIActionSheetDelegate>

@property (nonatomic, strong) UIImageView *background;
@property (nonatomic, strong) UITextView *instructions;
@property (nonatomic, strong) UITextView *nextInstructions;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) GHAppDefaults *userSettings;
@property (nonatomic) BOOL syllablesWrong;
@property (nonatomic) BOOL animateComposeScreen;

@end

@implementation GHComposeViewController

#pragma mark SETUP/CREATION METHODS

-(void)viewDidLoad {
    [super viewDidLoad];
    
                //Create and add swipe gesture recognizers
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(displayComposeScreen)];
    [swipeRight setNumberOfTouchesRequired : 1];
    [swipeRight setDirection : UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer:swipeRight];
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(displayInstructionsScreen)];
    [swipeLeft setNumberOfTouchesRequired : 1];
    [swipeRight setDirection : UISwipeGestureRecognizerDirectionLeft];
    [self.view addGestureRecognizer:swipeLeft];
    
                //Set defaults, including user defaults, non-animated compose screen, and (implicitly, by not declaring it) deactivate disable syllable check.
    
    [self setUserSettings : [GHAppDefaults sharedInstance]];
    [self.userSettings setUserDefaults];
    [self setAnimateComposeScreen : NO];
    
                //Access the shared instance of GHHaiku.

    ghhaiku = [GHHaiku sharedInstance];
    
                //Add the background image, choosing the correct one depending on whether you're using a 3.5 or a 4-inch screen.
    
    screenHeight = self.view.bounds.size.height;
    screenWidth = self.view.bounds.size.width;
    CGRect frame = CGRectMake(0, 0, screenWidth, (screenHeight-TAB_BAR_HEIGHT));
    [self setBackground : [[UIImageView alloc] initWithFrame:frame]];
    if (screenHeight<500) {
        [self.background setImage : [UIImage imageNamed:@"instructions.png"]];
    }
    else {
        [self.background setImage : [UIImage imageNamed:@"5instructions.png"]];
    }
    [self.view addSubview:self.background];
    
                //UNCOMMENT THESE LINES FOR TESTING:
    
    //userSettings.optOutSeen=NO;
    //userSettings.instructionsSeen=NO;
    //userSettings.instructionsSwipedToFromOptOut=NO;
    //userSettings.author=nil;
}

-(void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
                //If the user hasn't ever seen the opt out screen, show it.
    
    if (self.userSettings.optOutSeen==NO) {
        [self.tabBarController setSelectedIndex:4];
    }
    
                //Otherwise, if the user hasn't ever seen instructions screen, show it.
    
    else if (self.userSettings.instructionsSeen==NO) {
        [self displayInstructionsScreen];
        
                //Indicate that, since we're on instructions screen, if we go to the compose screen it should animate.
        
        [self setAnimateComposeScreen : YES];
    }
    
                //Otherwise, show the compose screen.  Indicate we're NOT coming from instructions screen so that compose screen won't be animated.
    
    else {
        [self setAnimateComposeScreen : NO];
        [self displayComposeScreen];
    }
}

-(UITextView *)createSwipeToAdd: (NSString *)word {
    
                //Create "Swipe" text and its characteristics
    
    UITextView *tV = [[UITextView alloc] init];
    [tV setEditable : NO];
    [tV setUserInteractionEnabled : NO];
    [tV setTextColor : self.userSettings.screenColorOp];
    [tV setBackgroundColor : [UIColor clearColor]];
    [tV setText : word];
    [tV setFont : [UIFont fontWithName:@"Zapfino" size:LARGE_FONT_SIZE]];
    return tV;
}

-(void)addSwipeForRight:(NSString *)direction {

                //Create the text to tell the user to swipe to the next screen.
    
    NSString *word;
    if (self.userSettings.instructionsSeen==NO) {
        word = @"Swipe";
    }
    else {
        word = @"Swipe to compose";
    }
    self.nextInstructions = [self createSwipeToAdd:word];
    NSString *text;
    if (self.userSettings.instructionsSeen==NO) {
        text = [word stringByAppendingString:@"compo"];
    }
    else {
        text = [word stringByAppendingString:@"co"];
    }
    
                //Locate and frame the text on the right side of the view.
    
    CGSize xySize = [text sizeWithFont:[UIFont fontWithName:@"Zapfino" size:LARGE_FONT_SIZE]];
    CGRect rect = CGRectMake((screenWidth - xySize.width), screenHeight*0.75, xySize.width, xySize.height);
    [self.nextInstructions setFrame : rect];
        
                //Display and animate it.
    
    [self animateView:self.nextInstructions withDirection:direction];
    [self.view addSubview:self.nextInstructions];
}

#pragma mark DISPLAY METHODS

-(UITextView *)instructions {
    
                //Lazily instantiate instructions for instructions display.
    
    if (!_instructions)
    {
        _instructions = [[UITextView alloc] init];
        [_instructions setBackgroundColor : [UIColor clearColor]];
        [_instructions setFont:[UIFont fontWithName:@"Georgia" size:SMALL_FONT_SIZE]];
        [_instructions setEditable : NO];
        [_instructions setText : @"\nFor millennia, the Japanese haiku has allowed great\nthinkers to express their ideas about the world in three\nlines of five, seven, and five syllables respectively.\n\nContrary to popular belief, the three lines need not be\nthree separate sentences. Rather, either the first two\nlines are one thought and the third is another or the\nfirst line is one thought and the last two are another;\nthe two thoughts are often separated by punctuation.\n\nHave a fabulous time composing your own gay haiku!"];
        NSString *t = @"thinkers to express their ideas about the world in three lin";
        CGSize thisSize = [t sizeWithFont:[UIFont fontWithName:@"Georgia" size:SMALL_FONT_SIZE]];
        int textWidth = thisSize.width;
        
        //Obviously this is an ugly hack and needs to be defined somewhere else.
        
        int textHeight = thisSize.height*17;
        [_instructions setFrame : CGRectMake(screenWidth/2-textWidth/2, screenHeight/2-textHeight/2 + 32, textWidth, textHeight)];
    }
    return _instructions;
}

-(void)displayInstructionsScreen {
    
                //If user is coming from the compose screen, which has a different background image, set the background image for the screen.
    
    if (self.background.image==[UIImage imageNamed:@"compose.png"] || self.background.image==[UIImage imageNamed:@"5compose.png"]) {
        [self.background removeFromSuperview];
        CGRect frame = CGRectMake(0, 0, screenWidth, screenHeight-TAB_BAR_HEIGHT);
        self.background = [[UIImageView alloc] initWithFrame:frame];
        if (screenHeight<500) {
            [self.background setImage : [UIImage imageNamed:@"instructions.png"]];
        }
        else {
            [self.background setImage : [UIImage imageNamed:@"5instructions.png"]];
        }
        [self.view addSubview:self.background];
        
    }
    
                //Hide the textview and resign first responder.
    
    [self.textView setHidden : YES];
    [self.textView resignFirstResponder];
    
                //If we're coming from the opt-out screen (i.e. swiping from the right), animate the instructions to the left.
    
    if (self.userSettings.instructionsSwipedToFromOptOut==YES) {
        [self animateView:self.instructions withDirection:@"left"];
        [self addSwipeForRight:@"left"];
    }
    
                //If we're coming from the compose screen (i.e. swiping from the left), animate the instructions to the left.
    
    else if (self.userSettings.instructionsSwipedToFromOptOut==NO) {
        
                //If we're coming from the compose screen, animate instructions from right.
            
        [self animateView:self.instructions withDirection:@"right"];
        [self addSwipeForRight:@"right"];
    }
    
                //Set boolean to indicate that the opt-out to instructions swipe has happened, and update the defaults.
    
    if (self.userSettings.instructionsSwipedToFromOptOut==NO) {
        [self.userSettings setInstructionsSwipedToFromOptOut : YES];
        [self.userSettings.defaults setBool:YES forKey:@"instructionsSwipedTo?"];
        [self.userSettings.defaults synchronize];
    }
    
                //Set boolean to indicate that the instructions have been seen, and update the defaults
    
    if (self.userSettings.instructionsSeen==NO) {
        [self.userSettings setInstructionsSeen : YES];
        [self.userSettings.defaults setBool:YES forKey:@"instructionsSeen?"];
        [self.userSettings.defaults synchronize];
    }
    
                //If we're coming from the compose screen, make sure the instructions are visible.  Add them to the view.
    
    [self.instructions setHidden : NO];
    [self.view addSubview:self.instructions];
    
                //Animate the compose screen if that's where we go next.
    
    [self setAnimateComposeScreen : YES];
}

-(void)animateView:(UIView *)tv withDirection: (NSString *)direction {
    
                //Set animation.
    
    CATransition *transition = [CATransition animation];
    [transition setDuration : 0.25];
    [transition setTimingFunction : [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [transition setType : kCATransitionPush];
    [transition setDelegate : self];
    
                //Indicate which direction animation is going.
    
    if ([direction isEqualToString:@"right"]) [transition setSubtype :kCATransitionFromRight];
    else if ([direction isEqualToString:@"left"]) [transition setSubtype : kCATransitionFromLeft];

                //Add animation.
    
    [tv.layer addAnimation:transition forKey:nil];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)displayComposeScreen {
    
                //Change the screen to the compose screen.
    
    [self.background removeFromSuperview];
    CGRect frame = CGRectMake(0, 0, screenWidth, screenHeight);
    self.background = [[UIImageView alloc] initWithFrame:frame];
    if (screenHeight<500) {
        [self.background setImage : [UIImage imageNamed:@"compose.png"]];
    }
    else {
        [self.background setImage : [UIImage imageNamed:@"5compose.png"]];
    }
    [self.view addSubview:self.background];
    
                //Hide the instructions and the swipe-for-next text.
    
    [self.instructions setHidden : YES];
    [self.nextInstructions removeFromSuperview];
    
                //Create the textView if it doesn't exist.
    
    if (!self.textView) {
        if (screenHeight<500) {
            self.textView = [[UITextView alloc] initWithFrame:CGRectMake(40, 40, 240, 135)];
        }
        else {
            self.textView = [[UITextView alloc] initWithFrame:CGRectMake(40, 40, 240, 222)];
        }
        [self.textView setDelegate : self];
    }
    
                //Create the translucent toolbar for above the keyboard.
    
    [self addTranslucentToolbarAboveKeyboard];
    
                //Set the textView's attributes.
    
    [self.textView setEditable : YES];
    [self.textView setBackgroundColor : [UIColor clearColor]];
    [self.textView setHidden : NO];
    [self.textView setFont : [UIFont fontWithName:@"Georgia" size:14]];
    
                //If the user is NOT editing a user haiku, set the textView's text to nil.  If the user IS editing a user haiku, set the textView's text to that haiku.
    
    if (ghhaiku.userIsEditing==NO || ghhaiku.isUserHaiku==NO) {
        [self.textView setText : @""];
    }
    else {
        GHVerify *ghv = [[GHVerify alloc] init];
        [self.textView setText : [ghv removeAuthor:ghhaiku.text]];
    }
    
                //Show the textView and set up the keyboard.
    
    [self.view addSubview:self.textView];
    [self.textView becomeFirstResponder];
    
                //Set up animation if we're coming from the instructions screen and set boolean so we're not coming from the instructions screen anymore.
    
    if (self.animateComposeScreen == YES) {
        [self animateView:self.view withDirection:@"right"];
        [self setAnimateComposeScreen : NO];
    }
}

-(void)addTranslucentToolbarAboveKeyboard {
    
                //Create translucent toolbar to sit above keyboard.
    
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [toolbar setTintColor:self.userSettings.screenColorTrans];
    [toolbar setTranslucent : YES];
    [toolbar sizeToFit];
    
                //Create "instructions" and "done" buttons and add them to the translucent toolbar.
    
    UIBarButtonItem *instructionsButton = [[UIBarButtonItem alloc] initWithTitle:@"Instructions" style:UIBarButtonItemStyleBordered target:self action:@selector(displayInstructionsScreen)];
    UIBarButtonItem *flexButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *doneButton =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(resignKeyboard)];
    NSArray *itemsArray = [NSArray arrayWithObjects:instructionsButton, flexButton, doneButton, nil];
    [toolbar setItems:itemsArray];
    [self.textView setInputAccessoryView:toolbar];
}
    
-(void)resignKeyboard {
    
                //Resign first responder and call action sheet.
    
    [self.textView resignFirstResponder];
    [self doActionSheet];
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    [textField becomeFirstResponder];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark SAVING METHODS

-(void)doActionSheet {
    [self.textView resignFirstResponder];
    UIActionSheet *actSheet;
    
                //If user hasn't made any changes, simply return to home screen and current haiku.
    
    if (self.textView.text.length==0) {
        [self.textView setText : @""];
        [self.tabBarController setSelectedIndex:0];
    }
    
                //If user HAS made changes, show alert view with appropriate destructive button title depending on whether it's a new haiku or an edited one.
    
    else {
        NSString *destroyButtonTitle;
        if (ghhaiku.userIsEditing) {
            destroyButtonTitle=@"Discard Changes";
        }
        else {
            destroyButtonTitle=@"Discard";
        }
        actSheet = [[UIActionSheet alloc] initWithTitle:nil delegate: self cancelButtonTitle:@"Continue Editing" destructiveButtonTitle:destroyButtonTitle otherButtonTitles:@"Save", nil];
        [actSheet showFromTabBar:self.tabBarController.tabBar];
    }
}

-(void)actionSheet:(UIActionSheet *)actSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
                //If the action sheet button is "cancel" or "discard changes," return to the home screen.
    
    if (buttonIndex==0) {
        [self.textView setText : @""];
        [self.tabBarController setSelectedIndex:0];
    }
    
                //If the action sheet button is "save," save the haiku.
    
    else if (buttonIndex==1) {
        [self verifySyllables];
    }
    
                //If the action sheet button is "continue editing," dismiss action sheet and make textView the first responder again.
    
    else {
        [actSheet dismissWithClickedButtonIndex:2 animated:YES];
        [self.textView becomeFirstResponder];
    }
}

-(BOOL)verifySyllables {
    
                //Create an instance of GHVerify if one doesn't exist.
    
    GHVerify *ghverify = [[GHVerify alloc] init];
    
                //Divide the current haiku into lines.
    
    [ghverify splitHaikuIntoLines:self.textView.text];
    
                //Check the number of syllables in each line.
    
    [ghverify checkHaikuSyllables];
    
                //Construct the part of the alert message correcting the number of lines, if one be necessary.
    
    NSString *alertMessage;
    BOOL somethingIsAmiss;
    if (ghverify.numberOfLinesAsProperty==tooFewLines) {
        alertMessage = @"Your haiku might have too few lines";
        somethingIsAmiss=YES;
    }
    else if (ghverify.numberOfLinesAsProperty==tooManyLines) {
        alertMessage = @"Your haiku might have too many lines";
        somethingIsAmiss=YES;
    }
    
                //Create an iterator for the array of lines in the haiku.
    
    int k;
    if (ghverify.listOfLines.count<3) {
        k=ghverify.listOfLines.count;
    }
    else {
        k=3;
    }
    
                //Create an array to hold the record of lines that have an incorrect number of syllables.
    
    NSMutableArray *arrayOfLinesToAlert = [[NSMutableArray alloc] init];
    
                //Iterate through the array of lines in the haiku and, if any need correction, note that in arrayOfLinesToAlert.
    
    for (int i=0; i<k; i++) {
        if (ghverify.linesAfterCheck[i])
        {
            if (![ghverify.linesAfterCheck[i] isEqualToString:@"just right"]) {
                [arrayOfLinesToAlert addObject:[NSNumber numberWithInt:i+1].stringValue];
            }
        }
    }
    
                //If there are syllable errors, add notification of these to the alert message.
    
    if (arrayOfLinesToAlert.count>0) {
        
        if (somethingIsAmiss==YES) {
            alertMessage=[alertMessage stringByAppendingString:@". Also, though the syllable-counting algorithm is imperfect, "];
        }
        else {
            alertMessage = @"Though the syllable-counting algorithm is imperfect, ";
            somethingIsAmiss=YES;
        }
        NSString *phrase;
        NSString *number;
        if (arrayOfLinesToAlert.count==1) {
            number = [NSString stringWithFormat:@"line %@ seems to have",arrayOfLinesToAlert[0] ];
        }
        else if (arrayOfLinesToAlert.count==2) {
            number = [NSString stringWithFormat:@"lines %@ and %@ seem to have",arrayOfLinesToAlert[0],arrayOfLinesToAlert[1]];
            }
        else if (arrayOfLinesToAlert.count==3) {
            number = [NSString stringWithFormat:@"lines %@, %@, and %@ seem to have",arrayOfLinesToAlert[0],arrayOfLinesToAlert[1],arrayOfLinesToAlert[2]];
        }
        phrase = [NSString stringWithFormat:@"%@ the wrong number of syllables (you need 5-7-5). ",number];
        alertMessage = [alertMessage stringByAppendingFormat:@"%@",phrase];
        }
    
    arrayOfLinesToAlert=Nil;
    
                //If the alert message needs displaying, add an ending to it and display it with an alertView.
    
    if (self.userSettings.disableSyllableCheck==YES) {
        [self setSyllablesWrong : YES];
        [self saveUserHaiku];
        return YES;
    }
    if (somethingIsAmiss) {
        NSString *add = @"Are you certain you'd like to continue saving?";
        alertMessage = [alertMessage stringByAppendingFormat:@" %@",add];
        UIAlertView *alert;
        alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?" message:alertMessage delegate:self cancelButtonTitle:@"Edit" otherButtonTitles:@"Save", nil];
        [alert show];
        somethingIsAmiss=NO;
        return YES;
    }
    
                //Otherwise, save the haiku.
    
    else {
        [self saveUserHaiku];
        return NO;
    }
}

-(BOOL)checkForRepeats {
    
                //Check to see whether the haiku the user has written is an exact duplicate of one already in the database.
    
    int i;
    for (i=0; i<ghhaiku.gayHaiku.count; i++) {
        NSString *haikuToCheck = [ghhaiku.gayHaiku[i] valueForKey:@"haiku"];
        
                //If it is, set that haiku to be the current haiku and return to the home screen.
        
        if ([self.textView.text isEqualToString:haikuToCheck]) {
            [ghhaiku setJustComposed : YES];
            [ghhaiku setNewIndex : i];
            [self.tabBarController setSelectedIndex:0];
            return YES;
        }
    }
    return NO;
}

-(BOOL)saveUserHaiku {
    
    NSString *haikuWithAttribution;
    
                //If user has entered name...
    
    if (self.userSettings.author) {
        
                //...add it to the haiku.
        
        haikuWithAttribution = [self.textView.text stringByAppendingFormat:@"\n\n\t%@",self.userSettings.author];
    }
    else {
        haikuWithAttribution = self.textView.text;
    }
    
                //Get out of this method if the haiku is a repeat of one the user has already written.  This method has to be called AFTER haikuWithAttribution is added to the haiku; otherwise, new haiku won't match with old attributed haiku.
    
    [self checkForRepeats];
    if ([self checkForRepeats]==YES) {
        return YES;
    }
    
                //Create the dictionary item of the new haiku to save in userHaiku.plist.
    
    NSArray *collectionOfHaiku = [[NSArray alloc] initWithObjects:@"user", haikuWithAttribution, nil];
    NSArray *keys = [[NSArray alloc] initWithObjects:@"category",@"haiku",nil];
    NSDictionary *dictToSave = [[NSDictionary alloc] initWithObjects:collectionOfHaiku forKeys:keys];

                //If the saved haiku is a new haiku, advance the current index by one and insert the new haiku at that position.
    
    if (self.textView.text.length>0 && ghhaiku.userIsEditing==NO) {
        ghhaiku.newIndex++;
        [ghhaiku.gayHaiku insertObject:dictToSave atIndex:ghhaiku.newIndex];
    }
    
                //If the saved haiku is an edited old haiku, replace the old version with the edited version and indicate that user is no longer editing.
    
    else if (ghhaiku.userIsEditing==YES && self.textView.text.length>0) {
        [ghhaiku.gayHaiku insertObject:dictToSave atIndex:ghhaiku.newIndex];
        [ghhaiku.gayHaiku removeObjectAtIndex:ghhaiku.newIndex+1];
        [ghhaiku setUserIsEditing : NO];
    }
    
                //If there's no actual haiku, return to the home screen.
    
    else if (!self.textView.text.length>0) {
        [self.tabBarController setSelectedIndex:0];
        return YES;
    }
    
                //Save the haiku to the plist.
    
    [ghhaiku saveToDocsFolder:@"userHaiku.plist"];
    
                //Create a PFObject to send to parse.com with the text of the haiku
    
//COMMENT THE FOLLOWING LINES FOR TESTING
    
    PFObject *haikuObject = [PFObject objectWithClassName:@"TestObject"];
    [haikuObject setObject:self.textView.text forKey:@"haiku"];
    
                //Include the author's name with the object
    
    if (self.userSettings.author) {
        [haikuObject setObject:self.userSettings.author forKey:@"author"];
    }
    
                //Indicate whether I have permission to use it.
    
    NSString *perm;
    if (self.userSettings.permissionDenied) {
        perm=@"No";
    }
    else {
        perm=@"Yes";
    }
    [haikuObject setObject:perm forKey:@"permission"];
    
                //Indicate whether syllables have been misanalyzed.
    
    NSString *misanalysis;
    if (self.syllablesWrong!=YES) {
        misanalysis=@"Yes";
    }
    else {
        misanalysis=@"No";
    }
    [self setSyllablesWrong : NO];
    [haikuObject setObject:misanalysis forKey:@"misanalyzed"];
    
               //Send the PFObject.

    [haikuObject saveEventually];
    
//END COMMENT FOR TESTING
    
                //Indicate that the current haiku is a user-composed one so the home screen knows what to display.
    
    [ghhaiku setJustComposed : YES];
    
                //Remove unnecessary UITextViews from view.
    
    [self.textView removeFromSuperview];
    [self.nextInstructions removeFromSuperview];
    
                //Return to home screen.
    
    [self.tabBarController setSelectedIndex:0];
    return YES;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger) buttonIndex {
    
                //If there are putative syllable errors and user choice is "continue editing," return to the textView.
    
    if (buttonIndex == 0) {
        [self.textView becomeFirstResponder];
    }
    
                //Otherwise, save haiku despite errors.
    
    else if (buttonIndex == 1) {
        [self setSyllablesWrong : YES];
        [self saveUserHaiku];
    }
}

@end
