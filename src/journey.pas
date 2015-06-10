///****************************************************///
///***		Journey Through Candy Land				***///
///***				Created 2015					***///
///***				Nathan Gauci					***///
///***		Swinburne University of Technology		***///
///***				100 576 323						***///
///****************************************************///

program journey;
// Stops Msys from coming up 
{$APPTYPE GUI}
uses
	SwinGame, sgTypes, sysUtils, typInfo, TextUserInput;
const
	NO_OF_CANDY = 50;
	NO_OF_ENEMIES = 17;
	GRAVITY_DIVISOR = 5;
	FALL_BACK_DIVISOR = 1.1;
	FONT_SIZE = 20;
	AMT_OF_CHARS = 15;
	LEEWAY = 100;
type
	DifficultyKind = (Easy, Hard, Impossible);

	PlayerData = record
		bmp				: Bitmap;
		x, y			: Single;
		score, Health 	: Integer;
		name 			: String;
	end;
	
	EnemyData = record
		bmp				: Bitmap;
		x, y, dx 		: Single;
	end;

	CandyData = record
		bmp				: Bitmap;
		value			: Integer;
		x, y, dx		: Single;
	end;

	HighScoreData = record
		value			: Integer;
		difficulty		: DifficultyKind;
		name			: String;
	end;

	CandyArray = array of CandyData;
	
	EnemyArray = array of EnemyData;

	HighScores = array [0..9] of HighScoreData;
	
	GameData = record
		player			: PlayerData;
		candy			: CandyArray;
		enemies			: EnemyArray;
		scores			: HighScores;
		scoreFile		: TextFile;
		difficulty		: DifficultyKind;
		gameStarted		: Boolean;
		head			: Bitmap;
		speed 			: Integer;
		font			: Font;
	end;

function EnumToStr(const dKind: DifficultyKind): String;
{Uses the GetEnumName on the difficultyKind and the Integer eq of whichever procedure calls it}
begin
	result := GetEnumName(TypeInfo(DifficultyKind), Integer(dKind));
end;

procedure ReadUsername(const game: GameData);
{Because the text reading is done in 2 places, the number only has to change here :)}
begin
	StartReadingTextWithText(game.player.name, ColorWhite, AMT_OF_CHARS, game.font, 432, 232);
end;

procedure PrintHighScoreList(var game: GameData);
{ Clears the number list, opens the text file in override mode, then for each high score adds them to the list
and writes their value to the file, then closes the file}
var
	i: Integer;
begin
	ListClearItems('NumbersList');
	Rewrite(game.scoreFile);
	
	for i:=0 to High(game.scores) do
	begin
		ListAddItem('NumbersList', IntToStr(i+1) + ': ' + game.scores[i].name + ' '  +
		IntToStr(game.scores[i].value) + ' (' + EnumToStr(game.scores[i].difficulty) + ')');

		WriteLn(game.scoreFile, game.scores[i].value);						// Writes the value to the file
		WriteLn(game.scoreFile, Integer(game.scores[i].difficulty));		// Writes the difficulty to the file as an integer
		WriteLn(game.scoreFile, game.scores[i].name);						// Writes the users name to the file
	end;

	close(game.scoreFile);	
end;

procedure AddToHighScore(var game: GameData; const toAdd: Integer);
{Checks if the score to add is greater than the last number in the array and
if so overwrites the last number with the latest score, then calls the procedure to sort the list.
After that calls the procedure that prints the list of highscores}
	procedure ListSort(var ListArray: HighScores);
	{Sorts the list}
	var
		i, j: Integer;
		temp: HighScoreData;
	begin
		for i:= High(ListArray) downto Low(ListArray) do
		begin
			for j:= Low(ListArray) to (i - 1) do
			begin
				if (ListArray[j].value < ListArray[j+1].value) then
				begin
					temp 			:= ListArray[j];
					ListArray[j]	:= ListArray[j+1];
					ListArray[j+1]	:= temp;
				end;
			end;
		end;
	end;

begin
	if toAdd > game.scores[High(game.scores)].value then
	begin
		game.scores[High(game.scores)].value 		:= toAdd;
		game.scores[High(game.scores)].difficulty 	:= game.difficulty;
		game.scores[High(game.scores)].name 		:= game.player.name;
		
		ListSort(game.scores);
	end;

	PrintHighScoreList(game);
end;

procedure ChangeVariables(var game: GameData);
{ checks what the difficulty is and changes the variables accordingly}
begin
	case game.difficulty of
		easy:
		begin
			game.speed:=10;
			game.player.health:= 5;
		end;
		hard:
		begin
			game.speed:=20;
			game.player.health:= 3;
		end;
		Impossible:
		begin
			game.speed:=25;
			game.player.health:= 2;
		end;
	end;
end;

procedure DrawHeader(const header: Bitmap);
{Draws the bitmap for the header}
begin
	DrawBitmap(header, 0, 0);
	DrawBitmap(header, 0, ScreenHeight()-BitmapHeight(header));
end;

procedure SetupEnemy(var enemy: EnemyData; const game: GameData);
{if a random number between 0 and 2 is greater than or equal to the Integer value associated with the games difficulty
loads a smaller version, which allows the game to set the difficulty (a lower difficulty will have a greater percentage
of smaller images) then sets the start value to be randomly off the screen and makes it move at the speed of the game}
begin
	if Rnd(3) >= Integer(game.difficulty) then  	
	begin
		enemy.bmp:= LoadBitmap('enemy_small.png');
	end
	else 
	begin
		enemy.bmp:= LoadBitmap('enemy_large.png');
	end;

	enemy.x		:= Rnd(5000)+ScreenWidth();
					// Random of the screen height -twice the header and enemies height,
					// then adds one height of the header to get it in the middle
	enemy.y		:= BitmapHeight(game.head) + Rnd(ScreenHeight()-((BitmapHeight(game.head) * 2) + BitmapHeight(enemy.bmp)));
	enemy.dx	:= game.speed;
end;

procedure SetupAllEnemies(var game: GameData);
{loops through the enemy array and sets them up}
var
	i: Integer;
begin
	SetLength(game.enemies, NO_OF_ENEMIES);

	for i:=0 to High(game.enemies) do
	begin
		SetupEnemy(game.enemies[i], game);
	end;
end;

procedure SetupPlayer(var player: PlayerData);
{Procedure sets the player at the right edge of the screen to give them some time to understand the controls
 They start out with 0 score and a randomly generated amount of health, between 2 and 4}
begin
	player.bmp		:= LoadBitmap('player.png');
	player.x		:= ScreenWidth()-1; 
	player.y		:= ScreenHeight()/2;
	player.score	:= 0;
end;

procedure SetupCandy(var candy: CandyData; const game: GameData);
{gives the candy the picture, a random value between 5 and 20, a random location between
the screen width and 10,000 pixels off the side. Gives the candy's dx to the game speed}
begin
	candy.bmp 	:= LoadBitmap('candy.png');
	candy.value := Rnd(15)+5;
	candy.x 	:= Rnd(10000)+ScreenWidth();
	candy.y 	:= Rnd(ScreenHeight() - (BitmapHeight(candy.bmp)+BitmapHeight(game.head)));
	candy.dx 	:= game.speed;
end;

procedure SetupAllCandy(var game:GameData);
{sets the length of the array of candy to the constant amount set at start, then sets them up}
var
	i: Integer;
begin
	SetLength(game.candy, NO_OF_CANDY);

	for i := 0 to High(game.candy) do
	begin
		SetupCandy(game.candy[i], game);
	end;
end;

procedure UpdateEnemies(var game: GameData);
{Checks for each enemy to see if it is hit, if so subtracts one from the health and sets up the enemy again
then moves the enemy and redraws the enemy at the new location, then checks if the enemy is off the screen
(accounting for the leeway the player gets) and if it is resets the enemy}
var
	i: Integer;
begin
	for i:=Low(game.enemies) to High(game.enemies) do
	begin
		if BitmapCollision(game.player.bmp, Round(game.player.x), Round(game.player.y),
						   game.enemies[i].bmp, Round(game.enemies[i].x), Round(game.enemies[i].y)) then
		begin
			game.player.health-=1;
			SetupEnemy(game.enemies[i], game);
		end;
		
		game.enemies[i].x -= game.enemies[i].dx;
		DrawBitmap(game.enemies[i].bmp, game.enemies[i].x, game.enemies[i].y);
		
		if game.enemies[i].x < -LEEWAY then
		begin
			SetupEnemy(game.enemies[i], game);
		end;	
	end;	
end;

procedure UpdateCandies(var game: GameData);
{ Checks if the candy and the player collide and if so adds however much the score is worth for that
candy,then for each amount of candy moves them forward as fast as the dx. And if the candy goes off the
screen wraps around to a random x location off the screen.}
var
	i: Integer;
begin
	for i:=Low(game.candy) to High(game.candy) do
	begin
		if BitmapCollision(game.player.bmp, Round(game.player.x), Round(game.player.y),
		   				  game.candy[i].bmp, Round(game.candy[i].x), Round(game.candy[i].y)) then
		begin
			game.player.score += game.candy[i].value;
			SetupCandy(game.candy[i], game);
		end;

		DrawBitmap(game.candy[i].bmp, game.candy[i].x, game.candy[i].y);
		game.candy[i].x -= game.candy[i].dx;

		if game.candy[i].x < 0 then
		begin
			SetupCandy(game.candy[i], game);
		end;	
	end;	
end;

procedure UpdatePlayer(var game: GameData);
{Procedure updates the player, and shows the score, name and health at the top left of the screen,
Also moves the player back a bit slower than the game speed to allow them to move forward
stops from going below the floor
then tests if the user goes more than the leeway amount off the screen and kills them if they are}
begin
	if game.player.y < (ScreenHeight() - (BitmapHeight(game.player.bmp) + BitmapHeight(game.head)))  then
	begin
		game.player.y += (game.speed/GRAVITY_DIVISOR);
	end;
					// Less than - NOT less than or equal
	if game.player.x < -(BitmapWidth(game.player.bmp)+LEEWAY) then
	begin
		game.player.health := 0;
	end;

	DrawText('User Name: ' + game.player.name + ' Score: ' + IntToStr(game.player.score)
	+ ' Health: ' + IntToStr(game.player.health), ColorBlack, game.font, 0, BitmapHeight(game.head) + 5);

	game.player.x -= (game.speed/FALL_BACK_DIVISOR);
	DrawBitmap(game.player.bmp, game.player.x, game.player.y);
end;

procedure HandleUserInput(var game: GameData);
{allows the player to go up or right, but only if they are within the screen top and bottom}
begin
	ProcessEvents();

	if (KeyDown(vk_UP)) AND (game.player.y > BitmapHeight(game.head)) then
	begin
		game.player.y -= game.speed;
	end;
	if KeyDown(vk_RIGHT) then
	begin
		game.player.x += game.speed;
	end;
end;

procedure ChangeDifficulty(var dKind: DifficultyKind);
{Checks if the button is pressed and if so increments the difficulty up one level, 
checks if the difficulty is the max it can be and if so changes to easy and exits}
begin
	if ButtonClicked('DifficultyButton') then
	begin
		if (dKind = DifficultyKind(High(dKind))) then
		begin
			dKind := DifficultyKind(0);
		end
		else 
		begin
			dKind:=succ(dKind);
		end;
	end;

	ClearScreen(ColorWhite); // These make sure the text doesn't overwrite itself
	DrawInterface();		 //	and the text for the buttons doesnt screw up
end;

procedure ClearHSList(var game: GameData);
{ goes through each score and clears the array then prints array}
var
	i: Integer;
begin
	for i:=0 to High(game.scores) do
	begin
		game.scores[i].value 		:= 0;
		game.scores[i].difficulty 	:= DifficultyKind(0);
		game.scores[i].name 		:= '';
	end;

	PrintHighScoreList(game);	
end;

procedure StartGame(var game: GameData);
{sets the various variables and then starts the game}
begin
	game.player.name := EndReadingText();
	ProcessEvents();
	HidePanel('MenuPanel');
	SetupPlayer(game.player);
	game.gameStarted := TRUE;
	SetupAllCandy(game);
	SetupAllEnemies(game);
end;

procedure SetupGame(var game: GameData);
{Procedure clears the screen and draws the main menu, then refreshes the screen
Delays while the player still has their finger on up or right, because if not 
the user name is boxes, after the player lifts their finger allows the text to be read}
begin
	ClearScreen(ColorWhite);
	DrawHeader(game.head);
	ShowPanel('MenuPanel');
	game.gameStarted := FALSE;
	GUISetBackgroundColor(ColorWhite);
	GUISetForegroundColor(ColorBlack);
	DrawInterface(); // Needed to go to the menu before the player releases button
	RefreshScreen(60);

	while ((KeyDown(vk_RIGHT)) OR (KeyDown(vk_UP))) do
	begin
		Delay(100); 
	end;
	ReadUsername(game);
end;

procedure ShowAboutScreen(var game: GameData);
{Shows the about screen then waits for ctrl and q to be pressed then returns to the menu}
var
	aboutBmp: Bitmap;
begin
	aboutBmp := LoadBitmap('about.png');
	DrawBitmap(aboutBmp, 0, 0);
	game.player.name:= EndReadingText();
	RefreshScreen(60);
	while NOT ((WindowCloseRequested()) OR (KeyTyped(vk_ESCAPE))) do
	begin
		ProcessEvents();
		
		if ((KeyDown(vk_LCTRL)) AND (KeyDown(vk_Q)))then
		begin
			ReadUsername(game);
			break;
		end;
	end;
end;

procedure Menu(var game: GameData);
{Procedure runs while the player hasn't pressed the button yet, checks if they have changed the difficulty,
also draws the header and the text relating to the difficulty kind then refreshes the screen
also checks if the player presses ctrl and C runs the clear highscores procedure, then checks if the start
button is clicked and if so starts game}
begin
	UpdateInterface();
	ProcessEvents();
	ChangeDifficulty(game.difficulty);
	ChangeVariables(game);
	DrawHeader(game.head);
	DrawText('Current Difficulty: ' + EnumToStr(game.difficulty), ColorWhite, game.font, 300, 320);
	RefreshScreen(60);
	
	if ButtonClicked('AboutButton') then
	begin
		ShowAboutScreen(game);
	end;

	if (((KeyDown(vk_LCTRL) OR KeyDown(vk_RCTRL)) AND (KeyDown(vk_C))))
	OR (ButtonClicked('ClearHSButton')) then
	begin
		ClearHSList(game);
	end;
	
	if (ButtonClicked('StartButton') OR KeyTyped(vk_RETURN))then
	begin
		StartGame(game);
	end;
end;

procedure KillPlayer(var game: GameData);
{when the players health is <= 0 (if they die twice at once) sets up the game
again, sets the length of the arrays to 0 to get rid of all the candy and enemies}
begin
	if game.player.health <= 0 then
	begin
		AddToHighScore(game, game.player.score);
		SetupGame(game);
		SetLength(game.candy, 0);
		SetLength(game.enemies, 0);
	end;
end;

procedure PopulateHSList(var game: GameData);
var
	i: Integer;
begin
	for i:=0 to High(game.scores) do
	begin
		game.scores[i].value:= ReadIntegerF(game.scoreFile);						// Sets the value at i to the matching line in the hsfile
		game.scores[i].difficulty:= DifficultyKind(ReadIntegerF(game.scoreFile));	// Sets the difficulty in the array to the Dkind equivalent
		game.scores[i].name := ReadStringF(game.scoreFile); 						// same as first
	end;

	close(game.scoreFile);
	PrintHighScoreList(game);	
end;

procedure LoadGame(var game: GameData);
{sets the icon for windows,opens the window and loads the header bitmap and font for writing text, then loads the 'side bar'
which is the menu,then calls the draw header procedure, sets the difficulty to easy, and for each highscore gives it the value 0}
begin
	SetIcon(PathToResource('WinIcon.png'));
	OpenGraphicsWindow('Journey through Candy Land', 800, 600);
	ShowSwinGameSplashScreen();
	AssignFile(game.scoreFile, PathToResource('./highscores.jtc'));
	game.head:= LoadBitmap('header.png');
	game.font:= LoadFont('arial.ttf', FONT_SIZE);
	LoadResourceBundle('MenuBundle.txt');
	game.difficulty:= EASY;
	Reset(game.scoreFile); 
	PopulateHSList(game);
end;

procedure Main();
var
	game: GameData;
begin
	LoadGame(game);
	SetupGame(game);
	repeat
		Menu(game);
		while ((game.gameStarted) AND NOT ((WindowCloseRequested()) OR (KeyTyped(vk_ESCAPE)))) do
		begin
			ClearScreen(ColorWhite);
			HandleUserInput(game);
			UpdatePlayer(game);
			KillPlayer(game);
			DrawHeader(game.head);
			UpdateCandies(game);
			UpdateEnemies(game);
			RefreshScreen(60);
		end;
	until WindowCloseRequested() OR KeyTyped(vk_ESCAPE);
end;

begin
	Main();
end.