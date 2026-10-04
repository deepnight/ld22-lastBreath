package render;

/** Translate the original filter parameters into current Heaps filters. */
class FlashFilters {
	public static function glow(color:Int, alpha:Float, blurX:Float, blurY:Float, strength=1.0, quality=1, inner=false) : h2d.filter.Filter {
		return inner
			? new h2d.filter.InnerGlow(color,alpha,M.fmax(blurX,blurY)*0.5,Math.sqrt(strength))
			: new SoftGlow(color,alpha,M.fmax(blurX,blurY)*0.5,strength);
	}
	public static function shadow(distance:Float, degrees:Float, color:Int, alpha:Float, blurX:Float, blurY:Float, strength=1.0, quality=1, inner=false) : h2d.filter.Filter {
		if( inner ) return new InnerShadow(distance,M.toRad(degrees),color,alpha,M.fmax(blurX,blurY)*0.5,strength);
		return new h2d.filter.DropShadow(distance,M.toRad(degrees),color,Math.sqrt(alpha)/1.5,M.fmax(blurX,blurY)*0.5,Math.sqrt(strength),1,true);
	}
	public static function group(filters:Array<h2d.filter.Filter>) return new h2d.filter.Group(filters);
}
