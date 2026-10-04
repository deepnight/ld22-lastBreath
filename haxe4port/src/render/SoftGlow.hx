package render;

/** Flash-style soft alpha falloff, using the Heaps Gaussian blur implementation. */
class SoftGlow extends h2d.filter.Glow {
	public function new(color:Int, opacity:Float, radius:Float, strength=1.0) {
		// Heaps applies the fixed color and gain in each of the two blur passes.
		super(color, 1, radius, Math.sqrt(strength), 1, true);
		setOpacity(opacity);
	}

	public inline function setOpacity(opacity:Float) {
		alpha = Math.sqrt(M.fmax(0,opacity))/1.5;
	}
}
