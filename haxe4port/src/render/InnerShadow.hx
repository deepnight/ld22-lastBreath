package render;

/** Flash's directional inner shadow, clipped to the original silhouette. */
class InnerShadow extends h2d.filter.Blur {
	var maskPass = new h3d.pass.ScreenFx<ShadowMask>(new ShadowMask());
	var blendPass = new h3d.pass.ScreenFx<ShadowBlend>(new ShadowBlend());
	var distance:Float;
	var angle:Float;
	var color:Int;
	var alpha:Float;
	var strength:Float;
	public function new(distance:Float,angle:Float,color:Int,alpha:Float,radius:Float,strength:Float) {
		super(radius);
		this.distance=distance;this.angle=angle;this.color=color;this.alpha=alpha;this.strength=strength;
	}
	override function sync(ctx:h2d.RenderContext,s:h2d.Object) {
		super.sync(ctx,s);
		boundsExtend+=Math.ceil(Math.abs(distance));
	}
	override function draw(ctx:h2d.RenderContext,t:h2d.Tile) {
		var source=t.getTexture();
		var mask=ctx.textures.allocTileTarget("innerShadowMask",t);
		maskPass.shader.texture=source;
		maskPass.shader.delta.set(Math.round(Math.cos(angle)*distance)/t.width,Math.round(Math.sin(angle)*distance)/t.height);
		ctx.engine.pushTarget(mask);maskPass.render();ctx.engine.popTarget();
		pass.apply(ctx,mask);
		var out=ctx.textures.allocTileTarget("innerShadowResult",t);
		blendPass.shader.source=source;blendPass.shader.mask=mask;
		blendPass.shader.color.setColor(color);blendPass.shader.alpha=alpha;blendPass.shader.strength=strength;
		ctx.engine.pushTarget(out);blendPass.render();ctx.engine.popTarget();
		// New filter tiles express displacement relative to the input, not its world offset.
		return h2d.Tile.fromTexture(out);
	}
}
private class ShadowMask extends h3d.shader.ScreenShader {
	static var SRC={
		@param var texture:Sampler2D;
		@param var delta:Vec2;
		function fragment(){
			var uv=input.uv-delta;
			var a=texture.get(uv).a;
			if(uv.x<0 || uv.y<0 || uv.x>1 || uv.y>1)a=0;
			output.color=vec4(1-a);
		}
	};
}
private class ShadowBlend extends h3d.shader.ScreenShader {
	static var SRC={
		@param var source:Sampler2D;
		@param var mask:Sampler2D;
		@param var color:Vec3;
		@param var alpha:Float;
		@param var strength:Float;
		function fragment(){
			var src=source.get(input.uv);
			var amount=clamp(mask.get(input.uv).a*strength,0,1)*alpha;
			output.color=vec4(mix(src.rgb,color*src.a,amount),src.a);
		}
	};
}
