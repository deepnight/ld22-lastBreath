import dn.heaps.slib.*;

class Assets {
	public static var SBANK	= dn.heaps.Sfx.importDirectory("sfx");
	public static var font : h2d.Font;
	public static var tiles : SpriteLib;

	public static function init() {
		if( font!=null )
			throw "init twice";

		font = hxd.Res.alterebroOutline.toFont();

		var t = hxd.Res.tiles.toTile();
		tiles = new SpriteLib([t]);


		tiles.slice("lightRay",0, 0,192, 16*2, 16*7, 2);
		tiles.slice("lightColumn",0, 16*4,192, 16*5, 16*9);
		tiles.slice("lightSource",0, 16*9,192, 16*3, 16*2);
		tiles.slice("lightRadius",0, 16*9,192+16*2, 16*4, 16*4);

		tiles.slice("wall",0, 0,0, 16,16, 4);
		tiles.slice("door",0, 16*4,0, 16,16);
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

		tiles.slice("player",0, 0,16*5, 16,16, 20,5);
		tiles.defineAnim("standing", "0-2(3)");
		// tiles.setAnim("standing", [0,1,2], [3]);

		tiles.defineAnim("walking", "20-27(1)");
		tiles.defineAnim("running", "20,22, 24, 26,27");
		// tiles.setAnim("walking", [20,21,22, 23,24,25, 26,27], [1]);
		// tiles.setAnim("running", [20,22, 24, 26,27], [1]);

		tiles.defineAnim("jumpUp", "40");
		tiles.defineAnim("jumpDown", "41(2),42(99999)");
		tiles.defineAnim("onWall", "43,44,45,44");
		tiles.defineAnim("grab", "46(5),47(5), 46(5),47(5), 46(5),47(5), 48(20), 46(5),47(5), 46(5),47(5)");
		// tiles.setAnim("jumpUp", [40], [1]);
		// tiles.setAnim("jumpDown", [41,42], [2,99999]);
		// tiles.setAnim("onWall", [43,44,45,44], [1]);
		// tiles.setAnim("grab", [46,47, 46,47, 46,47, 48, 46,47, 46,47], [5,5, 5,5, 5,5, 20, 5,5, 5,5]);

		// tiles.slice(0,16*8, 16,16, 7);
		// tiles.setAnim("lie", [20,21,22], [5]);
		// #if debug
		// tiles.setAnim("wakeUp", [62],[180]);
		// #else
		// tiles.setAnim("wakeUp", [66,64,65, 64,65, 64,65, 66,62,63,62,67, 66,20,2], [1,60,20, 1,3, 1,6, 7,20,50,30,100, 10,3,3]);
		// #end
		// tiles.setAnim("lookUp", [2,68], [3,999999]);
		// tiles.setAnim("lookBack", [2,3,2], [10,50,2]);

		// tiles.setGroup("smoke");
		// tiles.slice(0,16*10, 16,16, 6);
		// tiles.setAnim("smoke", [0,1,2,3,4,5], [1]);
		// tiles.setGroup("think");
		// tiles.slice(16*6,16*9, 32,32, 2);
		// tiles.setGroup("shardCounter");
		// tiles.slice(16*10,16*9, 16,16, 2);

		// tiles.setGroup("leo");
		// tiles.slice(0,16*9, 16,16, 1);
		// tiles.setGroup("shard");
		// tiles.slice(16*1,16*9, 16,16, 5);
		// tiles.setAnim("shardAnim", [1,2,3,4, 3,2,1,0], [2,2,1,3, 2,1,2,3]);

		// tiles.setGroup("endSky");
		// tiles.slice(336,0, 16*10, 16*4);
		// tiles.setGroup("endGround");
		// tiles.slice(336,64, 16*10, 16*1);
		// tiles.setGroup("endStreet");
		// tiles.slice(352,80, 16*5, 16*3);
		// tiles.setGroup("endPhoto");
		// tiles.slice(432,80, 16*3, 16*3);
		// tiles.setGroup("endBall");
		// tiles.slice(192,464, 16*3, 16*3, 3);

		// tiles.setGroup("worldMap");
		// tiles.slice(0,336, 16*10, 16*2);
	}

	public static inline function one(arr:Array<?Float->dn.heaps.Sfx>, ?vol=1.0) : dn.heaps.Sfx {
		return arr[ Std.random(arr.length) ](vol);
	}
}