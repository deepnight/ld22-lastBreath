package mt.deepnight;

enum TType {
	TLinear;
	TLoop; // loop : valeur initiale -> valeur finale -> valeur initiale
	TLoopEaseIn; // loop avec départ lent
	TLoopEaseOut; // loop avec fin lente
	TEase;
	TEaseIn; // départ lent, fin linéaire
	TEaseOut; // départ linéaire, fin lente
	TBurn; // départ rapide, milieu lent, fin rapide,
	TBurnIn; // départ rapide, fin lente,
	TBurnOut; // départ lente, fin rapide
	TZigZag; // une oscillation et termine sur Fin
	TRand; // progression chaotique de début -> fin. ATTENTION : la durée ne sera pas respectée (plus longue)
	TShake; // variation aléatoire de la valeur entre Début et Fin, puis s'arrête sur Début (départ rapide)
	TShakeBoth; // comme TShake, sauf que la valeur tremble aussi en négatif
	TJump; // saut de Début -> Fin
	TElasticEnd; // léger dépassement à la fin, puis réajustment
}

// GoogleDoc pour tester les valeurs de Bézier
// ->	https://spreadsheets.google.com/ccc?key=0ArnbjvQe8cVJdGxDZk1vdE50aUxvM1FlcDAxNWRrZFE&hl=en&authkey=CLCwp8QO

typedef Tween = {
	parent		: Dynamic,
	vname		: String,
	n			: Float,
	ln			: Float,
	speed		: Float,
	from		: Float,
	to			: Float,
	type		: TType,
	fl_pixel	: Bool, // arrondi toutes les valeurs si TRUE (utile pour les anims pixelart)
	onUpdate	: Null<Void->Void>,
	onUpdateT	: Null<Float->Void>, // callback appelé avec la progression (0->1) en paramètre
	onEnd		: Null<Void->Void>,
}

class Tweenie {
	static var DEFAULT_DURATION = DateTools.seconds(1);

	var tlist			: List<Tween>;
	var errorHandler	: String->Void;

	public function new() {
		tlist = new List();
		errorHandler = onError;
	}
	
	function onError(e) {
		trace(e);
	}
	
	public function setErrorHandler(cb:String->Void) {
		errorHandler = cb;
	}
	
	//@:macro public static function getMethods( e : Expr ) {
		//switch( e.expr ) {
		//case EField(o,f):
			//var getset = haxe.macro.Context.parse("{ get : function() return tmp."+f+", set : function(v) tmp."+f+"=v }", e.pos);
			//return {
				//expr : EBlock([ { expr : EVars([ { name : "tmp", e : o } ]), pos : o.pos }, getset ]),
				//pos : e.pos,
			//};
		//default: haxe.macro.Context.error("Should be <e>.field",e.pos);
		//}
	//}
	//
	//getMethods(o.blabla)
	//
	//--->
	//
	//create({ var tmp = o; { get : function() return tmp.blabla, set : function() .... } },to, .....)
	//
	//
	//function create<T>( o : T, getSet : { function get(o:T) : Float; function set(o:T,v:Float) : Void } )

	public inline function create(parent:Dynamic, varName:String, to:Float, ?tp:TType, ?duration_ms:Float) {
		if( Reflect.hasField(parent,varName) )
			return create_(parent, varName, to, tp, duration_ms);
		else
			return create_(parent, untyped __unprotect__(varName), to, tp, duration_ms); // champ obfuscqué
	}
	
	public function exists(p:Dynamic, v:String) {
		for (t in tlist)
			if (t.parent == p && t.vname == v)
				return true;
		return false;
	}

	function create_(p:Dynamic, v:String, to:Float, ?tp:TType, ?duration_ms:Float) {
		if ( duration_ms==null )
			duration_ms = DEFAULT_DURATION;

		if ( p==null )
			errorHandler("tween creation failed : null parent, v="+v+" tp="+tp);
		if ( tp==null )
			tp = TEase;

		// on supprime les tweens précédents appliqués à la même variable
		var tfound : TType = null;
		for(t in tlist)
			if(t.parent==p && t.vname==v) {
				tfound = t.type;
				tlist.remove(t);
			}
		if ( tfound!=null ) {
			if (tp==TEase && (tfound==TEase || tfound==TEaseOut) )
				tp = TEaseOut;
		}
		// ajout
		var t : Tween = {
			parent		: p,
			vname		: v,
			n			: 0.0,
			ln			: 0.0,
			speed		: 1 / ( duration_ms*30/1000 ), // une seconde
			from		: cast Reflect.field(p,v),
			to			: to,
			type		: tp,
			fl_pixel	: false,
			onUpdate	: null,
			onUpdateT	: null,
			onEnd		: null,
		}


		if( t.from==t.to )
			t.ln = 1; // tweening inutile : mais on s'assure ainsi qu'un update() et un end() seront bien appelés

		tlist.add(t);

		return t;
	}

	static inline function fastPow2(n:Float):Float {
		return n*n;
	}
	static inline function fastPow3(n:Float):Float {
		return n*n*n;
	}

	static inline function bezier(t:Float, p0:Float, p1:Float,p2:Float, p3:Float) {
		return
			fastPow3(1-t)*p0 +
			3*t*fastPow2(1-t)*p1 +
			3*fastPow2(t)*(1-t)*p2 +
			fastPow3(t)*p3;
	}

	public function delete(parent:Dynamic) { // attention : les callbacks end() / update() ne seront pas appelés !
		for(t in tlist)
			if(t.parent==parent)
				tlist.remove(t);
	}
	
	// suppression du tween sans aucun appel aux callbacks onUpdate, onUpdateT et onEnd (!)
	public function killWithoutCallbacks(parent:Dynamic, ?varName:String) {
		for (t in tlist)
			if (t.parent==parent && (varName==null || varName==t.vname))
				tlist.remove(t);
	}
	
	public function terminate(parent:Dynamic, ?varName:String) {
		for (t in tlist)
			if (t.parent==parent && (varName==null || varName==t.vname))
				terminateTween(t);
	}
	
	public function terminateTween(t:Tween) {
		var v = t.from+(t.to-t.from)*calcValue(t.type,1);
		if (t.fl_pixel)
			v = Math.round(v);
		Reflect.setField(t.parent, t.vname, v);
		onUpdate(t,1);
		onEnd(t);
		tlist.remove(t);
	}
	public function terminateAll() {
		for(t in tlist)
			t.ln = 1;
		update();
	}
	
	
	inline function onUpdate(t:Tween, n:Float) {
		if ( t.onUpdate!=null )
			t.onUpdate();
		if ( t.onUpdateT!=null )
			t.onUpdateT(n);
	}
	inline function onEnd(t:Tween) {
		if ( t.onEnd!=null )
			t.onEnd();
	}
	
	inline function calcValue(type:TType, step:Float) {
		return switch(type) {
			case TLinear		: step;
			case TRand			: step;
			case TEase			: bezier(step, 0,	0,		1,		1);
			case TEaseIn		: bezier(step, 0,	0,		0.5,	1);
			case TEaseOut		: bezier(step, 0,	0.5,	1,		1);
			case TBurn			: bezier(step, 0,	1,	 	0,		1);
			case TBurnIn		: bezier(step, 0,	1,	 	1,		1);
			case TBurnOut		: bezier(step, 0,	0,		0,		1);
			case TZigZag		: bezier(step, 0,	2.5,	-1.5,	1);
			case TLoop			: bezier(step, 0,	1.33,	1.33,	0);
			case TLoopEaseIn	: bezier(step, 0,	0,		2.25,	0);
			case TLoopEaseOut	: bezier(step, 0,	2.25,	0,		0);
			case TShake			: bezier(step, 0.5,	1.22,	1.25,	0);
			case TShakeBoth		: bezier(step, 0.5,	1.22,	1.25,	0);
			case TJump			: bezier(step, 0,	2,		2.79,	1);
			case TElasticEnd	: bezier(step, 0,	0.7,	1.5,	1);
		}
	}
	
	public inline function update(?tmod=1.0) {
		for (t in tlist) {
			var dist = t.to-t.from;
			if (t.type==TRand)
				t.ln+=if(Std.random(100)<33) t.speed * tmod else 0;
			else
				t.ln+=t.speed * tmod;
			t.n = calcValue(t.type, t.ln);
			if ( t.ln<1 ) {
				// en cours...
				var val =
					if (t.type!=TShake && t.type!=TShakeBoth)
						t.from + t.n*dist ;
					else if ( t.type==TShake )
						t.from + Lib.randFloat(Lib.abs(t.n*dist)) * (dist>0?1:-1);
					else
						t.from + Lib.randFloat(t.n*dist) * (Std.random(2)*2-1);
				if (t.fl_pixel)
					val = Math.round(val);
				Reflect.setField(t.parent, t.vname, val);
				onUpdate(t, t.ln);
			}
			else {
				// fini !
				terminateTween(t);
			}
		}
	}
}
