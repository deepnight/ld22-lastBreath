class Boot extends hxd.App {
	public static inline var UI_WID = 1024;
	public static inline var UI_HEI = 768;
	public static var ME : Boot;
	public var game : Game;
	public var gameScene : h2d.Scene;
	public var uiRoot : h2d.Object;
	var viewport : h2d.Mask;
	var focus : dn.heaps.GameFocusHelper;
	var frame : h3d.mat.Texture;
	var display : h2d.Bitmap;
	var mosaic : render.Mosaic;
	var elapsed = 0.;

	static function main() {
		hxd.Timer.wantedFPS = 30;
		hxd.Res.initEmbed();
		new Boot();
	}

	override function init() {
		ME = this;
		engine.backgroundColor = 0xFF161821;
		Assets.init();
		#if js
		// Register autoplay-unlock hooks before the first click/key, not after the music delay.
		hxd.snd.webaudio.Context.get();
		#end
		gameScene = new h2d.Scene();
		gameScene.scaleMode = Fixed(256,192,1,Left,Top);
		gameScene.defaultSmooth = false;
		frame = new h3d.mat.Texture(256,192,[Target]);
		frame.filter = Nearest;
		display = new h2d.Bitmap(h2d.Tile.fromTexture(frame),s2d);
		display.smooth = false;
		mosaic = new render.Mosaic();
		display.filter = mosaic;
		viewport = new h2d.Mask(UI_WID,UI_HEI,s2d);
		uiRoot = new h2d.Object(viewport);
		game = new Game();
		resizeDisplay();
		focus = new dn.heaps.GameFocusHelper(s2d,Assets.font);
		viewport.addChild(focus.root);
		resizeDisplay();
	}

	function resizeDisplay() {
		if( display==null ) return;
		var scale = M.fmin(Game.UPSCALE,dn.heaps.Scaler.bestFit_f(256,192,engine.width,engine.height,true));
		if(scale>=1)scale=Math.floor(scale);
		display.setScale(scale);
		display.x = Math.floor((engine.width-256*scale)*0.5);
		display.y = Math.floor((engine.height-192*scale)*0.5);
		mosaic.resize(M.imax(1,Std.int(scale)),Std.int(256*scale),Std.int(192*scale));
		viewport.x=display.x;viewport.y=display.y;
		viewport.width=Std.int(256*scale);viewport.height=Std.int(192*scale);
		uiRoot.setScale(scale/4);
		if(focus!=null){focus.root.x=-display.x;focus.root.y=-display.y;}
	}

	override function onResize() {
		super.onResize();
		resizeDisplay();
		dn.Process.resizeAll();
	}

	override function update(dt:Float) {
		elapsed = Math.min(dt,0.1);
		dn.Process.updateAll(elapsed*30);
	}

	override function render(e:h3d.Engine) {
		gameScene.syncOnly(elapsed);
		frame.clear(0xFF161821,1);
		@:privateAccess gameScene.ctx.begin();
		game.root.drawTo(frame);
		@:privateAccess gameScene.ctx.end();
		s2d.render(e);
	}
}
