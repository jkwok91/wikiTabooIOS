//
//  WordsTableViewController.m
//  wikiTaboo
//
//  Created by Jessica Kwok on 8/6/14.
//  Copyright (c) 2014 Jessica Kwok. All rights reserved.
//

#import "WordsTableViewController.h"
#import "Team.h"

@interface WordsTableViewController ()

@end

@implementation WordsTableViewController {
    // for parsing the wikipedia text
    NSArray *doesntCount;
    
    // 60 seconds on the clock
    int subroundLength;
    int secondsLeft;
    NSTimer *subroundTimer;
    
    // keeps an array of all teams
    NSMutableArray *_allTeams;
    int _numTeams;
    // and which one is currently playing
    int _currentTeamIdx;
    Team *_currentTeam;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // create tabooWords array
        self.tabooWords = [[NSMutableArray alloc] init];
        // filter out wikipedia stuff
        doesntCount = @[@"^",@"internal link",@"help page",@"references or sources",@"improve this article",@"adding citations to reliable sources"];
        // store teams
        _allTeams = [[NSMutableArray alloc] init];
        _currentTeamIdx = 0;
        subroundLength = 10;
        secondsLeft = subroundLength;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // all teams should register
    // these are placeholders
    Team *t1 = [[Team alloc] initWithName:@"team1"];
    Team *t2 = [[Team alloc] initWithName:@"team2"];
    Team *t3 = [[Team alloc] initWithName:@"teamBadass"];
    // put them in the _allTeams array
    _allTeams = @[t1,t2,t3];
    _numTeams = [_allTeams count];
    
    // creates a timer that calls updateCounter
    // wait i need it to only fire after the round starts? ugh
    subroundTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateCounter:) userInfo:nil repeats:YES]; // TODO FIX why is this timer so jumpy
    
    // game starts here
    [self getNewRound];
}

/**************/
/* GAME STATE */
/**************/
- (void)startGame {
    // start the game
}

- (void)pauseGame {
    // pause the game (tie this to a button)
}

- (void)endGame {
    // tally up the scores and return the winning team's name
}

/**********/
/* ROUNDS */
/**********/
- (void)getNewRound {
    [self getNewSubround];
    /*
     this is hella wrong. like, completely. that's not how you do it. i need a scheduled thing here.
     this is just a placeholder to convey what's gonna happen here (kinda?)
    for (Team *t in _allTeams) { 
        [self getNewSubround];
    } 
     */
}

- (void)getNewSubround {
    // update current team
    _currentTeam = [_allTeams objectAtIndex:_currentTeamIdx];
    self.currentTeamLabel.topItem.title = _currentTeam.teamName;
    self.scoreLabel.text = [NSString stringWithFormat:@"%i",_currentTeam.score];
    
    // start timer
        /* thanks, SO
         http://stackoverflow.com/questions/17145112/countdown-timer-ios-tutorial
         */
    secondsLeft = subroundLength;
    
    // get word
    [self getNewWord];
}

- (void)updateCounter:(NSTimer *)theTimer {
    if (secondsLeft > 0) {
        secondsLeft--;
    } else {
        // every time the timer hits 0, generate a new subround.
        _currentTeamIdx = (_currentTeamIdx+1)%_numTeams;
        if (_currentTeamIdx == 0) {
            [self getNewRound];
        } else {
            [self getNewSubround];
        }
    }
    self.timeLeftLabel.text = [NSString stringWithFormat:@"%i", secondsLeft];
}

/***********/
/* BUTTONS */
/***********/
- (void)guessedIt {
    _currentTeam.score++;
    self.scoreLabel.text = [NSString stringWithFormat:@"%d",_currentTeam.score];
    [self getNewWord];
}

- (void)skipIt { // wait should i just tie the button to "getNewWord"? or is this more readable?
    [self getNewWord];
}

/**************************/
/* HANDLING HTTP REQUESTS */
/**************************/
- (void)getNewWord {
    // clear prev word/taboo words
    self.word = @"";
    [self.tabooWords removeAllObjects];
    
    // pause timer (because latency)
    // TODO pause timer
    
    NSDictionary* json;
    
    NSURL *randomWord = [NSURL URLWithString:@"http://en.wikipedia.org/w/api.php?action=query&format=json&list=random&rnnamespace=0&rnlimit=1"];
    
    // parse out the json data
    json = [self getJSON:randomWord];
    self.word = [[[[json objectForKey:@"query"] objectForKey:@"random"] objectAtIndex:0] objectForKey:@"title"];
    // show word
    self.toBeGuessed.text = self.word;
    
    // now get the taboo words
    NSString *wordFormattedForURL = [self.word stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSString *urlString = [NSString stringWithFormat:@"http://en.wikipedia.org/w/api.php?format=json&action=parse&prop=text&page=%@&redirects=true&section=0",wordFormattedForURL];
    NSURL *randomPage = [NSURL URLWithString:urlString];
    
    json = [self getJSON:randomPage];
    // entire page in one string
    NSMutableString *text = [[[json objectForKey:@"parse"] objectForKey:@"text"] objectForKey:@"*"];
    NSError *error;
    // get all the linked words
    // regex for linked words
    // TODO improve regex so that the links are all to wikipedia ARTICLES and not helppages.
    // achievable by excluding links of the form wikipedia.org/wiki/Wikipedia: <---that colon.
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([^>]+( [A-Za-z0-9\u00A0-\uFFFF]+)*)(?=</a>)" options:0 error:&error];
    
    /* thanks, SO:
       http://stackoverflow.com/questions/16204218/nsstring-regex-string-matching-search
     */
    [regex enumerateMatchesInString:text options:0 range:NSMakeRange(0, [text length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
        
        // detect
        NSString *insideString = [text substringWithRange:[match rangeAtIndex:1]];
        for (NSString *str in doesntCount) {
            if (![insideString isEqualToString:str] && ![self.tabooWords containsObject:insideString]) {
                // load into taboo words array
                [self.tabooWords addObject:insideString];
            }
        }
    }];
    [self.tableView reloadData];
    
    NSRegularExpression *tagRegex = [NSRegularExpression regularExpressionWithPattern:@"<[^<>]+>" options:0 error:&error];
    text = [tagRegex stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, [text length]) withTemplate:@""];
    //NSLog(text);
    
    // resume timer
    // TODO resume timer
}

- (NSDictionary *)getJSON:(NSURL *)requestURL {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:requestURL];
    
    NSData *urlData;
    NSURLResponse *response;
    NSError *error;
    
    // Make synchronous request
    urlData = [NSURLConnection sendSynchronousRequest:request
                                    returningResponse:&response
                                                error:&error];
    
    // parse out the json data
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:urlData
                          options:kNilOptions
                          error:&error];
    return json;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return [self.tabooWords count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ListPrototypeCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSUInteger row = [indexPath row];
    NSUInteger count = [self.tabooWords count]; // here listData is your data source
    cell.textLabel.text = [self.tabooWords objectAtIndex:(count-row-1)];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
