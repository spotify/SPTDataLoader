#import "PlaylistsViewController.h"

#import "PlaylistsViewModel.h"

@interface PlaylistsViewController () <PlaylistsViewModelDelegate>

@property (nonatomic, strong) PlaylistsViewModel *model;

@end

@implementation PlaylistsViewController

#pragma mark PlaylistsViewController

- (instancetype)initWithModel:(PlaylistsViewModel *)model
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _model = model;
    _model.delegate = self;
    
    return self;
}

#pragma mark PlaylistsViewModelDelegate

- (void)playlistsViewModelDidLoad:(PlaylistsViewModel *)model
{
    [self.tableView reloadData];
}

#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass(self.class)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.model load];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.model.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(self.class)];
    
    cell.textLabel.text = self.model.items[indexPath.row][@"name"];
    
    return cell;
}

@end
