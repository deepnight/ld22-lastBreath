package mt.deepnight;

import flash.display.BitmapData;

class DSprite extends flash.display.Sprite {
	static var ALL : List<DSprite> = new List();
	
	public var lib		: SpriteLib;
	public var libGroup	: Null<String>;
	public var frame	: Int;
	var pt0				: flash.geom.Point;
	public var centerX	: Float;
	public var centerY	: Float;
	
	var animStep		: Int;
	var animCpt			: Int;
	var animId			: Null<String>;
	var anim			: Null<SpriteAnimation>;
	var animPlays		: Int;
	public var fl_killOnEndPlay	: Bool;
	public var useCache	: Bool; // activation auto du cacheAsBitmap ?
	
	var fl_update		: Bool;
	
	public function new(l:SpriteLib, ?g:String, ?frame=0) {
		super();
		lib = l;
		libGroup = g;
		centerX = lib.defaultCenterX;
		centerY = lib.defaultCenterY;
		animCpt = 0;
		fl_killOnEndPlay = false;
		pt0 = new flash.geom.Point(0, 0);
		useCache = true;
		cacheAsBitmap = true;
		setFrame(frame);
	}
	
	public override function toString() {
		return "DSprite "+libGroup+"["+frame+"]";
	}
	
	public inline function setFrame(f) {
		frame = f;
		redraw();
	}
	
	public inline function setCenter(cx,cy) {
		centerX = cx;
		centerY = cy;
		redraw();
	}
	
	public inline function redraw() {
		graphics.clear();
		if(libGroup!=null) {
			lib.drawIntoGraphics(graphics, libGroup, frame, centerX, centerY);
			graphics.endFill();
		}
	}
	
	public inline function getFrame() {
		return frame;
	}
	
	inline function startUpdates() {
		if(!fl_update)
			ALL.push(this);
		fl_update = true;
		cacheAsBitmap = false;
	}
	inline function stopUpdates() {
		if(fl_update)
			ALL.remove(this);
		fl_update = false;
		if (useCache)
			cacheAsBitmap = true;
	}
	
	inline function destroy() {
		if(parent!=null)
			parent.removeChild(this);
		stopUpdates();
	}
	
	public function stopAnim(frame:Int) {
		anim = null;
		animId = null;
		setFrame(frame);
		stopUpdates();
	}
	
	public function playAnim(id:String, ?plays=999999) {
		if(id==animId)
			return;
		animId = id;
		animCpt = 0;
		animStep = 0;
		animPlays = plays;
		anim = lib.getAnim(id);
		startUpdates();
		setFrame(anim.frames[0]);
	}
	
	public inline function hasAnim() {
		return animId!=null;
	}
	
	public function nextAnimFrame() {
		animCpt = 9999999;
		update();
	}
	
	function update() { // requis seulement en cas d'anim
		if(anim==null || parent==null)
			return;
		animCpt++;
		var duration = animStep<anim.durations.length ? anim.durations[animStep] : anim.durations[anim.durations.length-1];
		if(animCpt>duration) {
			animCpt=0;
			if(animStep+1>=anim.frames.length) {
				animStep = 0;
				animPlays--;
				if(animPlays<=0)
					if(fl_killOnEndPlay)
						destroy();
					else
						stopAnim(0);
				else
					setFrame(anim.frames[0]);
			}
			else {
				animStep++;
				setFrame(anim.frames[animStep]);
			}
		}
	}
	
	
	public static function updateAll() {
		var all = ALL;
		for(s in all)
			s.update();
	}
	
	//public function fastDraw(bd:BitmapData, x:Int, y:Int) {
		//bd.copyPixels(lib.bmp, libRect, new flash.geom.Point(x,y), true);
	//}
}

typedef SpriteAnimation = {frames:Array<Int>, durations:Array<Int>};

class SpriteLib {
	public var bmp				: BitmapData;
	var groups					: Hash<Array<flash.geom.Rectangle>>;
	var anims					: Hash<SpriteAnimation>;
	var lastGroup				: Null<String>;
	var frameRandDraw			: Hash<Array<Int>>;
	public var defaultCenterX	: Float;
	public var defaultCenterY	: Float;
	
	public function new(bd:BitmapData) {
		bmp = bd;
		groups = new Hash();
		anims = new Hash();
		frameRandDraw = new Hash();
		lastGroup = null;
		defaultCenterX = 0.5;
		defaultCenterY = 1;
	}
	
	public function setCenter(cx,cy) {
		defaultCenterX = cx;
		defaultCenterY = cy;
	}
	
	public inline function getGroup(?k:String) {
		if(k==null) {
			k = lastGroup;
			if(lastGroup==null)
				throw "No group selected previously";
		}
		return
			if(groups.exists(k))
				groups.get(k);
			else
				throw "Unknown group "+k;
	}
	
	public inline function getGroups() {
		return groups;
	}
	
	public inline function getAnim(id) {
		return anims.get(id);
	}
	
	public inline function setGroup(k:String) {
		lastGroup = k;
		if(!groups.exists(k))
			groups.set(k, new Array());
	}
	
	public function setAnim(animId:String, frames:Array<Int>, durations:Array<Int>) {
		anims.set(animId, {
			frames		: frames.copy(),
			durations	: durations.copy(),
		});
	}
	
	public inline function setWeights(?k:String, weights:Array<Int>) {
		if(k==null)
			k = lastGroup;
		if(!frameRandDraw.exists(k))
			frameRandDraw.set(k, new Array());
		
		var a = frameRandDraw.get(k);
		for(f in 0...weights.length)
			for(i in 0...weights[f])
				a.push(f);
	}
	
	public inline function getRectangle(k:String, idx:Int) {
		return getGroup(k)[idx];
	}
	
	public inline function getRandomFrame(k:String, ?randFunc:Int->Int) {
		if(randFunc==null)
			randFunc = Std.random;
		return
			if(frameRandDraw.exists(k)) {
				var a = frameRandDraw.get(k);
				a[ randFunc(a.length) ];
			}
			else
				randFunc(countFrames(k));
	}
	
	public inline function countFrames(k:String) {
		return getGroup(k).length;
	}
	
	public inline function getSprite(k:String, ?frame=0) : DSprite {
		return new DSprite(this, k, frame);
	}
	
	public inline function getSpriteRandom(k:String, ?randFunc:Int->Int) : DSprite {
		return getSprite(k, getRandomFrame(k, randFunc));
	}
	
	public inline function getMC(k:String, ?frame=0, ?centerX, ?centerY) : flash.display.MovieClip {
		var mc = new flash.display.MovieClip();
		drawIntoGraphics(mc.graphics, k, frame, centerX, centerY);
		return mc;
	}
	
	public inline function drawIntoGraphics(g:flash.display.Graphics, k:String, ?frame=0, ?centerX, ?centerY) {
		if(centerX==null)	centerX = defaultCenterX;
		if(centerY==null)	centerY = defaultCenterY;
		var rect = getRectangle(k, frame);
		var m = new flash.geom.Matrix();
		m.translate(Std.int(-rect.x - centerX*rect.width), Std.int(-rect.y - centerY*rect.height));
		g.beginBitmapFill(bmp, m, false, false);
		g.drawRect(Std.int(-centerX*rect.width), Std.int(-centerY*rect.height), rect.width, rect.height);
		g.endFill();
	}
	
	public inline function drawIntoBitmap(bd:flash.display.BitmapData, x:Int,y:Int, k:String, ?frame=0, ?centerX, ?centerY) {
		if(centerX==null)	centerX = defaultCenterX;
		if(centerY==null)	centerY = defaultCenterY;
		var r = getRectangle(k, frame);
		bd.copyPixels(
			bmp, r,
			new flash.geom.Point(x-Std.int(r.width*centerX), y-Std.int(r.height*centerY)),
			true
		);
	}
	
	public inline function paintIntoBitmap(k:String, ?idx:Null<Int>=0, bd:BitmapData, pt:flash.geom.Point) {
		bd.copyPixels( bmp, getGroup(k)[idx], pt, true );
	}
	
	public function slice(x:Int, y:Int, w:Int, h:Int, ?repeatX=1, ?repeatY=1) {
		var g = getGroup();
		for(iy in 0...repeatY)
			for(ix in 0...repeatX)
				g.push( new flash.geom.Rectangle(x+ix*w, y+iy*h, w, h) );
	}
	
	public function sliceWithMultipleKeys(keys:Array<String>, x:Int, y:Int, w:Int, h:Int, ?repeatX=1, ?repeatY=1) {
		if(keys.length!=repeatX*repeatY)
			throw "Invalid number of keys";
		for(iy in 0...repeatY)
			for(ix in 0...repeatX) {
				var k = keys.shift();
				setGroup(k);
				getGroup().push( new flash.geom.Rectangle(x+ix*w, y+iy*h, w, h) );
			}
	}
}

