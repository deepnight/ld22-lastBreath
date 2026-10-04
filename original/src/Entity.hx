import Game;

@:publicFields class Entity {
	var man			: Game;
	var fl_stable	: Bool;
	var fl_grabbing	: Bool;
	var fl_pick		: Bool;
	var fl_trigger	: Bool;
	var cx			: Int;
	var cy			: Int;
	var xr			: Float;
	var yr			: Float;
	var dx			: Float;
	var dy			: Float;
	var sprite		: Null<HSprite>;
	var id			: String;

	var onLand		: Null<Void->Void>;

	var jumpJIT		: Int;

	public function new(m) {
		man = m;
		jumpJIT = 0;
		id = "?";
		cx = 0;
		cy = 0;
		xr = 0.5;
		yr = 0.5;
		dx = dy = 0;
		fl_pick = false;
		fl_trigger = false;
		fl_stable = false;
		fl_grabbing = false;
	}

	public function destroy() {
		if( sprite!=null && sprite.parent!=null )
			sprite.parent.removeChild(sprite);
		sprite = null;
	}

	public function canGrab(dir) {
		var room = man.room;
		return !fl_stable && (dir==1?xr>0.5:xr<0.5) && yr>0.3 && yr<0.6 && dy>=0 &&
			!room.get(cx+dir,cy-1).collide && room.get(cx+dir,cy).collide && !room.get(cx,cy-1).collide;
	}

	function grab(dir:Int) {
		fl_stable = true;
		fl_grabbing = true;
		dx = 0;
		dy = 0;
		xr = if(dir==1) 1 else 0;
		yr = 0.45;
		sprite.setCenterRatio(0.4, 1);
		Assets.SBANK.grab(0.2);
	}

	function jump(p:Float) {
		sprite.setCenterRatio(0.5, 1);
		dy = -p;
		fl_stable = false;
		fl_grabbing	= false;
		jumpJIT = 0;
	}

	function moveTo(x,y) {
		cx = x;
		cy = y;
		xr = 0.5;
		yr = 1;
		update();
	}

	public function update() {
		if( sprite==null )
			return;

		var r = man.room;

		if( fl_stable )
			jumpJIT = 3;
		else
			jumpJIT--;


		// obey gravity!
		if( !fl_stable && !fl_grabbing )
			dy+=0.03;
		else if( yr<1 || dy<0 || !r.get(cx,cy+1).collide )
			if( !fl_grabbing )
				fl_stable = false;
		yr+=dy;
		dy*=0.9;

		if( dy>0 && yr>=1 && r.get(cx,cy+1).collide ) {
			dy = 0;
			//cy--;
			yr = 1;
			fl_stable = true;
			if(onLand!=null) onLand();
			if( this==man.player )
				if( man.phase=="intro" )
					Assets.SBANK.fallLand(0.3);
				else
					Assets.SBANK.land(0.2);
		}
		if( dy<0 && yr<0.5 && r.get(cx,cy-1).collide ) {
			dy = 0;
			yr = 0.5;
		}

		while(yr<0) {
			cy--;
			yr++;
		}
		while(yr>1) {
			cy++;
			yr--;
		}

		xr+=dx;
		dx*=0.7;
		if( xr<0.5 && r.get(cx-1,cy).collide ) {
			if( dx<0 ) dx = 0 else xr += 0.05;
			if( xr<0.4 ) xr = 0.4;
		}
		if( xr>0.6 && r.get(cx+1,cy).collide ) {
			if( dx>0 ) dx = 0 else xr -= 0.05;
			if( xr>0.7 ) xr = 0.7;
		}
		while(xr>1) {
			cx++;
			xr--;
		}
		while(xr<0) {
			cx--;
			xr++;
		}

		//if( Lib.abs(dx)<0.01 )
			//dx = 0;
		//if( Lib.abs(dy)<0.01 )
			//dy = 0;

		sprite.x = Std.int(cx*Game.CWID + xr*Game.CWID);
		sprite.y = Std.int(cy*Game.CHEI + yr*Game.CHEI);
	}
}