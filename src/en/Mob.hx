package en;

class Mob extends Entity {
	public static var ALL : Array<Mob> = [];

	var patrolPts : Array<CPoint> = [];
	var lastAlarmPt : CPoint;
	var curPatrolIdx = 0;
	var curPatrolPt(get,never) : CPoint; inline function get_curPatrolPt() return patrolPts[curPatrolIdx];

	public var lookAng : Float;
	var viewCone : HSprite;

	public function new(x,y, data:ogmo.Entity) {
		super(x,y);
		ALL.push(this);
		lastAlarmPt = new CPoint(cx,cy);

		// Parse patrol
		for(n in data.nodes) {
			for(pt in patrolPts)
				if( pt.is(n.cx,n.cy) )
					throw "Duplicate patrol point for mob at "+cx+","+cy;
			patrolPts.push( new CPoint(n.cx, n.cy) );
		}
		if( patrolPts.length==0 || !patrolPts[0].is(cx,cy) )
			patrolPts.insert(0, new CPoint(cx,cy));

		viewCone = Assets.tiles.h_get("viewCone",0, 0, 0.5);
		game.scroller.add(viewCone, Const.DP_FX_BG);
		viewCone.setScale(0.2);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	public function hasAlarm() {
		return cd.has("alarm");
	}

	override function postUpdate() {
		super.postUpdate();

		viewCone.x = footX;
		viewCone.y = footY;
		viewCone.visible = !level.hasVisibleRoof(cx,cy);

		viewCone.scaleX += ( ( hasAlarm() && sightCheckEnt(hero) ? 0.5 : 0.3 ) - viewCone.scaleX ) * 0.2;
		viewCone.scaleY += ( ( hasAlarm() && sightCheckEnt(hero) ? 0.2 : 0.3 ) - viewCone.scaleY ) * 0.2;
		viewCone.alpha += ( ( hasAlarm() ? 0.3 : 0.5 ) - viewCone.alpha ) * 0.2;
		if( !hasAlarm() )
			viewCone.rotation += M.radSubstract(lookAng,viewCone.rotation)*0.2 ;
		else if( sightCheckEnt(hero) )
			viewCone.rotation += M.radSubstract(angTo(hero),viewCone.rotation)*0.2 ;
		else
			viewCone.rotation += M.radSubstract(lookAng, viewCone.rotation ) * 0.2 ;
		viewCone.colorize( hasAlarm() ? sightCheckEnt(hero) ? 0xff0000 : 0xffdd00 : 0x7a9aff );
	}


	override function update() {
		super.update();

		if( !hasAlarm() ) {
			if( M.dist(footX, footY, curPatrolPt.footX, curPatrolPt.footY)>Const.GRID*0.1 ) {
				// Patrol movement
				var s = 0.005;
				var a = Math.atan2(curPatrolPt.footY-footY, curPatrolPt.footX-footX);
				dx+=Math.cos(a)*s;
				dy+=Math.sin(a)*s;
				lookAng = M.round(a/M.PIHALF)*M.PIHALF;
			}
			else {
				// Reached patrol point
				curPatrolIdx++;
				if( curPatrolIdx>=patrolPts.length )
					curPatrolIdx = 0;
			}
		}
		else {
			// Track alarm source
			var s = 0.007;
			var a = Math.atan2(lastAlarmPt.footY-footY, lastAlarmPt.footX-footX);
			dx+=Math.cos(a)*s;
			dy+=Math.sin(a)*s;
			if( distPxFree(lastAlarmPt.footX,lastAlarmPt.footY)>=Const.GRID*0.5 )
				lookAng = a;
		}

		// See hero
		if( sightCheckEnt(hero) && M.radDistance(angTo(hero),lookAng)<=M.PI*0.3 ) {
			lastAlarmPt.set(hero.cx, hero.cy, hero.xr, hero.yr);
			cd.setS("alarm",3);
		}

		// Sound emit fx
		if( level.hasVisibleRoof(cx,cy) && !cd.hasSetS("soundFx", 1) && distCase(hero)<=10 )
			fx.emitSound(footX, footY);
	}
}