//
//  NTESMixAudioSettingView.m
//  NIMLiveDemo
//
//  Created by chris on 2016/12/15.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESMixAudioSettingView.h"
#import "UIView+NTES.h"

@interface NTESMixAudioSettingBar : UIView

@property (nonatomic, weak) id<NTESMixAudioSettingViewDelegate> delegate;

@end

@interface NTESMixAudioSettingView()

@property (nonatomic,strong) NTESMixAudioSettingBar *bar;

@end

@implementation NTESMixAudioSettingView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addTarget:self action:@selector(onTapBackground:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.bar];
    }
    return self;
}

- (void)setDelegate:(id<NTESMixAudioSettingViewDelegate>)delegate
{
    _delegate = delegate;
    self.bar.delegate = delegate;
}

- (void)onTapBackground:(id)sender
{
    [self dismiss];
}

- (void)show
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self];
    self.bar.top = self.height;
    self.bar.width = self.width;
    [UIView animateWithDuration:0.25 animations:^{
        self.bar.bottom = self.height;
    }];
}

- (void)dismiss
{
    [UIView animateWithDuration:0.25 animations:^{
        self.bar.top = self.height;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (NTESMixAudioSettingBar *)bar
{
    if (!_bar) {
        _bar = [[NSBundle mainBundle] loadNibNamed:@"NTESMixAudioSettingBar" owner:nil options:nil].firstObject;
    }
    return _bar;
}

@end


@interface NTESMixAudioData : NSObject

@property (nonatomic,copy)   NSString *audioName;

@property (nonatomic,copy)   NSString *title;

@property (nonatomic,assign) UIControlState state;

@end

@interface NTESMixAudioEffectData : NSObject

@property (nonatomic, assign) NSInteger index;

@property (nonatomic, assign) BOOL selected;

@property (nonatomic, assign) BOOL disable;

@property (nonatomic, copy) NSString *path;

@end


@interface NTESMixAudioSettingCell : UITableViewCell

@property (nonatomic,strong) UIButton *playButton;

- (void)refresh:(NTESMixAudioData *)data;

@end

@interface NTESMixAudioEffectCell : UICollectionViewCell

- (void)refresh:(NTESMixAudioEffectData *)data;

@end


@interface NTESMixAudioSettingBar()<UITableViewDelegate,UITableViewDataSource,NIMNetCallManagerDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic,copy) NSArray<NTESMixAudioData *> *data;

@property (nonatomic,copy) NSArray<NTESMixAudioEffectData *> *effectData;
@property (weak, nonatomic) IBOutlet UILabel *titleLab;
@property (weak, nonatomic) IBOutlet UILabel *effectTitleLab;

@property (nonatomic,strong) IBOutlet UITableView *tableView;

@property (nonatomic,strong) IBOutlet UILabel  *volumeLabel;

@property (nonatomic,strong) IBOutlet UISlider *volumeSlider;

@property (weak, nonatomic) IBOutlet UICollectionView *collectView;

@property (nonatomic, strong) UICollectionViewFlowLayout *collectLayout;

@property (nonatomic,strong) NTESMixAudioData *curentAudioData;

@end

@implementation NTESMixAudioSettingBar

- (void)awakeFromNib
{
    [super awakeFromNib];
    _data = [self buildData];
    _effectData = [self buildEffectData];
    [self.tableView registerClass:[NTESMixAudioSettingCell class] forCellReuseIdentifier:@"cell"];
    self.tableView.tableHeaderView = [[UIView alloc] init];
    
    [self.volumeSlider setThumbImage:[UIImage imageNamed:@"icon_volume_slider_normal"] forState:UIControlStateNormal];
    [self.volumeSlider setThumbImage:[UIImage imageNamed:@"icon_volume_slider_disable"] forState:UIControlStateDisabled];
    
    self.collectView.delegate = self;
    self.collectView.dataSource = self;
    self.collectView.backgroundColor = [UIColor clearColor];
    [self.collectView setCollectionViewLayout:self.collectLayout];
    [self.collectView registerClass:[NTESMixAudioEffectCell class]
         forCellWithReuseIdentifier:@"effectCell"];
    
    [[NIMAVChatSDK sharedSDK].netCallManager addDelegate:self];
    
    //第一次默认关闭
    [self refresh:YES];
}

- (void)dealloc
{
    [[NIMAVChatSDK sharedSDK].netCallManager removeDelegate:self];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _titleLab.origin = CGPointMake(10.0, 14.0);
    _tableView.frame = CGRectMake(_titleLab.left, _titleLab.bottom + 10.0, self.width - 10.0*2, 90.0);
    _volumeLabel.origin = CGPointMake(_tableView.left, _tableView.bottom + 10.0);
    _volumeSlider.frame = CGRectMake(_volumeLabel.right + 14.0, 0, self.width - _volumeLabel.right - 14.0 - 10.0, _volumeSlider.height);
    _volumeSlider.centerY = _volumeLabel.centerY;
    _effectTitleLab.origin = CGPointMake(_volumeLabel.left, _volumeLabel.bottom + 14.0);
    _collectView.frame = CGRectMake(_effectTitleLab.left, _effectTitleLab.bottom + 20.0, _tableView.width, 80.0);
    CGFloat w = (_collectView.width - 8.0f)/4.0;
    CGFloat h = (_collectView.height - 4.0f)/2.0;
    _collectLayout.itemSize = CGSizeMake(w, h);
}

- (IBAction)changeVolume:(id)sender
{
    [self callbackUpdateMixAudio];
}

- (void) refresh:(BOOL)enabled
{
    for (NTESMixAudioData *data in self.data) {
        data.state = enabled? UIControlStateNormal : UIControlStateDisabled;
    }
    if (!enabled) {
        //关掉的时候，把声音也切掉
        [[NIMAVChatSDK sharedSDK].netCallManager stopAudioMix];
        self.curentAudioData = nil;
    }
    self.volumeLabel.textColor = enabled? UIColorFromRGB(0xffffff) : UIColorFromRGB(0x666666);
    self.volumeSlider.tintColor = enabled? UIColorFromRGB(0x238efa) : UIColorFromRGB(0x666666);
    self.volumeSlider.enabled = enabled;
    [self.tableView reloadData];
}

- (NSArray *)buildData
{
    NSArray *array = @[
                         @{@"audio":@"live_mix_auido_example_1.mp3",@"title":@"歌曲1",@"state":@(UIControlStateDisabled)},
                         @{@"audio":@"live_mix_auido_example_2.mp3",@"title":@"歌曲2",@"state":@(UIControlStateDisabled)},
                      ];
    NSMutableArray *data = [[NSMutableArray alloc] init];
    for (NSDictionary *item in array) {
        NTESMixAudioData *audioData = [[NTESMixAudioData alloc] init];
        audioData.audioName = item[@"audio"];
        audioData.title = item[@"title"];
        audioData.state = [item[@"state"] integerValue];
        [data addObject:audioData];
    }
    return data;
}

- (NSArray *)buildEffectData {
    NSArray *sounds = @[@"Barricade Arpeggio.caf",
                        @"diamond.caf",
                        @"Diving Synth Effects 03.caf",
                        @"Rising Synth Effects 02.caf",
                        @"voice.aac"];
    NSMutableArray *datas = [NSMutableArray array];
    [sounds enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *path = [[NSBundle mainBundle] pathForResource:obj ofType:nil];
        if (path) {
            NTESMixAudioEffectData *model = [[NTESMixAudioEffectData alloc] init];
            model.index = datas.count;
            model.disable = NO;
            model.path = path;
            [datas addObject:model];
        }
    }];
    return datas;
}

- (void)updateAudioEffectSelectedWithIndex:(NSInteger)index {
    _collectView.userInteractionEnabled = NO;
    [_effectData enumerateObjectsUsingBlock:^(NTESMixAudioEffectData * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == index) {
            obj.selected = YES;
            obj.disable = NO;
        } else {
            obj.selected = NO;
            obj.disable = YES;
        }
    }];
    [_collectView reloadData];
}

- (void)updateAudioEffectUnSelected {
    _collectView.userInteractionEnabled = YES;
    [_effectData enumerateObjectsUsingBlock:^(NTESMixAudioEffectData * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.selected) {
            obj.selected = NO;
        }
        if (obj.disable) {
            obj.disable = NO;
        }
    }];
    [_collectView reloadData];
}

- (void)doPlayEffectWithPath:(NSString *)path {
    NSURL *url = [NSURL fileURLWithPath:path];
    NIMNetCallAudioFileMixTask *task = [[NIMNetCallAudioFileMixTask alloc] initWithFileURL:url];
    [[NIMAVChatSDK sharedSDK].netCallManager playSoundEffect:task];
}

#pragma mark - UITableViewDelegate,UITableViewDataSource
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45.f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"cell";
    NTESMixAudioSettingCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    cell.playButton.tag = indexPath.row;
    [cell.playButton addTarget:self action:@selector(onPressPlay:) forControlEvents:UIControlEventTouchUpInside];
    NTESMixAudioData *data = self.data[indexPath.row];
    [cell refresh:data];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - <UICollectionViewDelegate, UICollectionViewDataSource>
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _effectData.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NTESMixAudioEffectCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"effectCell" forIndexPath:indexPath];
    NTESMixAudioEffectData *model = _effectData[indexPath.row];
    [cell refresh:model];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat w = (collectionView.width - 8.0f)/4.0;
    CGFloat h = (collectionView.height - 4.0f)/2.0;
    return CGSizeMake(w, h);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NTESMixAudioEffectData *model = _effectData[indexPath.row];
    [self doPlayEffectWithPath:model.path];
    [self updateAudioEffectSelectedWithIndex:indexPath.row];
}

- (void)onPressPlay:(id)sender
{
    UIButton *button = sender;
    NTESMixAudioData *data = self.data[button.tag];
    if (self.curentAudioData == data) {
        if (self.curentAudioData.state == UIControlStateNormal)
        {
            //恢复
            self.curentAudioData.state = UIControlStateSelected;
            [self callbackResumeMixAudio];
        }
        else
        {
            //暂停
            self.curentAudioData.state = UIControlStateNormal;
            [self callbackPauseMixAudio];
        }
        
    }
    else{
        self.curentAudioData.state = UIControlStateNormal;
        self.curentAudioData = data;
        self.curentAudioData.state = UIControlStateSelected;
        //从头播放
        [self callbackSelectMixAudio];
    }
    [self.tableView reloadData];    
}

- (void)callbackSelectMixAudio
{
    if ([self.delegate respondsToSelector:@selector(didSelectMixAuido:sendVolume:playbackVolume:)]) {
        NSString *audioName = self.curentAudioData.audioName;
        NSURL *url = [[NSBundle mainBundle] URLForResource:audioName withExtension:nil];
        CGFloat volume = self.volumeSlider.value;
        [self.delegate didSelectMixAuido:url sendVolume:volume playbackVolume:volume];
    }
}

- (void)callbackPauseMixAudio
{
    if ([self.delegate respondsToSelector:@selector(didPauseMixAudio)]) {
        [self.delegate didPauseMixAudio];
    }
}

- (void)callbackResumeMixAudio
{
    if ([self.delegate respondsToSelector:@selector(didResumeMixAudio)]) {
        [self.delegate didResumeMixAudio];
    }
}

- (void)callbackUpdateMixAudio
{
    if ([self.delegate respondsToSelector:@selector(didUpdateMixAuido:playbackVolume:)]) {
        CGFloat volume = self.volumeSlider.value;
        [self.delegate didUpdateMixAuido:volume playbackVolume:volume];
    }
}

- (void)onAudioMixTaskCompleted
{
    self.curentAudioData.state = UIControlStateNormal;
    self.curentAudioData = nil;
    [self.tableView reloadData];
}

- (void)onSoundEffectPlayCompleted {
    [self updateAudioEffectUnSelected];
}

- (UICollectionViewFlowLayout *)collectLayout {
    if (!_collectLayout) {
        _collectLayout = [[UICollectionViewFlowLayout alloc] init];
        _collectLayout.minimumLineSpacing = 1.0f;
        _collectLayout.minimumInteritemSpacing = 1.0f;
    }
    return _collectLayout;
}

@end


@implementation NTESMixAudioSettingCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setImage:[UIImage imageNamed:@"icon_audio_mix_play_normal"] forState:UIControlStateNormal];
        [_playButton setImage:[UIImage imageNamed:@"icon_audio_mix_play_pressed"] forState:UIControlStateHighlighted];
        [_playButton setImage:[UIImage imageNamed:@"icon_audio_mix_play_disable"] forState:UIControlStateDisabled];
        [_playButton setImage:[UIImage imageNamed:@"icon_audio_mix_play_select_normal"] forState:UIControlStateSelected];
        [_playButton setImage:[UIImage imageNamed:@"icon_audio_mix_play_select_pressed"] forState:UIControlStateSelected|UIControlStateHighlighted];
        [_playButton sizeToFit];
        [self addSubview:_playButton];
        
        self.textLabel.font = [UIFont systemFontOfSize:15.f];
        
    }
    return self;
}

- (void)refresh:(NTESMixAudioData *)data
{
    if (data.state == UIControlStateSelected)
    {
        self.textLabel.text = [NSString stringWithFormat:@"%@ (播放中...)",data.title];
    }
    else
    {
        self.textLabel.text = data.title;
    }
    
    [self.textLabel sizeToFit];
    
    self.playButton.selected = NO;
    self.playButton.enabled  = YES;
    switch (data.state) {
        case UIControlStateSelected:
            self.playButton.selected = YES;
            self.textLabel.textColor = UIColorFromRGB(0xffffff);
            break;
        case UIControlStateNormal:
            self.playButton.selected = NO;
            self.textLabel.textColor = UIColorFromRGB(0xffffff);
            break;
        case UIControlStateDisabled:
            self.playButton.enabled = NO;
            self.textLabel.textColor = UIColorFromRGB(0x666666);
            break;
        default:
            break;
    }
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.textLabel.left = 0;
    self.textLabel.centerY = self.height * .5f;
    
    CGFloat right = 10.f;
    self.playButton.right   = self.width - right;
    self.playButton.centerY = self.height * .5f;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated{}

@end


@implementation NTESMixAudioData

@end

@interface NTESMixAudioEffectCell ()

@property (nonatomic, strong) UILabel *titleLab;

@end

@implementation NTESMixAudioEffectCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.titleLab];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _titleLab.frame = self.bounds;
}

- (void)refresh:(NTESMixAudioEffectData *)data {
    _titleLab.text = [NSString stringWithFormat:@"音效%zi", data.index + 1];
    if (data.selected) {
        _titleLab.textColor = [UIColor blueColor];
    } else if (data.disable) {
        _titleLab.textColor = UIColorFromRGB(0x666666);
    } else {
        _titleLab.textColor = UIColorFromRGB(0xffffff);
    }
}

#pragma mark - Getter
- (UILabel *)titleLab {
    if (!_titleLab) {
        _titleLab = [[UILabel alloc] init];
        _titleLab.font = [UIFont systemFontOfSize:15.0];
        _titleLab.textColor = UIColorFromRGB(0xffffff);
    }
    return _titleLab;
}

@end


@implementation NTESMixAudioEffectData

@end
