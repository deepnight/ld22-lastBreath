import dn.heaps.slib.*;

class Assets {
	public static var SBANK = dn.heaps.assets.SfxDirectory.load("sfx");
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

		tiles.setSliceGrid(16,16);
		tiles.sliceAnimGrid("standing",0,  3,  0,5, 3);
		tiles.sliceAnimGrid("walking",0,  3,  0,6, 8);
		tiles.sliceAnimGrid("jumpUp",0,  1,  0,7, 1);
		tiles.sliceAnimGrid("lie",0, 5,  0,8, 3);

		tiles.sliceAnimGrid("lookUp",0, 3,  8,8, 2);
		tiles.defineAnim("lookUp", "0(3), 1(999)");

		tiles.sliceAnimGrid("lookBack",0, 3,  2,5, 2);
		tiles.defineAnim("lookBack", "0(10), 1(50), 0(2)");

		tiles.sliceGrid("running",0,  0,6, 8);
		tiles.defineAnim("running", "0(2),2,4(2),6,7(2)");

		tiles.sliceGrid("jumpDown",0,  1,7, 2);
		tiles.defineAnim("jumpDown", "0(2),1(9999)");

		tiles.sliceAnimGrid("onWall",0, 1,  3,7, 3);
		tiles.defineAnim("onWall", "0(2),1(2),2(2),1(2)");

		tiles.sliceAnimGrid("grab",0, 1,  6,7, 3);
		tiles.defineAnim("grab", "0(5), 1(5),   0(5), 1(5),   0(5), 1(5),  2(20),   0(5), 1(5),   0(5), 1(5)");

		tiles.sliceAnimGrid("wakeUp",0, 1,  0,8, 9);
		tiles.defineAnim("wakeUp", "6, 4(60), 5(20), 4, 5(3), 4, 5(6),  6(7), 2(20), 3(50), 2(30), 7(100), 2(2), 6(10), 8(999)");

		tiles.sliceAnimGrid("smoke",0,  1,  0,10,  6);
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

	public static inline function one(arr:Array<?Float->dn.heaps.Sfx>, ?vol=1.0) : dn.heaps.Sfx {
		return arr[ Std.random(arr.length) ](vol);
	}
}