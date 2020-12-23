package mt.deepnight;
import mt.deepnight.Types;

class Buffer {
	// **** à ajouter à la display list
	public var render(default,null)	: SPR;
	
	// **** à ajouter AUSSI à la display list (mais en visible=false) UNIQUEMENT en cas d'utilisation du registerButton()
	public var container			: SPR;

	public var width(default,null)		: Int;
	public var height(default,null)		: Int;
	public var upscale(default,null)	: Float;
	
	public var graphics		: flash.display.Graphics;
	public var dm			: mt.DepthManager;
	public var rect(getRect, never)	: flash.geom.Rectangle;
	var pt0					: flash.geom.Point;

	var bdCont				: SPR;
	var renderBD			: BD;
	public var texture		: Null<flash.display.Bitmap>;
	public var postFilters	: Array<flash.filters.BitmapFilter>;
	public var preFilters	: Array<flash.filters.BitmapFilter>;
	var buttons				: List<{clone:SPR, original:flash.display.DisplayObject}>;
	
	public var fl_transparent(default,null)		: Bool;
	public var bgColor(default,null)			: UInt;
	public var fl_scale2x(default,null)			: Bool;
	
	public var alphaLoss	: Float;
	
	public var onRender		: Null< Void->Void >;
	
	
	public function new(w,h,up, fl_transp:Bool, col:UInt, ?useScale2x=false) {
		width = w;
		height = h;
		upscale = up;
		postFilters = new Array();
		preFilters = new Array();
		buttons = new List();
		container = new SPR();
		graphics = container.graphics;
		alphaLoss = 1;
		pt0 = new flash.geom.Point(0, 0);
		fl_scale2x = useScale2x;
		
		dm = new mt.DepthManager(container);
		
		fl_transparent = fl_transp;
		bgColor = col;

		render = new SPR();
		bdCont = new SPR();
		render.addChild(bdCont);
		if(fl_scale2x) {
			var sqrt = Math.sqrt(upscale);
			var up = Std.int(upscale);
			if( upscale<2 || up!=upscale || up & (up-1) != 0 )
				throw "BUFFER : upscale must a power of 2 to use Scale2X (2,4,8,...)";
			if( width % 2!=0 || height % 2!=0 )
				throw "BUFFER : width & height must be multiples of 2";
			renderBD = new BD(Std.int(width*upscale), Std.int(height*upscale), fl_transparent, bgColor);
			bdCont.addChild( new BMP(renderBD) );
		}
		else {
			renderBD = new BD(width, height, fl_transparent, bgColor);
			var b = new BMP(renderBD);
			bdCont.addChild(b);
			bdCont.scaleX = bdCont.scaleY = upscale;
		}
	}
	
	public function createSimilarBitmap(?overrideTransparent:Bool) {
		return new BD(width, height, if(overrideTransparent!=null) overrideTransparent else fl_transparent, bgColor);
	}
	
	public function clone() {
		var bd = new BD(width, height, fl_transparent, bgColor);
		copyTo(bd);
		return bd;
	}
	
	public inline function copyTo(target:BD) {
		target.copyPixels(renderBD, new flash.geom.Rectangle(0,0,width,height), pt0, true);
	}
	
	public function setTexture(t:flash.display.BitmapData, alpha:Float, ?blendMode:flash.display.BlendMode, fl_disposeBitmap:Bool) {
		if(blendMode==null)
			blendMode = flash.display.BlendMode.OVERLAY;
		var w = Std.int( width*upscale );
		var h = Std.int( height*upscale );
		if (texture==null) {
			var bd = new BD(w, h);
			texture = new flash.display.Bitmap(bd);
			render.addChild(texture);
		}
		var spr = new flash.display.Sprite();
		var g = spr.graphics;
		g.beginBitmapFill(t, true, false);
		g.drawRect(0,0,w, h);
		g.endFill();
		texture.bitmapData.draw(spr);
		texture.blendMode = blendMode;
		texture.alpha = alpha;
		if (fl_disposeBitmap)
			t.dispose();
	}
	
	public static function makeMosaic(w:Int) {
		var bd = new BD(w,w, false, 0x808080);
		bd.setPixel(0, 0, 0xffffff);
		bd.setPixel(w-1, w-1, 0x0);
		for(x in 1...w-1) {
			bd.setPixel(x, 0, 0xE0E0E0);
			bd.setPixel(x, 1, 0xffffff);
			bd.setPixel(x, w-1, 0x0);
		}
		for(y in 1...w-1) {
			bd.setPixel(0, y, 0xffffff);
			bd.setPixel(w-1, y, 0x0);
		}
		return bd;
	}
	
	public inline function getRect() {
		return new flash.geom.Rectangle(render.x, render.y, width, height);
	}
	
	public inline function addChild(o:flash.display.DisplayObject) {
		container.addChild(o);
	}
	
	public inline function addStaticChild(o:flash.display.DisplayObject) {
		o.cacheAsBitmap = true;
		container.addChild(o);
	}
	
	public inline function addChildAt(o:flash.display.DisplayObject, idx:Int) {
		container.addChildAt(o, idx);
	}
	
	public function kill() {
		renderBD.dispose();
		graphics = null;
		container = null;
		if (render.parent!=null)
			render.parent.removeChild(render);
		killButtons();
	}
	
	public function killButtons() {
		for (b in buttons)
			b.clone.parent.removeChild(b.clone);
		buttons = new List();
	}
	
	public inline function killButton(original:flash.display.DisplayObject) {
		for (bt in buttons)
			if (bt.original==original) {
				bt.clone.parent.removeChild(bt.clone);
				buttons.remove(bt);
			}
	}
		
	public inline function getRealScale() {
		return if(fl_scale2x) upscale else 1;
	}

	public inline function registerButton(mc:flash.display.DisplayObject, ?fl_handCursor=true) {
		var clone = new SPR();
		bdCont.addChild(clone);
		clone.useHandCursor = fl_handCursor;
		clone.buttonMode = fl_handCursor;
		#if debug
		clone.alpha = 0.5;
		#else
		clone.alpha	 = 0;
		#end
		
		
		var g = clone.graphics;
		g.beginFill(0xFF00FF, 0.1);
		#if debug
		g.lineStyle(1,0xFF00FF, 1);
		#end
		var b = mc.getBounds(mc);
		g.drawRect(b.left, b.top, b.width, b.height);
		g.endFill();
		
		redirectEvents(clone, mc, flash.events.MouseEvent.CLICK);
		redirectEvents(clone, mc, flash.events.MouseEvent.MOUSE_OVER);
		redirectEvents(clone, mc, flash.events.MouseEvent.MOUSE_OUT);
		redirectEvents(clone, mc, flash.events.MouseEvent.MOUSE_MOVE);
		
		var m = mc.transform.concatenatedMatrix;
		var s = getRealScale();
		m.scale(s,s);
		clone.transform.matrix = m;
		
		buttons.add( { clone:clone, original:mc } );
	}
	
	public function registerAllButtons(?parent:flash.display.DisplayObjectContainer) {
		if (parent==null)
			parent = container;
			
		for (i in 0...parent.numChildren) {
			var mc = parent.getChildAt(i);
			if ( mc.hasEventListener(flash.events.MouseEvent.CLICK) || mc.hasEventListener(flash.events.MouseEvent.MOUSE_OVER) || mc.hasEventListener(flash.events.MouseEvent.MOUSE_OUT) )
				registerButton(mc);
			if(Reflect.hasField(mc, "numChildren"))
				registerAllButtons(cast mc);
		}
	}

	function redirectEvents(from:flash.events.EventDispatcher, to:flash.events.EventDispatcher, e:String) {
		from.addEventListener(e, function(d:Dynamic) {
			to.dispatchEvent(new flash.events.Event(e));
		});
	}
	
	public function globalToLocal(x:Float,y:Float) {
		return {
			x	: Std.int( (x-render.x)/upscale ),
			y	: Std.int( (y-render.y)/upscale ),
		}
	}
	
	public function localToGlobal(x:Float,y:Float) {
		return {
			x	: Std.int(x*upscale + render.x),
			y	: Std.int(y*upscale + render.y),
		}
	}
	
	public function getDebugView() {
		var spr : SPR = new SPR();
		spr.addChild(container);
		var outline = new SPR();
		spr.addChild(outline);
		var g = outline.graphics;
		g.lineStyle(2,0xffff00,1);
		g.drawRect(0,0,width, height);
		return spr;
	}
	
	public inline function scale2x() {
		var t = flash.Lib.getTimer();
		var memBuf = renderBD.getPixels(new flash.geom.Rectangle(0,0,Std.int(renderBD.width/2), Std.int(renderBD.height/2)) );
		var lineLength : UInt = renderBD.width*2;
		var tlineLength : UInt = renderBD.width*4;
		var end : UInt = memBuf.position;
		var pos : UInt = lineLength;
		memBuf.length+=renderBD.width*renderBD.height*4;
		flash.Memory.select(memBuf);
		var wid = renderBD.width/2;
		var x = 0;
		var p = 0;
		var right = 0;
		var tpos : UInt = end + pos*2;
		
		// Scale2X algorithm (source: http://scale2x.sourceforge.net/algorithm.html)
		while(pos<end) {
			var a = flash.Memory.getI32(pos-lineLength);
			var b = flash.Memory.getI32(pos+4);
			var c = p;
			var d = flash.Memory.getI32(pos+lineLength);
			p = right;
			right = b;

			var ab = a==b;
			var ac = a==c;
			var ad = a==d;
			var bc = b==c;
			var bd = b==d;
			var cd = c==d;
			flash.Memory.setI32(tpos, (ac && !cd && !ab ? a : p)); // haut-gauche
			flash.Memory.setI32(tpos+4, (ab && !ac && !bd ? b : p)); // haut-droite
			flash.Memory.setI32(tpos+tlineLength, (cd && !bd && !ac ? c : p)); // bas-gauche
			flash.Memory.setI32(tpos+4+tlineLength, (bd && !ab && !cd ? d : p)); // bas-droite
			pos+=4;
			tpos+=8;
			if(++x==wid) {
				x = 0;
				tpos+=tlineLength;
			}
		}
		memBuf.position = end;
		renderBD.setPixels(renderBD.rect, memBuf);
		return flash.Lib.getTimer()-t;
	}
	
	
	public inline function update() {
		// buttons
		var s = getRealScale();
		for (bt in buttons) {
			if (bt.original.parent==null) {
				bt.clone.parent.removeChild(bt.clone);
				buttons.remove(bt);
			}
			else {
				if(s!=1) {
					var m = bt.original.transform.concatenatedMatrix;
					m.scale(s,s);
					bt.clone.transform.matrix = m;
				}
				else
					bt.clone.transform.matrix = bt.original.transform.concatenatedMatrix;
				bt.clone.visible = bt.original.visible;
			}
		}
		
		// filtres post-rendu
		for(f in preFilters)
			renderBD.applyFilter(renderBD, renderBD.rect, pt0, f);
			
		// fade
		if (alphaLoss>0)
			if (alphaLoss>=1)
				renderBD.fillRect(renderBD.rect, bgColor);
			else {
				var ct = new flash.geom.ColorTransform();
				ct.alphaOffset = -alphaLoss*255;
				renderBD.colorTransform(renderBD.rect, ct);
			}

		renderBD.draw(container);
		
		// filtres post-rendu
		for(f in postFilters)
			renderBD.applyFilter(renderBD, renderBD.rect, pt0, f);
			
		if(onRender!=null)
			onRender();
		if(fl_scale2x) {
			var pow = 1;
			while(Math.pow(2,pow)<=upscale) {
				scale2x();
				pow++;
			}
		}
	}
}
