package mt.deepnight;
import flash.Vector;

class Particle extends flash.display.Shape {
	public static var ALL : Vector<Particle> = new Vector();
	public static var DEFAULT_BOUNDS : flash.geom.Rectangle = null;
	public static var GX = 0;
	public static var GY = 0.4;
	public static var WINDX = 0.0;
	public static var WINDY = 0.0;
	public static var SNAP_PIXELS = true;
	
	var rx				: Float; // real x,y
	var ry				: Float;
	public var dx		: Float;
	public var dy		: Float;
	public var frictX	: Float;
	public var frictY	: Float;
	public var gx		: Float;
	public var gy		: Float;
	public var r		: Float;
	public var life		: Int;
	public var bounds	: Null<flash.geom.Rectangle>;
	public var fl_wind	: Bool;
	public var groundY	: Null<Float>;
	public var groupId	: Null<String>;

	public function new(x:Float,y:Float) {
		super();
		moveTo(x,y);
		dx = 0;
		dy = 0;
		gx = GX;
		gy = GY + Std.random(Std.int(GY*10))/10;
		r = 0;
		frictX = 0.95+Std.random(40)/1000;
		frictY = 0.97;
		life = 32+Std.random(32);
		bounds = DEFAULT_BOUNDS;
		fl_wind = true;
		ALL.push(this);
	}
	
	public inline function drawBox(w,h, col:Int, ?a=1.0) {
		graphics.clear();
		graphics.beginFill(col, a);
		graphics.drawRect(-Std.int(w/2),-Std.int(h/2), w,h);
		graphics.endFill();
	}
	
	public static function makeExplosion(n:Int, x,y, powX:Int, ?powY:Int) {
		if(powY==null)
			powY = Math.round(powX*2);
		var list = new List();
		for(i in 0...n) {
			var p = new Particle(x+Std.random(700)/1000*sign(), y+Std.random(700)/1000*sign());
			p.dx = Std.random(powX*1000)/1000 * sign();
			p.dy = -Std.random(powY*1000)/1000;
			if(i<n*0.3)
				p.dy*=1+randFloat(2);
			if(i>=n*0.3 && i<n*0.6)
				p.dx*=1+randFloat(2);
			//p.r = p.dx*3;
			list.add(p);
		}
		return list;
	}
	
	public static function makeDust(n:Int, x,y) {
		var list = new List();
		for(i in 0...n) {
			var p = new Particle(x+randFloat(7)*sign(), y+randFloat(7)*sign());
			p.dx = randFloat(0.8)*sign();
			p.dy = -randFloat(0.8);
			p.gx = randFloat(0.02)*sign();
			p.gy = randFloat(0.02)*sign();
			list.add(p);
		}
		return list;
	}
	
	
	public static inline function sign() {
		return Std.random(2)*2-1;
	}
	
	public static inline function randFloat(f:Float) {
		return Std.random( Std.int(f*10000) ) / 10000;
	}
	
	public inline function moveTo(x,y) {
		rx = this.x = x;
		ry = this.y = y;
	}
	
	public static function update() {
		var i : UInt = 0;
		var all = ALL;
		var wx = WINDX;
		var wy = WINDY;
		var snap = SNAP_PIXELS;
		while(i<all.length) {
			var p = ALL[i];
			var wind = (p.fl_wind?1:0);
			p.dx+=p.gx + wind*wx; // gravité
			p.dy+=p.gy + wind*wy;
			p.dx*=p.frictX; // friction
			p.dy*=p.frictY;
			p.rx+=p.dx; // mouvement
			p.ry+=p.dy;
			if(p.groundY!=null && p.dy>0 && p.ry>=p.groundY) {
				p.dy = -p.dy*0.85;
				p.ry = p.groundY-1;
			}
			if(snap) {
				p.x = Std.int(p.rx);
				p.y = Std.int(p.ry);
			}
			else {
				p.x = p.rx;
				p.y = p.ry;
			}
			p.rotation+=p.r;
			if(p.life--<=0)
				p.alpha-=0.1;
			if( p.alpha<=0 || p.bounds!=null && !p.bounds.contains(p.rx, p.ry)  ) {
				// destruction
				p.parent.removeChild(p);
				all.splice(i,1);
			}
			else
				i++;
		}
	}
}
