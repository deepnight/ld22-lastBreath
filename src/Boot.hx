class Boot extends hxd.App {
	public static var ME : Boot;

	// Boot
	static function main() {
		new Boot();
	}

	// Engine ready
	override function init() {
		ME = this;

		engine.backgroundColor = 0x0;

		#if debug
		//new hxd.net.SceneInspector(s3d);
		#end

		hxd.Timer.wantedFPS = 30;
		// hxd.snd.Manager.get(); // TODO
		hxd.Res.initEmbed();
		Assets.init();
		new dn.heaps.GameFocusHelper(s2d, Assets.font);
		// new Game();
		dn.Process.resizeAll();
	}

	override function onResize() {
		super.onResize();
		dn.Process.resizeAll();
	}

	override function update(dt:Float) {
		super.update(dt);

		var tmod = hxd.Timer.tmod;

		#if debug
		var mul = K.isDown(K.HOME) ? 0.2 : 1.0;
		if( K.isDown(K.END) )
			mul*=5;
		tmod*=mul;
		#end
		Assets.tiles.tmod = tmod;
		dn.Process.updateAll(tmod);
	}
}

