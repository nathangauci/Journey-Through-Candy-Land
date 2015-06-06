program journey;
uses
	SwinGame, sgTypes, sysUtils;
const
	GAME_SPEED = 10;
type
	Player = record
		bmp: Bitmap;
		x, y: Single;
		score, health: Integer;
	end;
	
	CandyData = record
		bmp: Bitmap;
		value: Integer;
		x, y, dx: Integer;
	end;

	CandyArray = array of CandyData;

	GameData = record
		player: Player;
		candy: CandyArray;
		gameStarted: Boolean;
		head: Bitmap;
	end;

	// HighScore = array [0..9] of String;

procedure SetupPlayer(var player: Player);
{Procedure sets the player at the right edge of the screen to give them sometime to understand the controls
 They start out with 0 score and a randomly generated amount of health, between 2 and 4}
begin
	player.bmp:= LoadBitmap('player.png');
	player.x:= ScreenWidth()-1; 
	player.y:= ScreenHeight()/2;
	player.health:= Rnd(3)+2; 
	player.score:=0;
end;

procedure SetupCandy(var candy: CandyData; head:Bitmap);
{gives the candy the picture, a random value between 5 and 20, a random location between
the screen width and 1000 pixels off the side. Gives the candy's dx to the game speed}
begin
	candy.bmp:= LoadBitmap('candy.png');
	candy.value:= Rnd(15)+5;
	candy.x:= Rnd(10000)+ScreenWidth();
	candy.y:=Rnd(ScreenHeight()-(BitmapHeight(candy.bmp)+BitmapHeight(head)));
	candy.dx:= GAME_SPEED;

end;

procedure SetupAllCandy(var game:GameData; amount: Integer);
{sets the length of the array of candy to whatever is set, then sets them up}
var
	i: Integer;
begin
 	SetLength(game.candy, amount);
	
	for i:=0 to High(game.candy) do
 	begin
 		SetupCandy(game.candy[i], game.head);
 	end;
end;

procedure UpdateCandy(var game: GameData);
{for each amount of candy moves them forward as fast as the dx}
var
	i: Integer;
begin
	for i:=Low(game.candy) to High(game.candy) do
	begin
		if BitmapCollision(game.player.bmp, Round(game.player.x), Round(game.player.y),
		   				  game.candy[i].bmp, Round(game.candy[i].x), Round(game.candy[i].y)) then
		begin
			game.player.score+=game.candy[i].value;
		end;
		DrawBitmap(game.candy[i].bmp, game.candy[i].x, game.candy[i].y);
		game.candy[i].x -= game.candy[i].dx;
		if game.candy[i].x < 0 then game.candy[i].x :=(Rnd(10000)+ScreenWidth());
	end;	
end;
procedure UpdatePlayer(var play: Player; const head: Bitmap);
{Procedure updates the player, and shows the score at the top left of the screen,
Also moves the player back if they don't hold down the correct arrow
Tests if the floor is there and stops from going below that.
Also tests if the user goes more than 100 pixels off the screen and kills them if they aren}
begin
	if play.y<(ScreenHeight()-(BitmapHeight(play.bmp)+BitmapHeight(head)))  then
	begin
		DrawText('Score: ' + IntToStr(play.score) + ' Health: ' + IntToStr(play.health), ColorBlack, 0, BitmapHeight(head) +5);
		play.y +=(GAME_SPEED/5);
	end;
	
	if play.x<-(BitmapWidth(play.bmp)+100) then
	begin
		play.health:=0;
	end;

	play.x -= (GAME_SPEED/1.1);
	DrawBitmap(play.bmp, play.x, play.y);
end;

procedure BeginGame(var game: GameData);
begin
	OpenGraphicsWindow('Journey through Candy Land II', 800, 600);
	game.head:= LoadBitmap('header.png');
	LoadResourceBundle( 'SideBundle.txt' );
end;

procedure SetupGame(var game: GameData);
{This procedure opens the window and gets the menu ready,
also sets up the player to work around the Mac bug whereby the game
crashes, sets the player off the screen so they aren't in the menu.}
begin
	
	SetupPlayer(game.player);
	
	game.player.y:=ScreenHeight();
	//game.player.health:=0;
	
	ShowPanel('SidePanel');
	DrawInterface();
	 		
	GUISetForegroundColor(ColorBlack);
	GUISetBackgroundColor(ColorWhite);
	RefreshScreen();
end;

procedure HandleUserInput(var game: GameData);
{allows the player to go up or right, but only if they are within the screen top and bottom}
begin
	ProcessEvents();
	if (KeyDown(vk_UP)) AND (game.player.y > BitmapHeight(game.head)) then
	begin
		game.player.y -= GAME_SPEED;
	end;
	if KeyDown(vk_RIGHT) then
	begin
		game.player.x+= GAME_SPEED;
	end;
end;

procedure UpdateGame(var game: GameData);
begin
	ClearScreen(ColorWhite);
	HandleUserInput(game);
end;

procedure StartGame(var game: GameData);
begin
	DrawInterface();
	UpdateInterface();
	if ButtonClicked('StartButton') then
	begin
		HidePanel('SidePanel');
		SetupPlayer(game.player);
		game.gameStarted:= TRUE;
		SetupAllCandy(game, 50);
	end;
end;

procedure KillPlayer(var game: GameData);
{when the players health is <= 0 (if they die twice at once) sets up the game
again, and puts all the candy off the screen and stops them from moving}
var
	i: Integer;
begin
	if game.player.health <=0 then
	begin
		ListAddItem('NumbersList', IntToStr(game.player.score));
		SetupGame(game);
		for i:=Low(game.candy) to High(game.candy) do
		begin
			game.candy[i].y:=ScreenWidth()*2;
			game.candy[i].dx:=0;
		end;

	end;
end;

procedure Header(var header: Bitmap);
begin
	DrawBitmap(header, 0, 0);
	DrawBitmap(header, 0, ScreenHeight()-BitmapHeight(header));
end;
procedure Main();
var
	game: GameData;
	i: Integer;

begin
	BeginGame(game);
	SetupGame(game);
	i:=0;
	//tests if the list displays properly
	// ListClearItems('NumbersList');
	// for i:= 0 to 9 do
	// begin
	// 	ListAddItem('NumbersList', IntToStr(i));
	// end;
	
	repeat
	 	repeat
	 		StartGame(game);
	 	until game.gameStarted;

	 	UpdateGame(game);
	 	
	 	DrawInterface();
	 	UpdateInterface();
	 	UpdatePlayer(game.player, game.head);
	 	KillPlayer(game);
		Header(game.head);
	 	UpdateCandy(game);
	 	RefreshScreen(60);
	until WindowCloseRequested OR KeyTyped(vk_ESCAPE);
end;

begin
	Main();
end.