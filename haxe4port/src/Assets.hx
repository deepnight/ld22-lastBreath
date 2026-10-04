import dn.heaps.slib.*;

typedef SoundBank = {
	var bump : ?Float->Sfx;
	var die : ?Float->Sfx;
	var explode : ?Float->Sfx;
	var fallLand : ?Float->Sfx;
	var grab : ?Float->Sfx;
	var hit : ?Float->Sfx;
	var jump2 : ?Float->Sfx;
	var jump3 : ?Float->Sfx;
	var land : ?Float->Sfx;
	var pickup : ?Float->Sfx;
	var respawn : ?Float->Sfx;
	var shadow : ?Float->Sfx;
	var shard : ?Float->Sfx;
	var theme : ?Float->Sfx;
	var think : ?Float->Sfx;
	var trigger : ?Float->Sfx;
}

class Assets {
	public static var SBANK : SoundBank;
	public static var font : h2d.Font;
	public static var tiles : SpriteLib;

	public static function init() {
		if( font!=null )
			throw "init twice";

		font = hxd.Res.font.toFont();
		var sounds = dn.heaps.assets.SfxDirectory.load("sfx",true);
		SBANK = sounds;

		var t = hxd.Res.tiles.toTile();
		t.getTexture().filter = Nearest;
		tiles = new SpriteLib([t]);
		tiles.tmod = 0;


		tiles.slice("lightRay",0, 0,192, 16*2, 16*7, 2);
		tiles.slice("lightColumn",0, 16*4,192, 16*5, 16*9);
		tiles.slice("lightSource",0, 16*9,192, 16*3, 16*2);
		tiles.slice("lightRadius",0, 16*9,192+16*2, 16*4, 16*4);

		tiles.slice("wall",0, 0,0, 16,16, 4);
		tiles.slice("door",0, 16*4,0, 16,16);
		tiles.slice("doorLock",0, 16*10,0, 16,16);
		tiles.slice("ground",0, 0,16*1, 16,16, 2);
		tiles.slice("spike",0, 16*5,16*1, 16,16, 1);
		tiles.slice("wallBg",0,16*6,16*1, 16,16, 4);
		tiles.slice("grass",0, 16*2,16*1, 16,16, 3);
		tiles.slice("props",0, 0,16*2, 16,16, 11);
		tiles.slice("ceilProps",0, 0,16*3, 16,16, 5);

		tiles.slice("trigger",0, 16*10,16*1, 16,16, 2);
		tiles.slice("key",0, 16*12,16*1, 16,16, 1);

		tiles.slice("iGrass",0, 0,16*26, 16*5,16);
		tiles.slice("iRoad",0, 16*5,16*26, 16*5,16);
		tiles.slice("iCar",0, 16*10,16*26, 16*2,16*2);
		tiles.slice("iBall",0, 16*12,16*26, 16,16, 2);
		tiles.slice("iSky",0, 0,16*27, 16*5,16*2, 2);

		tiles.setSliceGrid(16,16);
		tiles.slice("player",0,0,80,16,16,20,5);
		dogAnim("standing",[0,1,2],[3]);
		dogAnim("walking",[20,21,22,23,24,25,26,27],[1]);
		dogAnim("running",[20,22,24,26,27],[1]);
		dogAnim("jumpUp",[40],[1]);
		dogAnim("jumpDown",[41,42],[2,99999]);
		dogAnim("onWall",[43,44,45,44],[1]);
		dogAnim("grab",[46,47,46,47,46,47,48,46,47,46,47],[5,5,5,5,5,5,20,5,5,5,5]);
		dogAnim("lie",[60,61,62],[5]);
		dogAnim("wakeUp",[66,64,65,64,65,64,65,66,62,63,62,67,66,20,2],[1,60,20,1,3,1,6,7,20,50,30,100,10,3,3]);
		dogAnim("lookUp",[2,68],[3,999999]);
		dogAnim("lookBack",[2,3,2],[10,50,2]);
		dogAnim("cinematic",[60,61,62,60,61,62,63,67,62,0,40,41,42,0,40,41,42],[5,5,5,5,5,5,50,10,20,3,3,3,3,3,3,3,3]);

		tiles.sliceAnimGrid("smoke",0,  2,  0,10,  6);
		tiles.slice("think",0,  6*16,9*16, 32,32,  2);
		tiles.sliceGrid("shardCounter",0,  10,9, 2);

		tiles.sliceGrid("leo",0,  0,9);

		tiles.sliceGrid("shard",0,  1,9, 5);
		tiles.sliceGrid("shardAnim",0,  1,9, 5);
		tiles.defineAnim("shardAnim", "1(3), 2(2), 3(1),  4(1),  3(1), 2(2), 1(3), 0(4)");

		tiles.slice("endSky",0,  336,0, 16*10, 16*4);
		tiles.slice("endGround",0,  336,64, 16*10, 16*1);
		tiles.slice("endStreet",0,  352,80, 16*5, 16*3);
		tiles.slice("endPhoto",0,  432,80, 16*3, 16*3);
		tiles.slice("endBall",0,  192,464, 16*3, 16*3,  3);
		tiles.slice("worldMap",0,  0,336, 16*10, 16*2);
	}

	static var dogAnims : Map<String,Bool> = [];
	public static function dogAnim(id:String, frames:Array<Int>, durations:Array<Int>) {
		var g = tiles.createGroup(id);
		g.frames = tiles.getGroup("player").frames.copy();
		var sequence = [];
		for( i in 0...frames.length )
			// The original DSprite advances when its counter is > duration.
			for( tick in 0...durations[M.imin(i,durations.length-1)]+1 ) sequence.push(frames[i]);
		tiles.__defineAnim(id,sequence);
		dogAnims[id] = true;
	}
	public static inline function isDogAnim(id:String) return dogAnims.exists(id);
	public static inline function sprite(id:String, frame=0) return new Sprite(tiles,id,frame);
	public static inline function randomSprite(id:String, ?random:Int->Int) return sprite(id,tiles.getRandomFrame(id,random));
}
