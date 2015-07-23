var BLOCK_START = -1;
var BLOCK_WHITE = 0;
var BLOCK_BLACK = 1;
var BLOCK_CLICKED = 2;

var GAME_IDLE = 0;
var GAME_PLAYING = 1;
var GAME_OVER = 2;
var KEYSETTING = 3;

var KEYMAP = {
	34: "PAGE DOWN",
	35: "END",
	36: "HOME",
	37: "←",
	38: "↑",
	39:	"→",
	40: "↓",
	65: "A",
	68: "D",
	83:	"S",
	87: "W",
	96: "小键盘 0",
	97: "小键盘 1",
	98: "小键盘 2",
	99: "小键盘 3",
	100: "小键盘 4",
	101: "小键盘 5",
	102: "小键盘 6",
	103: "小键盘 7",
	104: "小键盘 8",
	105: "小键盘 9"
};

var gameManager;


function newView(manager){

	var view = {};

	view.canvas = $.createCanvas({
		x: 0,
		y: 0,
		lifeTime: 0
	});

	//黑白块的画布
	view.gridCanvas = $.createCanvas({
		x: 100,
		y: 0,
		lifeTime: 0,
		parent: view.canvas
	});

	view.grid = [];

	//grid的上层画布
	view.maskCanvas = $.createCanvas({
		x: 100,
		y: 0,
		lifeTime: 0,
		parent: view.canvas
	});

	//时间
	view.timeView = $.createComment("0.0",{
		lifeTime: 0,
		parent: view.maskCanvas
	});
	view.timeView.y = 10;

	//错误提示砖块 
	view.wrongBlock = $.createShape({
		lifeTime: 0,
		alpha: 0,
		parent: view.maskCanvas
	});
	var ta = Tween.to(view.wrongBlock, {alpha: 1}, 0.2);
	view.tWrongBlink = Tween.repeat(Tween.serial(ta, Tween.reverse(ta)), 3);

	//键位指示
	view.keyGuide = [
		$.createComment("1",{
			lifeTime: 0,
			parent: view.maskCanvas
		}),
		$.createComment("2",{
			lifeTime: 0,
			parent: view.maskCanvas
		}),
		$.createComment("3",{
			lifeTime: 0,
			parent: view.maskCanvas
		}),
		$.createComment("4",{
			lifeTime: 0,
			parent: view.maskCanvas
		})
	];
	
trace("#3");
	//游戏结束对话框
	view.gameOverBoard = $.createCanvas({
		lifeTime: 0,
		alpha: 0,
		parent: view.maskCanvas
	});
	view.tBoardShow = Tween.to(view.gameOverBoard, {alpha: 1}, 0.5);
	view.tBoardHide = Tween.to(view.gameOverBoard, {alpha: 0}, 0.3);
	var boardBackgroud = $.createShape({
		lifeTime: 0,
		x: 0,
		y: 0,
		parent: view.gameOverBoard
	});
	var g = boardBackgroud.graphics;
	g.beginFill(0xffffff);
	g.lineStyle(1, 0x000000,1,true);
	g.drawRoundRect(0,0,250,200,20,20);
	g.endFill();
	view.scoreTitle = $.createComment("",{
		x: 8,
		y: 8,
		lifeTime: 0,
		parent: view.gameOverBoard
	});
	view.bestscoreTitle = $.createComment("",{
		x: 8,
		y: 50,
		lifeTime: 0,
		parent: view.gameOverBoard
	});
	view.resetButton = $.createButton({
		x: 95,
		y: 150,
		text: "重来",
		lifeTime: 0,
		onclick: function(){
			if(manager.gameFlag == GAME_OVER){
				manager.reset();
				view.tBoardHide.play();
			}
		},
		parent: view.gameOverBoard
	});

	//改键区域
	view.keymapCanvas = $.createCanvas({
		lifeTime: 0,
		parent: view.canvas
	});
	view.keymapBackground = $.createShape({
		lifeTime: 0,
		x: 0,
		y: 0,
		parent: view.keymapCanvas
	});
	var g = view.keymapBackground.graphics;
	g.beginFill(0xffffff);
	g.lineStyle(1, 0x000000,1,true);
	g.drawRoundRect(0,0,128,250,20,20);
	g.endFill();
	$.createComment("改键区域",{
		lifeTime: 0,
		x: 8,
		y: 8,
		parent: view.keymapCanvas
	});
	view.kmButton = [];
	var key = ($G._get("keySet"))[0];
	var button = $.createButton({
		x: 16,
		y: 58,
		width: 96,
		lifeTime: 0,
		text: "1: " + KEYMAP[key],
		onclick: function(){
			manager.keySets(0);
		},
		parent: view.keymapCanvas
	});
	view.kmButton.push(button);
	key = ($G._get("keySet"))[1];
	button = $.createButton({
		x: 16,
		y: 108,
		width: 96,
		lifeTime: 0,
		text: "2: " + KEYMAP[key],
		onclick: function(){
			manager.keySets(1);
		},
		parent: view.keymapCanvas
	});
	view.kmButton.push(button);
	key = ($G._get("keySet"))[2];
	button = $.createButton({
		x: 16,
		y: 158,
		width: 96,
		lifeTime: 0,
		text: "3: " + KEYMAP[key],
		onclick: function(){
			manager.keySets(2);
		},
		parent: view.keymapCanvas
	});
	view.kmButton.push(button);
	key = ($G._get("keySet"))[3];
	button = $.createButton({
		x: 16,
		y: 208,
		width: 96,
		lifeTime: 0,
		text: "4: " + KEYMAP[key],
		onclick: function(){
			manager.keySets(3);
		},
		parent: view.keymapCanvas
	});
	view.kmButton.push(button);

	//method
	/**移动函数
	* clickIndex: 第一行中被点的黑块
	* newRow: 新加入的随机行
	*/
	view.moveOn = function(clickIndex, newRow){
		//变色
		var cb = this.grid[1][clickIndex];
		cb.graphics.clear();
		cb.graphics.beginFill(0x808080);
		cb.graphics.drawRect(1,1,this.blockWidth - 2, this.blockHeight - 2);
		cb.graphics.endFill();
		
		//下移动画
		this.grid.push(this.createRowBlock(4, newRow));
		for(var i=0; i<this.grid.length; i++){
			var row = this.grid[i];
			for(var j=0; j<row.length; j++){
				(Tween.to(row[j], {y: row[j].y + view.blockHeight}, 0.1)).play();
			}
		}

		var row0 = this.grid.shift();
		for(var i=0; i<row0.length; i++){
			timer(row0[i].remove, 250);
		}
	};

	view.updateTime = function(t){
		this.timeView.text = t.toFixed(1);
	};

	view.gameOver = function(isWin, param){
//		trace("view.gameOver :[isWin: "+ isWin + ", param: "+param+"]");
		if(isWin){
			this.scoreTitle.text = "本次时间: " + param.time;
			this.bestscoreTitle.text = "最佳时间: "+param.bestTime;
			this.tBoardShow.play();
		}else{
			this.wrongBlink(1, param.wrongLine);
			this.scoreTitle.text = "失败了!";trace("#5 "+param.bestTime);
			this.bestscoreTitle.text = "最佳时间: "+param.bestTime;

			(Tween.delay(this.tBoardShow ,1.2)).play();
//			trace("board show");
		}
	};

	view.wrongBlink = function(r,c){
		//trace("wrongBlock called {r:"+r+",c:"+c+"}");
		this.wrongBlock.x = this.grid[r][c].x;
		this.wrongBlock.y = this.grid[r][c].y;
		//trace(this.grid[r][c].y);
		//trace("wrongBlock has been setted to {x: "+this.wrongBlock.x+",y: "+this.wrongBlock.y+"}");
		this.tWrongBlink.play();
	};

	view.clearBlock = function(){
		while(this.grid.length > 0){
			var arr = this.grid.shift();
			while(arr.length > 0){
				(arr.shift()).remove();
			}
		}
	};

	view.createRowBlock = function(rowIndex, rowArray){
		var arr = [];
		for(var j=0; j<rowArray.length; j++){
			var shape = $.createShape({
				x: view.blockWidth * j,
				y: view.blockHeight * (3-rowIndex),
				lifeTime: 0,
				parent: view.gridCanvas
			});
			arr.push(shape);
			switch(rowArray[j]){
				case BLOCK_START:
					shape.graphics.beginFill(0xffff00);
					break;
				case BLOCK_WHITE:
					shape.graphics.beginFill(0xffffff);
					break;
				case BLOCK_BLACK:
					shape.graphics.beginFill(0x000000);
					break;
			}
			shape.graphics.drawRect(1,1,this.blockWidth - 2, this.blockHeight - 2);
			shape.graphics.endFill();
		}
		return arr;
	};

	view.reset = function(grid){
		this.clearBlock();

		this.blockHeight = $.height / 4;
		this.blockWidth = this.blockHeight / 1.5;

		for(var i=0; i<4; i++){
			this.grid.push(this.createRowBlock(i, grid[i]));
		}

		//调整time位置
		this.timeView.x = this.blockWidth * 2 - 25;
		this.timeView.text = "0.0";
		//调整引导位置
		for(var i=0; i<this.keyGuide.length; i++){
			var c = this.keyGuide[i];
			c.x = this.blockWidth * i + this.blockWidth / 2 - 10;
			c.y = this.blockHeight * 3 - 40;
		}
		//调整游戏结束对话框的位置
		this.gameOverBoard.x = this.blockWidth * 2 - 125;
		this.gameOverBoard.y = this.blockHeight * 2 - 100;
		//调整错误提示砖块的大小
		var g = this.wrongBlock.graphics;
		g.clear();
		g.beginFill(0xff0000);
		g.drawRect(1,1,this.blockWidth - 2, this.blockHeight - 2);
		g.endFill();
		//调整改键区位置
		this.keymapCanvas.x = $.width - 158;
		this.keymapCanvas.y = 100;
	};

	return view;
}

function newManager(){
	ScriptManager.clearTimer();
	ScriptManager.clearEl();
	ScriptManager.clearTrigger();

	var manager = {};

    //视图
	manager.gameView = newView(manager);
trace("#2");
	manager.timeCounter = 0;
	manager.timeStamp;
    manager.timer = interval(function(){
    	//trace(manager.timeCounter.toFixed(1));
    	if(Player.time < manager.timeStamp){
    		manager.timeCounter += Player.time + 10*60*1000 - manager.timeStamp;
    	}else{
    		manager.timeCounter += Player.time - manager.timeStamp;
    	}
    	manager.timeStamp = Player.time;
    	manager.gameView.updateTime(manager.timeCounter / 1000);
    }, 50, 0);
    manager.timer.stop();
    //计数器 50个结束游戏
    manager.blockCounter = 0;
    //状态缓冲 用来改键后返回原来的状态
    manager.flagCache;
    //音效
    manager.sound;

    //method
    //init
    manager.reset = function(){
    	//trace("manager.reset called");
    	this.gameFlag = GAME_IDLE;
    	//trace("this.gameFlag: "+this.gameFlag);
    	this.grid = [[-1,-1,-1,-1]];
    	for (var i = 1; i < 4; i++) {
    		this.grid.push(this._getRandomRow());
    	};

    	//trace(this.grid);
    	this.blockCounter = 0;
    	this.gameView.reset(this.grid);

    	this.timeCounter = 0;

    };

    manager._getRandomRow = function(){
    	var arr = [];
    	var black = Math.floor(Math.random() * 4);
    	for (var j = 0; j < 4; j++) {
    		if(j == black){
    			arr.push(BLOCK_BLACK);
			}else{
				arr.push(BLOCK_WHITE);
			}
    	}
    	return arr;
    };

    manager.gameStart = function(){
    	trace("call gameStart");
    	this.timeStamp = Player.time;
    	this.timer.start();
    	this.keySet = $G._get("keySet");
    	this.sound = $G._("_gal_sound_over");
    	this.gameFlag = GAME_PLAYING;
    };

    manager.gameOver = function(isWin, line){
    	//trace("game over win?"+isWin);
    	this.gameFlag = GAME_OVER;
    	manager.timer.stop();
    	var bestTime = $G._get("bestTime");
    	if(isWin){
    		//最佳时间
    		if(bestTime == undefined || this.timeCounter < bestTime){
    			bestTime = this.timeCounter;
    			$G._set("bestTime", bestTime);
    		}
    		this.gameView.gameOver(true, {time: (this.timeCounter/1000).toFixed(1), bestTime: (bestTime/1000).toFixed(1)});
    	}else{
    		//this.gameView.wrongBlink(1, line);
    		if(bestTime == undefined){
    			bestTime = "无";
    		}else{
    			bestTime = (bestTime/1000).toFixed(1);
    		}
    		this.gameView.gameOver(false, {wrongLine: line, bestTime: bestTime});
    	}
    };

    manager.linePress = function(n){
    	//trace("call linePress");
    	Player.play();
    	var line = this.keySet.indexOf(n);
    	if(this.grid[1][line] == BLOCK_BLACK){
    		this.moveOn(line);
    	}else{
    		this.gameOver(false, line);
    	}
    };

    manager.moveOn = function(i){
    	//trace("call manager.moveOn("+i+")");
    	if(this.sound){
    		this.sound.play();
    	}

    	this.blockCounter ++;
    	if(this.blockCounter >= 50){
    		this.gameOver(true);
    		return;
    	}
    	this.grid.shift();
    	if(this.blockCounter >= 48){
    		this.grid.push([-1,-1,-1,-1]);
    	}else{
    		this.grid.push(this._getRandomRow());
		}

    	//点过的砖块变色
    	//this.grid[0][i] = BLOCK_CLICKED;
    	//ui刷新
    	this.gameView.moveOn(i,this.grid[3]);

    };

    //游戏过程中不允许改键
    manager.keySets = function(index){
    	if(this.gameFlag == GAME_PLAYING || this.gameFlag == KEYSETTING){
    		return;
    	}
    	this.flagCache = this.gameFlag;
    	this.gameFlag = KEYSETTING;
    	this.gameView.kmButton[index].text = (index+1) + ": 按下设置";
    	this.ksIndex = index;
    };

    //改变按键 检查冲突
    manager.keyChange = function(key){
trace("chang index: "+this.ksIndex+" to key: "+key);
    	var ks = $G._get("keySet");
    	var index = this.ksIndex;
    	var k = ks[index];
//trace("ks:"+ks+" k:"+k);
    	if(ks.indexOf(key) != -1 || key == 37 || key == 38 || key == 39 || key == 40){
    		this.gameView.kmButton[index].text = (index+1) + ": " + KEYMAP[k];
    	}else{

    		ks[index] = key;
    		$G._set("keySet",ks);
    		trace("#6 "+ this.ksIndex +":"+ this.gameView.kmButton[index]);

    		this.gameView.kmButton[index].text = (index+1) + ": " + KEYMAP[key];
    	}

    	//恢复状态
    	this.gameFlag = this.flagCache;
    };

    manager._keyTrigger = function(key){
    	trace("you press key "+key);
    	trace("this.gameFlag: "+manager.gameFlag);
    	switch(manager.gameFlag){
    		case GAME_IDLE:
    			manager.gameStart();
    		case GAME_PLAYING:
    			manager.linePress(key);
    			break;

    		case KEYSETTING:
    			manager.keyChange(key);
    			break;
    	}
    };
    Player.keyTrigger(manager._keyTrigger, 2147483647);

    return manager;
}

//main
function main(){
	if($G._get("keySet") == undefined){
		$G._set("keySet",[83,68,35,36]);
	}

	var _gal_sound = Player.createSound("btnover",function(){
		$G._set("_gal_sound_over",_gal_sound);
	});
	
	var gameManager = newManager();
	trace("#1");
	gameManager.reset();
}

//start
main();

//todo 
//声音 
//按键设置 ok
//鼠标点击