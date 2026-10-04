import dn.heaps.HParticle;

/** Preserve the jam's particle equations; reuse HParticle's pooled batch rendering. */
class Particle extends h2d.Object {
	public static var ALL : Array<Particle> = [];
	static var pool : dn.heaps.HParticle.ParticlePool;
	static var pixel : h2d.Tile;
	var hp : HParticle;
	var rx : Float;
	var ry : Float;
	public var r = 0.; // Original angular velocity in degrees per tick.
	public var life : Int;
	public var fl_wind = true;
	public var bounds : Null<h2d.col.Bounds>;
	public var groupId : Null<String>;
	public var dx(get,set) : Float;
	inline function get_dx() return hp.dx;
	inline function set_dx(v:Float) return hp.dx=v;
	public var dy(get,set) : Float;
	inline function get_dy() return hp.dy;
	inline function set_dy(v:Float) return hp.dy=v;
	public var gx(get,set) : Float;
	inline function get_gx() return hp.gx;
	inline function set_gx(v:Float) return hp.gx=v;
	public var gy(get,set) : Float;
	inline function get_gy() return hp.gy;
	inline function set_gy(v:Float) return hp.gy=v;
	public var frictX(get,set) : Float;
	inline function get_frictX() return hp.frictX;
	inline function set_frictX(v:Float) return hp.frictX=v;
	public var frictY(get,set) : Float;
	inline function get_frictY() return hp.frictY;
	inline function set_frictY(v:Float) return hp.frictY=v;

	public static function init() {
		pixel = h2d.Tile.fromColor(0xFFFFFF,1,1);
		pool = new dn.heaps.HParticle.ParticlePool(pixel,1024,30);
	}
	public function new(x:Float,y:Float) {
		super();
		rx=this.x=x; ry=this.y=y;
		var sb = new h2d.SpriteBatch(pixel,this);
		hp=pool.alloc(sb,pixel,0,0);
		hp.onKill=function(){ALL.remove(this);remove();};
		dx=dy=gx=0; gy=0.4+Std.random(4)/10;
		frictX=0.95+Std.random(40)/1000; frictY=0.97;
		life=32+Std.random(32);
		ALL.push(this);
	}
	public function drawBox(w:Float,h:Float,color:Int,a=1.0) {
		hp.scaleX=w; hp.scaleY=h;
		hp.setCenterRatio(Math.floor(w/2)/w,Math.floor(h/2)/h);
		hp.colorize(color); hp.a=a;
	}
	public static function makeExplosion(n:Int,x:Float,y:Float,powX:Int,powY:Int) {
		var list=[];
		for(i in 0...n){
			var p=new Particle(x+Math.random()*0.7*sign(),y+Math.random()*0.7*sign());
			p.dx=Math.random()*powX*sign();p.dy=-Math.random()*powY;
			if(i<n*0.3)p.dy*=1+Math.random()*2;
			if(i>=n*0.3 && i<n*0.6)p.dx*=1+Math.random()*2;
			list.push(p);
		}
		return list;
	}
	public static function makeDust(n:Int,x:Float,y:Float){
		var list=[];
		for(i in 0...n){
			var p=new Particle(x+Math.random()*7*sign(),y+Math.random()*7*sign());
			p.dx=Math.random()*0.8*sign();p.dy=-Math.random()*0.8;
			p.gx=Math.random()*0.02*sign();p.gy=Math.random()*0.02*sign();
			list.push(p);
		}
		return list;
	}
	static inline function sign() return Std.random(2)*2-1;
	public static function update(){
		for(p in ALL.copy()){
			p.dx+=p.gx+(p.fl_wind ? -0.06 : 0);
			p.dy+=p.gy+(p.fl_wind ? 0.02 : 0);
			p.dx*=p.frictX;p.dy*=p.frictY;
			p.rx+=p.dx;p.ry+=p.dy;
			p.x=Std.int(p.rx);p.y=Std.int(p.ry);
			p.rotation+=M.toRad(p.r);
			if(p.life--<=0)p.alpha-=0.1;
			if(p.alpha<=0 || p.parent==null || p.bounds!=null && !(p.rx>=p.bounds.xMin && p.rx<p.bounds.xMax && p.ry>=p.bounds.yMin && p.ry<p.bounds.yMax))p.hp.kill();
		}
	}
	public static function clear(){for(p in ALL.copy())p.hp.kill();}
	public static function dispose(){clear();pool.dispose();pixel.dispose();}
}
