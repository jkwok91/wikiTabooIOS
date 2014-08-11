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
    // TODO use wiki pageviews to select best pages
    // TODO fetch new word on resume
    // TODO pause on end of subround so that you can add score or wahtever
    // TODO load a couple of words in the background so there is no latency
    
    // for parsing the wikipedia text
    NSArray *doesntCount;
    
    // 60 seconds on the clock
    int subroundLength;
    int secondsLeft;
    NSTimer *subroundTimer;
    BOOL _paused;
    
    // game data
    int _numRounds;
    // keeps an array of all teams
    NSMutableArray *_allTeams;
    int _numTeams;
    // and which one is currently playing
    int _currentTeamIdx;
    Team *_currentTeam;
    
    // swipe gesture
    UISwipeGestureRecognizer *swipe;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.listOfWords = [NSMutableArray array];
        self.cards = [NSMutableDictionary dictionary];
        // filter out wikipedia stuff
        doesntCount = @[@"^",@"improve this article",@"archived here.",@"internal link",@"help page",@"references or sources",@"improve this article",@"adding citations to reliable sources"];
        // store teams
        _allTeams = [[NSMutableArray alloc] init];
        _currentTeamIdx = 0;
        //subroundLength = 5; // for testing
        subroundLength = 90;
        secondsLeft = subroundLength;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipe.numberOfTouchesRequired = 1;
    swipe.direction = UISwipeGestureRecognizerDirectionLeft; //recognize left direction
    [swipe setDelegate:self];
    [self.view setUserInteractionEnabled:YES];
    [self.view addGestureRecognizer:swipe];
    
    // all teams should register
    // these are placeholders
    Team *t1 = [[Team alloc] initWithName:@"team1"];
    Team *t2 = [[Team alloc] initWithName:@"team2"];
    Team *t3 = [[Team alloc] initWithName:@"teamBadass"];
    // put them in the _allTeams array
    _allTeams = @[t1,t2,t3];
    _numTeams = [_allTeams count];
    _numRounds = 5;
    
    // creates a timer that calls updateCounter
    // wait i need it to only fire after the round starts? ugh
    subroundTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateCounter) userInfo:nil repeats:YES]; // TODO FIX why is this timer so jumpy
    
    //[self performSelector:@selector(getTerm) withObject:self afterDelay:1.0f];
    // game starts here
    [self startGame];
}

/**************/
/* GAME STATE */
/**************/
- (void)startGame {
    // probably some other shit
    // how many rounds are we playing
    // start the game
    [self getTerm];
    [self getNewRound];
}

- (void)pauseGame {
    secondsLeft--;
    if (!_paused) {
        // pause the game (tie this to a button perhaps)
        [subroundTimer invalidate];
        subroundTimer = nil;
    } else {
        subroundTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateCounter) userInfo:nil repeats:YES];
    }
    _paused = !_paused;
}

- (void)endGame {
    // tally up the scores and return the winning team's name
    NSMutableArray *winners; // = [_allTeams objectAtIndex:0];
    int winningScore = 0;
    for (Team *t in _allTeams) {
        if (t.score >= winningScore) {
            [winners addObject:t];
        }
    }
    // go to new screen and display winners and winning score
}

/**********/
/* ROUNDS */
/**********/
- (void)getNewRound {
    [self getNewSubround];
    _numRounds--;
}

- (void)getNewSubround {
    // update current team
    _currentTeam = [_allTeams objectAtIndex:_currentTeamIdx];
    self.currentTeamLabel.text = _currentTeam.teamName;
    self.scoreLabel.text = [NSString stringWithFormat:@"%i",_currentTeam.score];
    
    // start timer
        /* thanks, SO
         http://stackoverflow.com/questions/17145112/countdown-timer-ios-tutorial
         */
    secondsLeft = subroundLength;
    
    // get word
    [self getNewWord];
}

- (void)updateCounter {
    if (secondsLeft > 0) {
        secondsLeft--;
        [self getTerm];
    } else {
        // every time the timer hits 0, generate a new subround.
        _currentTeamIdx = (_currentTeamIdx+1)%_numTeams;
        if (_currentTeamIdx == 0) {
            if (_numRounds > 0) {
                [self getNewRound];
            } else {
                [self endGame];
            }
        } else {
            [self getNewSubround];
        }
    }
    self.timeLeftLabel.text = [NSString stringWithFormat:@"%i", secondsLeft];
}

/********************/
/* HANDLES UI STUFF */
/********************/
- (IBAction)buttonTapped:(UIButton *)sender {
    _currentTeam.score++;
    self.scoreLabel.text = [NSString stringWithFormat:@"%d",_currentTeam.score];
    [self getNewWord];
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)recognizer {
    [self getNewWord];
}

- (IBAction)pause:(UIButton *)sender {
    [self pauseGame];
}

/************************/
/* LOADING UP NEW WORDS */
/************************/
- (void)getNewWord {
    self.word = [self.listOfWords objectAtIndex:0];
    self.toBeGuessed.text = self.word;
    self.tabooWords = [self.cards objectForKey:self.word];
    [self.tableView reloadData];
    [self.listOfWords removeObjectAtIndex:0];
}

- (void)getTerm {
    NSString *term = [self getWord];
    [self.listOfWords addObject:term];
    NSArray *taboo = [self getTabooWords:term];
    self.cards[term] = taboo;
}

- (NSString *)getWord {
    NSDictionary *json;
    NSString *word;
    NSURL *randomWord = [NSURL URLWithString:@"http://en.wikipedia.org/w/api.php?action=query&format=json&list=random&rnnamespace=0&rnlimit=1"];
    
    // parse out the json data
    json = [self getJSON:randomWord];
    word = [[[[json objectForKey:@"query"] objectForKey:@"random"] objectAtIndex:0] objectForKey:@"title"];
    return word;
}

- (NSArray *)getTabooWords:(NSString *)word {
    NSDictionary *json;
    NSMutableArray *taboos = [NSMutableArray array];
    // get the URL for this
    NSString *wordFormattedForURL = [word stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
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
        NSString *insideString = [[text substringWithRange:[match rangeAtIndex:1]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        for (NSString *str in doesntCount) {
            if (![insideString isEqualToString:str] && ![taboos containsObject:insideString]) {
                // load into taboo words array
                [taboos addObject:insideString];
            }
        }
    }];
    return (NSArray *)taboos;
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
