// Wolfram : http://tones.wolfram.com/xid/0442-996-1532-982-3127

import dn.Tweenie;
import dn.heaps.HParticle;

typedef GhostData = {
	x		: Float,
	y		: Float,
	cx		: Float,
	cy		: Float,
	scaleX	: Float,
	frame	: Int,
	room	: Int,
	alpha	: Float,
	death	: Bool,
}

@:publicFields class Cell {
	var kill		: Bool;
	var collide		: Bool;
	var cx			: Int;
	var cy			: Int;
	var sprite		: Null<HSprite>;

	public function new() {
		cx = 0;
		cy = 0;
		collide = false;
		kill = false;
	}
}

@:publicFields class Room {
	var map		: Array<Array<Cell>>;
	var gx		: Int;
	var gy		: Int;
	var wid		: Int;
	var hei		: Int;
	var wall	: Cell;
	var entities: Array<Entity>;

	public function new(w,h, gx,gy) {
		this.gx = gx;
		this.gy = gy;
		entities = new Array();
		wid = w;
		hei = h;
		map = new Array();
		for(x in 0...w) {
			map[x] = new Array();
			for(y in 0...h) {
				var c = new Cell();
				c.cx = x;
				c.cy = y;
				map[x][y] = c;
			}
		}

		wall = new Cell();
		wall.collide = true;
	}

	inline function getId() {
		return gy*1000+gx;
	}

	inline function get(x,y) {
		return
			if( x<0 || x>=wid || y<0 || y>=hei )
				wall;
			else
				map[x][y];
	}
}

class Game extends dn.Process {
	static var GAME_WID = 256;
	static var GAME_HEI = 192;
	static var SCALE = 1;
	static var TITLE = "Last breath";
	static var EXTENDED = true;
	static var MUSIC_VOLUME = 1;
	static var MAIN_VOLUME = 1;
	static var RNAMES = [
		["The pit","Narrow caves","The Great Hall","Temptation","Dead end"],
		["","","Crossroads","Trap","Fallen","Depths"]
	];
	public static var CWID = 16;
	public static var CHEI = CWID;
	public static var ME : Game;
	public static var UPSCALE = 4;
	public static var USE_SCALE2X = false;
	public static var USE_TEXTURE = true;

	var wrapper			: h2d.Layers;
	var tiles			: SpriteLib;
	public var room		: Room;
	var worldMap		: hxd.Pixels;
	var rseed			: dn.Rand;
	var fl_lock			: Bool;
	var fl_lockAll		: Bool;
	var fl_ghost		: Bool;
	var fl_gameOver		: Bool;
	public var phase			: String;
	var breath			: Int;
	var respawn			: {x:Int, y:Int};
	var shield			: Int;
	var keyLocks		: Map<String,Bool>;
	var easy			: Bool;

	var pool : dn.heaps.HParticle.ParticlePool;

	public var player	: Entity;
	var playerLight		: HSprite;
	var ghost			: HSprite;
	var ghostSpeed		: Float;
	var ghostAdvance	: Float;
	var ghostDist		: Int;
	var ghostSfx : Sfx;
	var shardCounter	: h2d.Object;

	var scene			: h2d.Object;
	var platforms		: h2d.Object;
	var bg				: h2d.Object;
	var front			: h2d.Object;
	var top				: h2d.Object;
	var interf			: h2d.Object;
	var popMc			: Null<h2d.Object>;
	var curDialog		: Array<String>;
	var onDialogEnd		: Null<Void->Void>;
	var lastTitle		: Null<h2d.Text>;
	var lastTip			: Null<h2d.Text>;

	var cineMask		: h2d.Object;
	var cine			: h2d.Object;
	var cineUpdate		: Void->Void;

	var roomSprites		: h2d.Object;
	var miscSprites		: h2d.Object;

	var darkness		: h2d.Graphics;
	var lights			: h2d.Object;

	var shards			: Array<String>;
	var maxShards		: Int;
	var flags			: Map<String,Bool>;
	var lastKey			: UInt;
	var history			: Array<GhostData>;
	var historyBase		: Array<GhostData>;


	public function new() {
		super();
		ME = this;

		fl_lock = false;
		breath = 10;
		maxShards = 0;
		keyLocks = new Map();
		ghostSpeed = 0;
		ghostAdvance = 0;
		ghostDist = 100;
		lastKey = -1;
		easy = false;
		fl_ghost = false;
		shield = 0;
		shards = new Array();
		fl_lockAll = false;
		flags = new Map();
		history = new Array();
		historyBase = new Array();
		curDialog = new Array();
		// Particle.WINDX = -0.06; // TODO
		// Particle.WINDY = 0.02;

		// var gradient = new h2d.Object(); // TODO
		// root.addChild(gradient);
		// var g = gradient.graphics;
		// var m = new flash.geom.Matrix();
		// m.createGradientBox(GAME_WID, GAME_HEI, Math.PI/2, 0,50);
		// g.beginGradientFill(flash.display.GradientType.LINEAR, [0x3A4056,0x0A0B0E], [0,1], [0,255], m);
		// g.drawRect(0,0,GAME_WID, GAME_HEI);
		// g.endFill();

		scene = new h2d.Object(root);

		bg = new h2d.Object();
		scene.addChild(bg);
		platforms = new h2d.Object();
		scene.addChild(platforms);
		front = new h2d.Object();
		scene.addChild(front);

		top = new h2d.Object();
		scene.addChild(top);

		interf = new h2d.Object(root);

		darkness = new h2d.Graphics(top);
		darkness.beginFill(0x0,1);
		darkness.drawRect(0,0, 100,100); // TODO proper size

		lights = new h2d.Object();
		top.addChild(lights);
		lights.blendMode = Erase;

		top.blendMode = Alpha;

		// tiles = new SpriteLib(new GfxTiles(0,0) ) ;

		worldMap = tiles.getTile("worldMap").getTexture().capturePixels();
		for( x in 0...worldMap.width )
			for( y in 0...worldMap.height )
				if( worldMap.getPixel(x,y)==0x0042ff )
					maxShards++;
		#if debug trace("found "+maxShards+" shards"); #end

		player = new Entity(this);
		player.cx = 10;
		player.cy = 9;
		player.id = "player";
		player.sprite = tiles.h_get("player");
		player.sprite.setCenterRatio(0.5, 1);
		front.addChild(player.sprite);

		playerLight = tiles.h_get("lightRadius");
		playerLight.alpha = 0.8;
		playerLight.setCenterRatio(0.5,0.6);

		ghost = tiles.h_get("player");
		var ct = new flash.geom.ColorTransform();
		ct.color = 0x0;
		// ghost.filters = [ // TODO
		// 	mt.deepnight.Color.getColorizeMatrixFilter(0x171D24,1,0),
		// 	new flash.filters.GlowFilter(0x293241,0.5, 2,2,10),
		// 	new flash.filters.GlowFilter(0x0,1, 16,16,2),
		// ];
		ghost.visible = false;
		front.addChild(ghost);

		pool = new ParticlePool(Assets.tiles.tile, 512, 30);

		displayRoom(0,0,false);
		player.moveTo(0,0);

		chooseDifficulty();
	}

	override function onResize() {
		super.onResize();

		SCALE = Scaler.bestFit_i(GAME_WID, GAME_HEI);
		darkness.clear();
		darkness.beginFill(0x0,1);
		darkness.drawRect(0,0, GAME_WID, GAME_HEI);
	}

	function chooseDifficulty() {
		function fn() {
			#if debug
			startGame();
			#else
			playIntroCinematic();
			#end
		}
		if( EXTENDED ) {
			front.visible = false;
			scene.visible = false;
			phase = "difficulty";
			dialog(["§Choose difficulty :\n1- Easy\n2- Normal"]);
			onDialogEnd = function() {
				fn();
			}
		}
		else
			fn();
	}

	function startGame() {
		if( cine!=null ) {
			cine.parent.removeChild(cine);
			cineMask.parent.removeChild(cineMask);
			cineUpdate = null;
		}
		updateGhostDist();
		updateShardCounter();
		scene.visible = front.visible = true;

		ghostSfx = Assets.SBANK.shadow();
		ghostSfx.playOnGroup(1, true, 0);

		haxe.Timer.delay(function() {
			var m = Assets.SBANK.theme();
			m.play(true, MUSIC_VOLUME);
		}, 2500);

		fl_lockAll = false;
		fl_ghost = true;
		phase = "intro";
		#if debug
		flags.set("_keyDropped",true);
		//flags.set("_keyPicked",true);
		displayRoom(0,0, false);
		player.moveTo(6,2);
		#else
		displayRoom(0,0, false);
		player.moveTo(6,-1);
		#end
		player.sprite.anim.play("jumpDown", 1);
		fl_lock = true;
		#if !debug
		darkness.alpha = 1;
		#end
		player.onLand = function() {
			// tw.createMs(root.y, root.y+10, TLoopEaseOut, 150); // TODO cam bump
			for( i in 0...20 ) {
				var p = new Particle( 16*4+Std.random(16*5)+1, 16*8-1-Std.random(5) );
				p.drawBox(2,1,0x69a34f, 1);
				p.groupId = "leaf";
				p.dy = -rnd(0,3);
				p.dx = rnd(0,0.7)*rndSign();
				p.gy = 0.02;
				p.frictY = 0.9;
				p.life = 200;
				p.r = Std.random(5)+2;
				p.alpha = rnd(0,0.5)+0.5;
				p.fl_wind = false;
				p.bounds = new flash.geom.Rectangle(16*4,0, 16*5, 16*8);
				p.filters = [ new flash.filters.GlowFilter(0x466F35,1,2,2,1) ];
				front.addChild(p);
			}
			player.sprite.anim.play("wakeUp",1);
			player.onLand = null;
		}
		setSpawn();
		tw.createMs(scene.alpha, 0>1, 1000);
		main(null);
	}

	function onKey(e:flash.events.KeyboardEvent) {
		if( lastKey==e.keyCode )
			return;
		var k = e.keyCode;
		lastKey = k;
		if( phase=="difficulty" ) {
			if( k==K.NUMPAD_1 || k==K.NUMBER_1 || k==97 || k==35 ) {
				easy = true;
				closePop(true);
			}
			if( k==K.NUMPAD_2 || k==K.NUMBER_2 || k==98 || k==40 )
				closePop(true);
		}
		else
			if( k==K.SPACE || k==K.ENTER )
				closePop(true);
		if( phase=="cinematic" && !fl_gameOver && (k==K.C || k==K.S) ) {
			curDialog = new Array();
			closePop();
			startGame();
		}
	}

	inline function setGhostVolume(v:Float) {
		ghostSfx.volume = MAIN_VOLUME*0.1*v;
	}

	function _createEntity(?id:String, x,y, s:HSprite) {
		var i = new Entity(this);
		i.sprite = s;
		i.sprite.setCenterRatio(0.5, 1);
		i.cx = x;
		i.cy = y;
		i.yr =1;
		i.fl_stable = true;
		if( id!=null )
			i.id = id;
		room.entities.push(i);
		return i;
	}
	function createItem(?id:String, x,y, s:HSprite) {
		var i = _createEntity(id,x,y,s);
		i.fl_pick = true;
		miscSprites.addChild(i.sprite);
		return i;
	}
	function createTrigger(?id:String, x,y, s:HSprite) {
		var i = _createEntity(id,x,y,s);
		i.fl_trigger = true;
		roomSprites.addChild(i.sprite);
		var s = tiles.h_get("lightRadius");
		s.setCenterRatio(0.5,0.5);
		s.scaleX = s.scaleY = 0.7;
		s.x = i.cx*CWID+CWID*0.5-2;
		s.y = i.cy*CHEI+CHEI*0.5;
		lights.addChild(s);
		return i;
	}

	function createLight(x,y,?sc=1.0) {
		var s = tiles.h_get("lightRadius");
		s.setCenterRatio(0.5,0.5);
		s.scaleX = s.scaleY = sc;
		s.x = x*CWID+CWID*0.5-2;
		s.y = y*CHEI+CHEI*0.5;
		lights.addChild(s);
		return s;
	}

	function getRoomName() {
		return null;
		return try RNAMES[room.gy][room.gx] catch(e:Dynamic) null;
	}

	function hasShard(rid:Int,x:Int,y:Int) {
		for(s in shards)
			if( s==rid+"_"+x+"_"+y )
				return true;
		return false;
	}

	function redrawRoom() {
		displayRoom(room.gx, room.gy, false);
	}

	function displayRoom(rx,ry, ?fl_showName=true) {
		clearTip();
		if( roomSprites!=null ) {
			miscSprites.parent.removeChild(miscSprites);
			roomSprites.parent.removeChild(roomSprites);
			bg.removeChildren();
			lights.removeChildren();
		}

		if( room!=null ) {
			for(e in room.entities)
				e.destroy();
			room.entities = new Array();
			if( inRoom(0,0) ) {
				for(p in Particle.ALL)
					if( p.groupId=="leaf" ) {
						p.life = 0;
						p.alpha = 0;
					}
			}
		}
		miscSprites = new h2d.Object();
		front.addChild(miscSprites);
		roomSprites = new h2d.Object();
		// roomSprites.filters = [ // TODO
		// 	new flash.filters.DropShadowFilter(1,-90, 0x0,0.6, 2,2,10, 1,true),
		// 	new flash.filters.GlowFilter(0x0,0.6, 2,2,5),
		// ];
		platforms.addChild(roomSprites);
		lights.addChild(playerLight);
		rseed = new dn.Rand(0);
		rseed.initSeed(rx+ry*101 + 2);

		if( rx==0 && ry==0 )
			darkness.alpha = 0.5;
		else
			darkness.alpha = 0.5;

		var old = room;
		room = new Room(16,12, rx,ry);
		for(x in 0...16)
			for(y in 0...12) {
				var c = room.get(x,y);
				var sx = c.cx*CWID;
				var sy = c.cy*CHEI;
				var s = tiles.h_getRandom("wallBg", rseed.random);
				s.x = sx;
				s.y = sy;
				bg.addChild(s);
				switch( worldMap.getPixel(rx*16+x, ry*16+y) ) {
					case 0xFFFFFF : // ray of light
						var s = tiles.h_getRandom("lightRay", rseed.random);
						s.setCenterRatio(0.4,0);
						s.x = sx;
						s.y = sy;
						s.rotation = -20;
						//s.alpha = rnd(0,0.3)+0.7;
						s.scaleY = rseed.rand()*0.3/1000+1;
						s.scaleX = rseed.rand()*0.2+1;
						lights.addChild(s);

					case 0x0042ff : // shard
						if( !hasShard(room.getId(),x,y) ) {
							var i = createItem("shard",x,y, tiles.h_get("shard"));
							i.sprite.anim.play("shardAnim"); // TODO async anims
							// i.sprite.filters = [ // TODO
							// 	new flash.filters.GlowFilter(0xBCFAF3,1, 4,4),
							// 	new flash.filters.GlowFilter(0x1FE9BB,1, 16,16,1)
							// ];
							var s = tiles.h_get("lightRadius");
							s.setCenterRatio(0.5,0.5);
							s.x = sx+6;
							s.y = sy+6;
							lights.addChild(s);
						}

					case 0xff981e : // special item
						if( inRoom(0,0) && !flags.get("_keyPicked") ) {
							createItem("key", x, y+(flags.get("_keyDropped")?2:0), tiles.h_get("key"));
							if( phase!="intro" )
								createLight(x,y);
						}
						if( inRoom(2,0) )
							createTrigger("dropKey", x,y, tiles.h_get("trigger", flags.get("_keyDropped") ? 1:0 ));
					case 0xFFFF00 : // pit
						var s = tiles.h_get("lightColumn");
						s.setCenterRatio(0,0);
						s.x = sx-16;
						s.y = sy;
						lights.addChild(s);
					case 0x707070 : // doors
						if( !(inRoom(2,0) && flags.get("_doorOpened") || inRoom(1,0) && (flags.get("_keyDropped") || flags.get("keytPicked"))) ) {
							c.collide = true;
							var s = tiles.h_get("door");
							s.x = sx;
							s.y = sy;
							roomSprites.addChild(s);
						}
					case 0xaaaaaa : // wall or ground
						c.collide = true;
						var s = tiles.h_getRandom( if( room.get(c.cx,c.cy-1).collide ) "wall" else "ground", rseed.random );
						s.x = sx;
						s.y = sy;
						roomSprites.addChild(s);
					case 0x00ff00 : // grass
						c.collide = true;
						var s = tiles.h_getRandom("grass", rseed.random);
						s.x = sx;
						s.y = sy;
						roomSprites.addChild(s);
					case 0x58d7c6 : // Leo's ghost
						if( flags.exists("comeBackPit") ) {
							var s = tiles.h_get("leo");
							s.setCenterRatio(0.5, 1);
							s.x = sx+8;
							s.y = sy+12;
							s.blendMode = Screen;
							s.scaleX = if( player.cx<x ) -1 else 1;
							// s.filters = [ new flash.filters.GlowFilter(0x1FE9BB,1, 16,16,1) ]; // TODO
							miscSprites.addChild(s);
							if( phase!="intro" ) {
								var s = tiles.h_get("lightRadius");
								s.setCenterRatio(0.5,0.5);
								s.x = sx+6;
								s.y = sy;
								lights.addChild(s);
							}
						}
					case 0xff0000 :
						var s = tiles.h_get("spike", tiles.getRandomFrame("spike", rseed.random));
						s.x = sx;
						s.y = sy;
						c.kill = true;
						miscSprites.addChild(s);
					default :
				}
				if( c.collide && !room.get(c.cx,c.cy-1).collide && rseed.random(100)<50 ) {
					var s = tiles.h_get("props", tiles.getRandomFrame("props", rseed.random));
					s.x = c.cx*CWID;
					s.y = (c.cy-1)*CHEI;
					roomSprites.addChild(s);
				}
				if( c.collide && !room.get(c.cx,c.cy+1).collide && rseed.random(100)<50 ) {
					var s = tiles.h_get("ceilProps", tiles.getRandomFrame("ceilProps", rseed.random));
					s.x = c.cx*CWID;
					s.y = (c.cy+1)*CHEI;
					roomSprites.addChild(s);
				}
			}

		if( inRoom(0,0) ) {
			var s = tiles.h_get("lightSource");
			// s.filters = [ // TODO
			// 	new flash.filters.GlowFilter(0xFFF39D,1, 16,16,2) ,
			// 	new flash.filters.GlowFilter(0xFFAD33,1, 32,32,2) ,
			// 	new flash.filters.GlowFilter(0xFF9900,1, 64,64,1) ,
			// ];
			s.x = 5*16;
			s.y = -20;
			miscSprites.addChild(s);
		}

		if( inRoom(2,0) )
			credit("time", "Made in 48h for the Ludum Dare 22", -1, 150);

		// room name
		var name = getRoomName();
		if( fl_showName && name!=null ) {
			if( lastTitle!=null && lastTitle.parent!=null )
				lastTitle.parent.removeChild(lastTitle);
			var tf = getTextField();
			tf.text = name;
			tf.x = Std.int( GAME_WID*0.5-tf.textWidth*0.5 );
			tf.y = -10;
			tw.createMs(tf.y,0).pixel();
			tf.textColor = 0xF98715;
			// tf.filters = [ // TODO
			// 	new flash.filters.DropShadowFilter(1,90, 0xFCE149,0.6, 0,0,1, 1,true),
			// 	new flash.filters.GlowFilter(0x0,0.5, 2,2,10),
			// ];
			tf.alpha = 0;
			tw.createMs(tf.alpha, 1);
			haxe.Timer.delay(function() {
				if( tf.parent==null )
					return;
				var o = {b:0.0};
				try {
					tw.createMs(tf.y, tf.y-10, TEaseIn, 500);
					tw.createMs(tf.alpha, 0, TEaseIn, 800).onEnd = function() if(tf.parent!=null) tf.parent.removeChild(tf);
					tw.createMs(o.b, 1, TEaseIn, 300).onUpdateT = function(t) {
						// tf.filters = [ new flash.filters.BlurFilter(t*8,t*8) ]; // TODO
					}
				} catch(e:Dynamic) {}
			}, 2000);
			root.addChild(tf);
			lastTitle = tf;
		}
	}

	inline function inRoom(x,y) {
		return room.gx==x && room.gy==y;
	}

	function gotoRoom(dx,dy) {
		if( dx!=0 ) {
			player.cx = if(dx<0) room.wid-1 else 0;
			player.xr = 0.5;
			player.yr = 0.9;
		}
		else {
			player.cy = if(dy<0) room.hei-2 else 1;
			player.yr = if(dy<0) 1 else 0;
		}
		setSpawn();
		displayRoom(room.gx+dx, room.gy+dy);
	}

	function getTextField() {
		var tf = new h2d.Text( Assets.font );
		return tf;
	}

	function tip(k:String, msg:String) {
		if( flags.get("_"+k) )
			return;
		flags.set("_"+k,true);
		clearTip();
		var tf = getTextField();
		root.addChild(tf);
		tf.textColor = 0xffffff;
		tf.scaleX = tf.scaleY = 2;
		tf.text = msg;
		tf.x = w()-tf.textWidth*2-5;
		tf.y = h();
		tw.createMs(tf.y, h()-tf.textHeight*2-5);
		// tf.filters = [ new flash.filters.GlowFilter(0x0,1, 2,2,10) ]; // TODO
		lastTip = tf;
	}


	function credit(k:String, msg:String, xdir, y) {
		if( flags.get("_"+k) )
			return;
		flags.set("_"+k,true);
		var tf = getTextField();
		root.addChild(tf);
		tf.textColor = 0xffffff;
		var sc = 4;
		tf.scaleX = tf.scaleY = sc;
		tf.text = msg;
		if( xdir<0 ) {
			tf.x = 5;
			tw.createMs(tf.x, 20, 3000).pixel();
		}
		else {
			tf.x = w()-tf.textWidth*sc-5;
			tw.createMs(tf.x, w()-tf.textWidth*sc-20, 3000).pixel();
		}
		tf.y = y;
		// tf.filters = [ new flash.filters.GlowFilter(0xffffff,0.5, 8,8,1, 2) ]; // TODO
		tf.alpha = 0;
		tw.createMs(tf.alpha, 0.5, 2000);
		haxe.Timer.delay(function() {
			tw.createMs(tf.alpha, 0, 1000).onEnd = function() tf.remove();
		}, 4000);
	}

	function clearTip() {
		if( lastTip!=null ) {
			var tf = lastTip;
			tw.createMs(tf.alpha,0).onEnd = function() tf.remove();
			lastTip = null;
		}
	}

	function dialog(list:Array<String>) {
		if( phase!="difficulty" )
			tip("skip", "Hit \"SPACE\" or \"ENTER\" to continue.");
		curDialog = curDialog.concat(list);
		pop( curDialog.shift() );
	}

	function closePop(?fl_nextDialog=false) {
		if( popMc!=null ) {
			clearTip();
			var mc = popMc;
			tw.createMs(mc.alpha, 0, 500).onEnd = function() mc.remove();
			popMc = null;
		}
		if( fl_nextDialog ) {
			if( curDialog.length>0 )
				pop( curDialog.shift() );
			else {
				fl_lockAll = false;
				if( onDialogEnd!=null ) {
					var cb = onDialogEnd;
					onDialogEnd = null;
					cb();
				}
			}
		}
	}

	function pop(msg:String) {
		closePop();
		fl_lockAll = true;
		popMc = new h2d.Object();
		interf.addChild(popMc);

		var clean = if(msg.charAt(0)=="*" || msg.charAt(0)=="§") msg.substr(1) else msg;

		var bg = new h2d.Object();
		popMc.addChild(bg);

		var tf = getTextField();
		popMc.addChild(tf);
		tf.textColor = 0xffffff;
		tf.maxWidth = 150;

		tf.text = if( msg.charAt(0)!="§" )  "\""+clean+"\"" else clean;
		tf.maxWidth = tf.textWidth + 5;

		// var g = bg.graphics; // TODO popup bg
		// g.beginFill( if(msg.charAt(0)=="*") 0x891414 else 0x474D78, 1);
		// g.drawRect(0,0, tf.width,tf.height);
		// bg.filters = [
		// 	new flash.filters.GlowFilter(0xFFFFFF,1,2,2,10),
		// 	new flash.filters.DropShadowFilter(3,90, 0x0,1, 4,4),
		// ];

		// popMc.x = Std.int(GAME_WID*0.5-popMc.width*0.5) + Std.random(20)*Lib.sign(); // TODO position
		popMc.y = 15 + Std.random(20);
	}

	function makeRadial(n:Int, x:Float,y:Float, r:Float, speed:Float) {
		var list = new List();
		for(i in 0...30) {
			var a = rnd(0,2*3.14);
			var p = new Particle(x+Math.cos(a)*r, y-3+Math.sin(a)*r);
			p.rotation = a*180/3.14;
			var s = rnd(0,speed) + speed*0.5;
			p.dx = Math.cos(a)*s;
			p.dy = Math.sin(a)*s;
			p.life = 3;
			p.frictX = p.frictY = 1;
			p.fl_wind = false;
			p.gx = 0;
			p.gy = 0;
			list.add(p);
		}
		return list;
	}

	function resetGame() {
		shards = [];
		ghostSpeed = 0;
		ghostAdvance = 0;
		updateGhostDist();
		updateShardCounter();
		for( f in flags.keys() ) {
			if( f.indexOf("_")==0 )
				continue;
			flags.remove(f);
		}
		//flags.set("_shardTuto",true);
		//flags.set("_thinkOfHuman",true);
		//flags.set("_keyPicked",true);
		//flags.set("_keyDropped",true);
		//flags.set("_doorOpened",true);
		//flags.set("_ghostLaunched",true);

		displayRoom(0,0);
		player.moveTo(8,7);
		fl_ghost = true;
		fl_gameOver = false;
		phase = "game";
		history = historyBase.copy();
		fl_lock = false;
		player.fl_grabbing = false;
		player.sprite.alpha = 1;
	}

	function win() {
		//fl_lockAll = true;
		setGhostVolume(0);
		fl_lock = true;
		fl_gameOver = true;
		fl_ghost = false;
		player.dx = 0;
		player.dy = 0;
		player.sprite.anim.play("lookUp");
		shardCounter.visible = false;

		var white = new h2d.Graphics(root);
		white.beginFill(0xffffff,1);
		white.drawRect(0,0,GAME_WID,GAME_HEI);
		white.endFill();
		white.alpha = 0;
		tw.createMs(white.alpha, 1, TEaseIn, #if debug 5000 #else 5000 #end).onEnd = function() {
			scene.visible = false;
			tw.createMs(white.alpha, 0, TEaseOut, #if debug 2000 #else 2000 #end).onEnd = function() white.parent.removeChild(white);
			pool.killAll();
			playEndCinematic();
		}
	}

	function gameOver() {
		fl_lock = true;
		fl_ghost = false;
		fl_gameOver = true;
		setGhostVolume(0);

		Assets.SBANK.hit(1);

		for( p in Particle.makeExplosion(50, player.sprite.x, player.sprite.y, 2,10) ) {
			p.drawBox(1,1, 0xAE0000, rnd(0,0.5)+0.5);
			p.filters = [ new flash.filters.GlowFilter(0xAE0000,1, 2,2) ];
			front.addChild(p);
		}
		tw.createMs(root, "y", root.y-6, TShakeBoth);
		player.sprite.alpha = 0;
		shield = 0;
		for(i in 0...35) {
			var p = new Particle(player.sprite.x+rnd(0,11)*Lib.sign(), player.sprite.y);
			p.drawBox(1, Std.random(10)+1,0xFF1104);
			p.dy = -rnd(0,5)-0.1;
			p.fl_wind = false;
			p.gy = -0.1;
			p.life = Std.random(15)+10;
			//p.life = 20;
			p.filters = [new flash.filters.GlowFilter(0xC11D00,1, 4,4,2)];
			front.addChild(p);
		}

		var o = {t:0.0};
		var a = tw.createMs(o,"t", 1, 3000);
		a.onUpdateT = function(t) {
			// scene.filters = [ // TODO
			// 	mt.deepnight.Color.getColorizeMatrixFilter(0x9D2828,t*0.8, 1-t),
			// 	new flash.filters.BlurFilter(t*2,t*2),
			// ];
		}
		a.onEnd = function() {
			scene.filter = null;
			resetGame();
		}
	}

	function die() {
		if( shield>0 || fl_gameOver )
			return;
		shield = 100;
		setGhostVolume(0);
		for( p in Particle.makeExplosion(50, player.sprite.x, player.sprite.y, 2,5) ) {
			p.drawBox(1,1, 0xAE0000, rnd(0,0.5)+0.5);
			p.filters = [ new flash.filters.GlowFilter(0xAE0000,1, 2,2) ];
			front.addChild(p);
		}
		Assets.SBANK.die(1);
		tw.terminateWithoutCallbacks(player.sprite.alpha);
		root.y+=5;
		tw.createMs(root.y, root.y-5, TElasticEnd, 500);
		tw.createMs(root.x, root.x-5, TShakeBoth, 250);
		player.sprite.alpha = 0;
		//player.fl_grabbing = false;
		player.fl_stable = false;
		player.dx = player.dy = 0;
		fl_lock = true;
		player.fl_grabbing = true;
		if( history.length>0 )
			history[history.length-1].death = true;
		haxe.Timer.delay( function() {
			if( fl_gameOver )
				return;

			tw.createMs(player.sprite, "alpha", 1, TEaseIn, 700);
			player.moveTo(respawn.x, respawn.y);

			for(p in makeRadial(30, player.sprite.x, player.sprite.y, 50, -4)) {
				p.drawBox(Std.random(10)+1,1,0xFF1104);
				p.filters = [new flash.filters.GlowFilter(0xC11D00,1, 4,4,2)];
				front.addChild(p);
			}
			Assets.SBANK.respawn(0.5);

			haxe.Timer.delay(function() {
				if( fl_gameOver )
					return;
				fl_lock = false;
				player.fl_grabbing = false;

				for(p in makeRadial(30, player.sprite.x, player.sprite.y, 4, 1)) {
					p.drawBox(Std.random(5)+1,1,0x56CED8);
					p.filters = [new flash.filters.GlowFilter(0x1D8ECB,1, 4,4,2)];
					front.addChild(p);
				}
			}, 300);
		}, 400);
	}

	function updateGhostDist() {
		var r = 1-shards.length/maxShards;
		if( easy )
			ghostDist = Std.int( 100+r*100 );
		else
			ghostDist = Std.int( 55+r*95 );
	}

	function updateShardCounter() {
		if( shardCounter!=null ) {
			var mc = shardCounter;
			tw.createMs(mc, "alpha", 0, TEaseOut, 1000).onEnd = function() mc.parent.removeChild(mc);
		}
		shardCounter = new h2d.Object();
		interf.addChild(shardCounter);
		shardCounter.visible = phase=="game";
		shardCounter.x = 0;
		shardCounter.y = GAME_HEI-13;
		for(i in 0...maxShards) {
			var on = i<shards.length;
			var s = tiles.h_get("shardCounter", on ? 0 : 1);
			shardCounter.addChild(s);
			s.x = i*8;
			s.alpha = on?1:0.3;
		}
	}

	function onPick(e:Entity) {
		#if debug trace("pick "+e.id); #end
		var defaultParts = true;

		switch( e.id ) {
			case "key" :
				flags.set("_keyPicked",true);
				flags.set("_ghostLaunched",true);
				Assets.SBANK.pickup(0.5);
				fl_lock = true;
				player.sprite.playAnim("standing");
				haxe.Timer.delay(function() {
					fl_lock = false;
					dialog(["As you pick the key, something falls from the ceiling.", "Your shadow.", "His eyes...","*...show nothing but HATRED..."]);
				}, 700);
				//dialog(["Your shadow...","*Your shadow left you. It has been corrupted and now it is after you.","You are alone...","*You need to retrieve the shards!","They contain small fragments of your soul... The remains.", "...Your shadow is coming for YOU...", "*Run!!"]);
				//onDialogEnd = function() {
					fl_ghost = true;
				//}
			case "shard" :
				Assets.SBANK.shard(1);
				for(p in makeRadial(50, e.cx*CWID+CWID*0.5, e.cy*CHEI+CHEI*0.5, 2, 2)) {
					p.drawBox(Std.random(10)+1,1,0xBEF8F0);
					p.life = Std.random(16)+2;
					p.filters = [new flash.filters.GlowFilter(0x1EE6CD,1, 8,8,2)];
					front.addChild(p);
				}
				shards.push(room.getId()+"_"+e.cx+"_"+e.cy);
				updateShardCounter();
				setSpawn();
				if( shards.length==maxShards )
					win();
				updateGhostDist();
				redrawRoom();
				defaultParts = false;
				if( !flags.get("_shardTuto") ) {
					flags.set("_shardTuto",true);
					dialog(["You suddenly feel that the shadow is getting closer behind you...", "*This happens each time you find a red ball.", "To avoid being trapped in a dead end, you shall choose carefully the order in which you pick the Balls..."]);
				}
		}

		if( defaultParts )
			for(i in 0...35) {
				var p = new Particle(e.sprite.x+rnd(0,6)*Lib.sign(), e.sprite.y-rnd(0,5));
				p.drawBox(1, Std.random(3)+1,0xFFAC00);
				p.dy = -rnd(0,1.5)-0.1;
				p.fl_wind = false;
				p.gy = -0.05;
				p.alpha = rnd(0,0.7)+0.3;
				p.life = Std.random(15)+10;
				//p.life = 20;
				p.filters = [new flash.filters.GlowFilter(0xFFAC00,1, 4,4,2)];
				front.addChild(p);
			}

		e.destroy();
		room.entities.remove(e);
	}

	function setSpawn() {
		respawn = {x:player.cx, y:player.cy};
	}


	function onTrigger(e:Entity) {
		#if debug trace("trigger: "+e.id); #end
		switch(e.id) {
			case "dropKey" :
				if( !flags.get("_keyDropped") ) {
					flags.set("_keyDropped",true);
					tw.createMs(root, "y", root.y+5, TLoopEaseOut, 200);
					redrawRoom();
					Assets.SBANK.trigger(1);
					setSpawn();
				}
		}
	}

	function getCineFilters() {
		return [
			//new flash.filters.GlowFilter(0xFFFFFF,0.1, 2,2,10, 1,true),
			//new flash.filters.GlowFilter(0x0,0.5,2,2,10),
			new flash.filters.DropShadowFilter(4,70, 0x0,0.4, 0,0),
		];
	}

	function playEndCinematic() {
		phase = "cinematic";

		cine = new h2d.Object();
		interf.addChild(cine);
		cine.filters = getCineFilters();
		cine.x = Std.int(GAME_WID*0.5 - 10*16*0.5);
		cine.y = 50;

		var sky = tiles.h_get("endSky");
		cine.addChild(sky);

		var loops = new Array();

		//for(i in 0...2) {
			//var s = tiles.h_get("endGround");
			//cine.addChild(s);
			//s.x = i*10*16;
			//s.y = 16*3-3;
			//s.alpha = 0.5;
			//loops.push({spr:s, spd:0.25});
		//}

		var ballCont = new h2d.Object();
		cine.addChild(ballCont);

		var fxCont = new h2d.Object();
		cine.addChild(fxCont);

		for(i in 0...2) {
			var s = tiles.h_get("endGround");
			cine.addChild(s);
			s.x = i*10*16;
			s.y = 16*3;
			loops.push({spr:s, spd:2.0});
		}

		var dog = tiles.h_get("player");
		dog.setCenterRatio(0,0);
		dog.playAnim("walking");
		dog.x = 16*3.5;
		dog.y = 16*2+1;
		cine.addChild(dog);


		var mask = new flash.display.h2d.Object();
		buffer.addChild(mask);
		cineMask = mask;
		mask.graphics.beginFill(0xff0000,0.3);
		mask.graphics.drawRect(0,0,16*10,16*4-1);
		mask.graphics.endFill();
		mask.x = cine.x;
		mask.y = cine.y;
		cine.mask = mask;

		var balls = new Array();
		function addBall() {
			var s = tiles.h_getRandom("endBall");
			ballCont.addChild(s);
			var z = 0.5+rnd(0,0.5);
			//var ct = mt.deepnight.Color.getColorizeCT(0xC45B5B, rnd(0,0.9));
			//s.transform.colorTransform = ct;
			//s.alpha = rnd(0,0.7)+0.3;
			balls.push({
				spr	: s,
				x	: 16*10.0,
				y	: -16.0-Std.random(16),
				dx	: rnd(0,2.5)+1,
				dy	: 0.0,
			});
		}

		var street = tiles.h_get("endStreet");
		buffer.addChild(street);
		street.filters = getCineFilters();
		street.x = 160;
		street.y = 15;
		street.alpha = 0;

		var photo = tiles.h_get("endPhoto");
		buffer.addChild(photo);
		photo.filters = getCineFilters();
		photo.x = 180;
		photo.y = 90;
		photo.alpha = 0;

		var timer = 0;

		var ballCD = 150;

		var dogDy = 0.0;
		var baseY = 16*2+1;


		cineUpdate = function() {
			timer++;
			if( timer==300 ) {
				tw.createMs(street, "alpha", 1, 4000);
				tw.createMs(street, "x", street.x-100, TLinear, 20000).fl_pixel = true;
				haxe.Timer.delay(function() {
					tw.createMs(street, "alpha", 0, 4000);
				}, 7000);
			}
			if( timer==650 ) {
				tw.createMs(photo, "alpha", 1, 4000);
				tw.createMs(photo, "x", photo.x-100, TLinear, 20000).fl_pixel = true;
				haxe.Timer.delay(function() {
					tw.createMs(photo, "alpha", 0, 4000);
				}, 7000);
			}
			if( timer==900 )
				credit("endTitle", "\""+TITLE+"\"", 1, h()-200);
			if( timer==1050 )
				credit("thank", "Thank you for playing =)", 1, h()-170);
			if( timer==1100 )
				tip("url","http://blog.deepnight.net");
			for(l in loops) {
				var s = l.spr;
				s.x -= l.spd;
				if( s.x<=-16*10 )
					s.x += 16*10*loops.length;
			}
			if( ballCD--<=0 ) {
				addBall();
				ballCD = Std.random(75)+15;
			}
			for(b in balls) {
				b.x-=b.dx;
				b.dy+=0.25;
				b.y+=b.dy;
				if(b.y>=4 && b.dy>0) {
					b.dy = -b.dy*1.05;
				}
				b.spr.x = Std.int(b.x);
				b.spr.y = Std.int(b.y);
			}
			for( p in Particle.makeDust(Std.random(2), 16*7+Std.random(16*10), -10) ) {
				p.drawBox(1,2,0x4D1E17, 1);
				p.groupId = "leaf";
				p.life = 300;
				p.r = Std.random(5)+2;
				p.alpha = rnd(0,0.8)+0.2;
				p.bounds = new flash.geom.Rectangle(0,-16, 16*20, 16*4.5);
				fxCont.addChild(p);
			}

			if( !TW.exists(dog,"x") )
				tw.createMs(dog,"x", 16*2+Std.random(16*3), 4000).fl_pixel = true;

			if( Std.random(100)<3 && dogDy==0 && dog.y==baseY ) {
				dog.playAnim("jumpUp");
				dogDy = -2-rnd(0,2);
			}
			if( dogDy>=0 && dog.y<baseY )
				dog.playAnim("jumpDown");
			dog.y+=dogDy;
			dogDy+=0.25;
			if( dog.y>=baseY ) {
				dogDy = 0;
				dog.y = baseY;
				dog.playAnim("walking");
			}
		}
	}

	function thinkOf(s:HSprite) {
		s.setCenterRatio(0.5,0.5);
		s.x = player.sprite.x-8;
		s.y = player.sprite.y-12;
		Assets.SBANK.think(0.2);
		front.addChild(s);
		var a = tw.createMs(s,"alpha", 0, TEaseIn, 4000);
		a.onUpdate = function() {
			s.x = player.sprite.x-8;
			s.y = player.sprite.y-12;
		}
		a.onEnd = function() s.parent.removeChild(s);
	}

	function playIntroCinematic() {
		//tip("Hit \"S\" to skip introduction. It's really short, you don't need that.");
		phase = "cinematic";
		front.visible = false;
		scene.visible = false;
		cine = new h2d.Object();
		interf.addChild(cine);
		cine.x = Std.int( GAME_WID*0.5-16*5*0.5 );
		cine.y = 50;
		cine.filters = getCineFilters();

		var sky = tiles.h_get("iSky");
		cine.addChild(sky);

		var grass = tiles.h_get("iGrass");
		cine.addChild(grass);
		grass.filters = [ new flash.filters.DropShadowFilter(1,-90, 0x0,0.5, 1,1,10)];
		grass.y = 16*2-1;

		var skyRoad = tiles.h_get("iSky",1);
		cine.addChild(skyRoad);
		skyRoad.alpha = 0;

		var car = tiles.h_get("iCar");
		cine.addChild(car);
		car.x = 32;
		car.y = 24;
		car.alpha = 0;

		var road = tiles.h_get("iRoad");
		cine.addChild(road);
		road.alpha = 0;
		road.y = 16*2-1;

		tiles.setAnim("cinematic",
			[60,61,62,	60,61,62,	63,67,62, 0,40,41,42,	0,40,41,42],
			[5,5,5,		5,5,5,		50,10,20, 3,3,3,3,		3,3,3,3]
		);

		var dog = tiles.h_get("player");
		cine.addChild(dog);
		dog.playAnim("cinematic",1);
		dog.x = 16;
		dog.y = 16;

		var mask = new flash.display.h2d.Object();
		buffer.addChild(mask);
		cineMask = mask;
		mask.graphics.beginFill(0xff0000,0.3);
		mask.graphics.drawRect(0,0,16*5,16*3-1);
		mask.graphics.endFill();
		mask.x = cine.x;
		mask.y = cine.y;
		cine.mask = mask;

		var shadow = tiles.h_get("iBall",1);
		cine.addChild(shadow);

		var ball = tiles.h_get("iBall");
		cine.addChild(ball);
		ball.x = -48;
		ball.y = 16;

		flags.set("inGarden",true);

		var ct = new flash.geom.ColorTransform();
		cineUpdate = function() {
			cine.transform.colorTransform = ct;
			shadow.x = ball.x+1;
			shadow.y = 1 + if(flags.get("inGarden")) 16+1 else 16+5;
			shadow.alpha = 1 * (1-Math.min(1,(shadow.y-ball.y)/16));
			if( flags.get("inGarden") ) {
				if( dog.getFrame()==0 )
					flags.set("runBall1",true);
				if( flags.get("runBall1") )
					dog.x+=2;
				if( dog.getFrame()==63 && !flags.get("ballBounce1") ) {
					dialog(["Fluffy!","Catch the ball Fluffy! Catch it! Good dog!"]);
					flags.set("ballBounce1",true);
					onDialogEnd = function() {
						haxe.Timer.delay(()->Assets.SBANK.bump(0.1), 400);
						haxe.Timer.delay(()->Assets.SBANK.bump(0.3), 1300);
						haxe.Timer.delay(()->Assets.SBANK.bump(0.5), 2200);
						haxe.Timer.delay(()->Assets.SBANK.bump(0.3), 3100);
					}
				}
				if( flags.get("ballBounce1") ) {
					ball.x+=1.2;
					ball.y = 16 - Lib.abs( Math.sin(ball.x/(16*0.6))*24 );
				}
				if( Std.random(100)<5 )
					for( p in Particle.makeDust(Std.random(2)+1, Std.random(16*5), -10) ) {
						p.drawBox(2,1,0x69a34f, 1);
						p.groupId = "leaf";
						p.dy = Lib.abs(p.dy);
						p.gy = 0.01;
						p.frictY = 1;
						p.life = 200;
						p.r = Std.random(5)+2;
						p.alpha = rnd(0,0.5)+0.5;
						p.fl_wind = false;
						p.bounds = new flash.geom.Rectangle(0,-16, 16*5, 16*3);
						p.filters = [ new flash.filters.GlowFilter(0x466F35,1,2,2,1) ];
						cine.addChild(p);
					}
				if( dog.x>=16*5 && flags.get("inGarden") ) {
					flags.remove("runBall1");
					flags.remove("ballBounce1");
					flags.remove("inGarden");
					flags.set("onRoad",true);
					var d = 500;
					tw.createMs(road, "alpha", 1, d);
					tw.createMs(skyRoad, "alpha", 1, d);
					dog.x = 3;
					dog.y = 16+5;
					dog.playAnim("standing");
					dog.alpha = 0;
					tw.createMs(dog,"alpha",1, d);
					ball.alpha = 0;
					ball.x = 16*3;
					ball.y = dog.y;
					tw.createMs(ball,"alpha",1, d);
					tw.createMs(ball, "x", 16*3.5, TEaseOut).onEnd = function() {
						flags.set("carArrives",true);
						var d = 2000;
						tw.createMs(car,"alpha",1,TEaseIn, d);
						tw.createMs(car,"x",40,TEaseIn, d).fl_pixel = true;
						var a = tw.createMs(car,"y",16,TEaseIn, d);
						a.fl_pixel = true;
						a.onEnd = function() {
							dog.playAnim("walking");
							tw.createMs(car,"y",1,TLinear, 2000);
							var a = tw.createMs(dog,"x", ball.x-12, TEase, 2000);
							a.fl_pixel = true;
							a.onEnd = function() {
								dog.stopAnim(20);
							}
							haxe.Timer.delay(function() {
								var white = new h2d.Object();
								white.graphics.beginFill(0xffffff,1);
								white.graphics.drawRect(0,0,GAME_WID,GAME_HEI);
								white.graphics.endFill();
								buffer.addChild(white);
								white.alpha = 0;
								tw.createMs(white,"alpha", 1, TEaseIn, 1500).onEnd = function() {
									Assets.SBANK.explode(1);
									cine.visible = false;
									tw.createMs(white,"alpha", 0, TEaseOut, 500).onEnd = function() {
										white.parent.removeChild(white);
											haxe.Timer.delay(startGame, 1500);
									}
								}
							}, 500);
						}
					}
				}
			}
		}

		cineUpdate();
	}


	function main(_) {
		TW.update();

		if( !fl_lockAll ) {
			shield--;

			switch( phase ) {
				case "cinematic" :
					cineUpdate();

				case "intro" :
					if( !player.sprite.hasAnim() ) {
						player.sprite.playAnim("standing");
						tip("basics", "Use LEFT + RIGHT arrows to move.");
						thinkOf( tiles.h_get("think",0) );
						tw.createMs(darkness,"alpha", 0.5, TEaseIn, 2000).onEnd = function() {
							//dialog(["Beware little dog.", "Your shadow...", "You are not alone...", "Grab the soul shards before it reaches you...", "*Your shadow wants YOU.", "It comes...", "*Run for your life! RUN!"]);
							//dialog(["Your soul, little dog..."]);
							var key = room.entities[0];
							var s = createLight(key.cx, key.cy, 0.5);
							s.alpha = 0;
							tw.createMs(s,"alpha",1);
							fl_ghost = false;
							historyBase = history.copy();
							//onDialogEnd = function() {
								//player.sprite.scaleX = -1;
								//player.sprite.playAnim("lookUp");
								//dialog(["*...your soul is decaying.", "Grab the shards.", "Save your soul from oblivion.", "*Or you will stay here, alone, for eternity."]);
								//onDialogEnd = function() {
									player.sprite.playAnim("standing");
									fl_lock = false;
									updateShardCounter();
									phase = "game";
								//}
							//}
						}
					}
			}

			if( inRoom(0,0) && Std.random(100)<5 )
				for( p in Particle.makeDust(2, 16*5+Std.random(16*3), -10) ) {
					p.drawBox(2,1,0x69a34f, 1);
					p.groupId = "leaf";
					p.dy = Lib.abs(p.dy);
					p.gy = 0.01;
					p.frictY = 1;
					p.life = 200;
					p.r = Std.random(5)+2;
					p.alpha = rnd(0,0.5)+0.5;
					p.fl_wind = false;
					p.bounds = new flash.geom.Rectangle(16*2, -16, 16*7, 16*9);
					p.filters = [ new flash.filters.GlowFilter(0x466F35,1,2,2,1) ];
					front.addChild(p);
				}


			for( p in Particle.makeDust(1, Std.random(GAME_WID), Std.random(GAME_HEI)) ) {
				p.drawBox(1,1,0x298F85, rnd(0,0.3)+0.1);
				p.life = 100;
				p.bounds = buffer.getRect();
				p.filters = [new flash.filters.GlowFilter(0x26596C,1, 2,2, 2) ];
				front.addChild(p);
			}

			if( !fl_lock && popMc==null ) {
				if( Key.isDown(Keyboard.UP) && player.jumpJIT>0 && !keyLocks.get("up") ) {
					var n = if(player.fl_grabbing) Std.random(4)+3 else Std.random(4)+1;
					for( i in 0...n ) {
						var p = new Particle(player.sprite.x+rnd(0,4)*Lib.sign(), player.sprite.y-rnd(0,2)*Lib.sign());
						p.drawBox(1,1, 0xC5CBDA, rnd(0,0.7)+0.3);
						p.fl_wind = false;
						if ( player.fl_grabbing ) {
							p.dx = -rnd(0,2.5)*player.sprite.scaleX;
							p.dy = -rnd(0,1)-0.2;
						}
						else {
							p.dx = rnd(0,0.5)*player.sprite.scaleX;
							p.dy = -rnd(0,1);
							p.gy = 0;
						}
						p.life = Std.random(4);
						front.addChild(p);
					}

					switch(Std.random(2)) {
						case 0 : Assets.SBANK.jump2(0.3);
						case 1 : Assets.SBANK.jump3(0.3);
					}

					player.jump(-0.4);
					player.dy = -0.4;
					player.sprite.playAnim("jumpUp");
					keyLocks.set("up",true);
				}
				if( !Key.isDown(Keyboard.UP) )
					keyLocks.remove("up");
				if( Key.isDown(Keyboard.DOWN) && player.fl_grabbing ) {
					player.jump(-0.2);
				}
				var spd = 0.04;
				if( Key.isDown(Keyboard.LEFT) && !player.fl_grabbing ) {
					player.sprite.scaleX = -1;
					player.dx-=spd;
					if( player.fl_stable )
						if( room.get(player.cx-1, player.cy).collide && Lib.abs(player.dx)<0.05 )
							player.sprite.playAnim("onWall");
						else
							player.sprite.playAnim("walking");
					if( player.canGrab(-1) && !Key.isDown(Keyboard.DOWN) ) {
						player.grab(-1);
						player.sprite.playAnim("grab");
					}
				}

				if( Key.isDown(Keyboard.RIGHT) && !player.fl_grabbing ) {
					player.sprite.scaleX = 1;
					player.dx+=spd;
					if( player.fl_stable )
						if( room.get(player.cx+1, player.cy).collide && Lib.abs(player.dx)<0.05 )
							player.sprite.playAnim("onWall");
						else
							player.sprite.playAnim("walking");
					if( player.canGrab(1) && !Key.isDown(Keyboard.DOWN)  ) {
						player.grab(1);
						player.sprite.playAnim("grab");
					}
				}

				if( !player.fl_grabbing  ) {
					if( player.fl_stable && !Key.isDown(Keyboard.LEFT) && !Key.isDown(Keyboard.RIGHT)  )
						player.sprite.playAnim("standing");

					if( !player.fl_stable && player.dy>=0 )
						player.sprite.playAnim("jumpDown");
				}

				if( player.cy==0 && !inRoom(0,0) )
					gotoRoom(0,-1);
				if( player.cy==room.hei-1 && player.yr>0.7 )
					gotoRoom(0,1);
				if( player.cx==0 && player.xr<0.5 )
					gotoRoom(-1,0);
				if( player.cx==room.wid-1  && player.xr>0.5 )
					gotoRoom(1,0);
				#if debug
				if( !fl_gameOver ) {
					if( Key.isDown(Keyboard.R) )
						gameOver();
					if( Key.isDown(Keyboard.W) )
						win();
				}
				#end
			}

			DSprite.updateAll();
			Particle.update();
			for(e in room.entities) {
				e.update();
				if( e.sprite!=null ) {
					var d = Lib.distanceSqr(e.sprite.x,e.sprite.y, player.sprite.x,player.sprite.y);
					if( d<=30 && Math.sqrt(d)<=8 ) {
						if( e.fl_trigger )
							onTrigger(e);
						if( e.fl_pick )
							onPick(e);
					}
				}
			}
			player.update();

			if( shield>0 )
				player.sprite.visible = !player.sprite.visible;
			else
				player.sprite.visible = true;

			if( !fl_lock && player.yr>=0.8 && !player.fl_grabbing && room.get(player.cx, player.cy).kill )
				die();

			if( inRoom(1,0) && player.cy>=9 )
				credit("title", "\""+TITLE+"\"", -1, 80);
			if( inRoom(2,0) && player.cy<=3 && player.cx>=8 )
				credit("theme", "Theme : \" Alone \"", 1, 100);

			if( phase=="game" && breath--<0 ) {
				breath = 40+Std.random(10);
				var s = tiles.h_get("smoke");
				s.setCenterRatio(0.5,1);
				s.playAnim("smoke",1);
				s.alpha = 0.2;
				s.scaleX = player.sprite.scaleX;
				s.fl_killOnEndPlay = true;
				s.x = player.sprite.x + 9*player.sprite.scaleX + player.dx*3;
				s.y = player.sprite.y;
				front.addChild(s);
			}

			if( inRoom(2,0) && player.cx==room.wid-2 && flags.get("_keyPicked") && !flags.get("_doorOpened") ) {
				flags.set("_doorOpened",true);
				redrawRoom();
			}

			if( inRoom(1,0) && player.cy>=6 )
				credit("author", "A game by deepnight", 1, h()-150);
			if( inRoom(1,0) && player.cx>=2 && !flags.get("_thinkOfHuman") ) {
				thinkOf( tiles.h_get("think",1) );
				flags.set("_thinkOfHuman",true);
				fl_lock = true;
				player.sprite.playAnim("lookBack",1);
				haxe.Timer.delay(function() {
					fl_lock = false;
				},1500);
			}

			if( inRoom(0,0) && player.cx>=9 )
				tip("jump", "Use UP to jump. Use UP+LEFT or UP+RIGHT to grab corners.");

			playerLight.x = player.sprite.x;
			playerLight.y = player.sprite.y;

			if( !fl_ghost )
				ghost.visible = false;
			else {
				history.push({
					x		: player.sprite.x,
					y		: player.sprite.y,
					cx		: player.sprite.centerX,
					cy		: player.sprite.centerY,
					scaleX	: player.sprite.scaleX,
					frame	: player.sprite.getFrame(),
					alpha	: player.sprite.alpha,
					room	: room.getId(),
					death	: false,
				});

				// ghost
				if( phase=="game" ) {
					var boost = if( history.length>ghostDist ) 0.4 else 0;
					ghostAdvance += 1+boost;
					while( ghostAdvance>1 ) {
						ghostAdvance--;
						if( history.length>0 ) {
							var h = history[0];
							var d = Lib.distance(ghost.x, ghost.y, h.x, h.y);
							if( ghost.visible && d>=10 && d<50 ) {
								ghost.x += (h.x-ghost.x)/20;
								ghost.y += (h.y-ghost.y)/20;
							}
							else {
								ghost.x = h.x;
								ghost.y = h.y;
								ghost.setCenterRatio(h.cx, h.cy);
								ghost.setFrame(h.frame);
								ghost.scaleX = h.scaleX;
								ghost.visible = h.room==room.getId();
								ghost.alpha = h.alpha;
								if( h.death && ghost.visible && !inRoom(0,0)) {
									for( p in Particle.makeExplosion(20, ghost.x, ghost.y, 2,5) ) {
										p.drawBox(1,1, 0x6F497C, rnd(0,0.5)+0.5);
										p.filters = [ new flash.filters.GlowFilter(0x753966,1, 2,2) ];
										front.addChild(p);
									}
								}
								history.shift();
							}
						}
					}

					var v = if( ghost.visible )
						Math.min(1, Math.max(0, 1-M.dist(player.sprite.x,player.sprite.y, ghost.x,ghost.y)/100));
					else
						0;
					setGhostVolume(v);

					if( ghost.visible && M.dist(ghost.x,ghost.y, player.sprite.x, player.sprite.y)<=6 )
						gameOver();
				}
			}

			#if debug
			debug.custom.text = "d="+ghostDist+"/h="+history.length;
			#end
		}
		pool.update(tmod);
	}
}
