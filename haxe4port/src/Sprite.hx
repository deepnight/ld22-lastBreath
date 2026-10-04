/** Original fixed-tick playback semantics on top of current HSprite / AnimManager. */
class Sprite extends dn.heaps.slib.HSprite {
	static var ALL : Array<Sprite> = [];
	public var fl_killOnEndPlay(default,set) = false;

	public function new(lib:SpriteLib, group:String, frame=0) {
		super(lib,group,frame);
		ALL.push(this);
	}

	public function playAnim(id:String, plays=999999) {
		if( anim.isPlaying(id) ) return;
		anim.play(id,plays);
		@:privateAccess if(anim.hasAnim())anim.getCurrentAnim().curFrameCpt=1;
		if( Assets.isDogAnim(id) )
			anim.onComplete(function() set(null,"player",0));
	}
	public inline function hasAnim() return animAllocated && anim.hasAnim();
	public inline function getFrame() return frame;
	public function stopAnim(frame:Int) {
		anim.stopWithoutStateAnims();
		set(null,"player",frame);
	}
	function set_fl_killOnEndPlay(v:Bool) {
		if( v ) anim.killAfterPlay();
		return fl_killOnEndPlay = v;
	}
	static function inGameTree(s:h2d.Object) {
		while(s!=null){if(s==Boot.ME.gameScene)return true;s=s.parent;}
		return false;
	}
	public static function updateAll() {
		for( s in ALL.copy() )
			if( !inGameTree(s) ) ALL.remove(s);
			else if( s.animAllocated ) s.anim.update(1);
	}
}
