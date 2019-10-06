package en;

class Item extends Entity {
	public static var ALL : Array<Item> = [];
	public var item : ItemType;

	public var maxUses : Int;

	public function new(x,y,i:ItemType) {
		super(x,y);
		ALL.push(this);
		item = i;
		spr.set(item.getName());

		maxUses = switch i {
			case Barrel: 1;
			case Grenade: 1;
			case Gun: 2;
			case Knife: 4;
			case SilverKey: 1;
			case GoldKey: 1;
		}
	}

	public function getGrabDist() : Float {
		return switch item {
			case Barrel: 0.5;
			case _: 0.7;
		}
	}

	public function getSpeedReductionOnGrab() : Float {
		return switch item {
			case Barrel: 0.55;
			case _: 0.;
		}
	}

	public function canGrab(){
		return isAlive() && !isGrabbed() && !isDepleted() && !cd.has("grabLock");
	}
	public function canUse() return isAlive() && isGrabbed() && !isDepleted();
	public function isDepleted() return maxUses<=0;

	public function consumeUse() {
		maxUses--;
		if( maxUses<=0 ) {
			cd.setS("grabLock",Const.INFINITE);
			switch item {
				case Barrel, Grenade: trigger(1);
				case _:
					cd.setS("selfDestructing", Const.INFINITE);
					cd.setS("selfDestruct", 0.2);
			}
		}
	}

	function trigger(sec:Float) {
		cd.setS("trigger", sec);
		maxUses = 0;
	}

	override function onZLand() {
		super.onZLand();
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	function onSelfDestruct() {
		fx.destroyItem(this);
		destroy();
	}

	function explosion(rCase:Float) {
		cd.setS("exploded", Const.INFINITE);
		fx.explosion(centerX, centerY, Const.GRID*(rCase-1));
		for(e in Mob.ALL)
			if( e.isAlive() && distCase(e)<=rCase && ( sightCheckEnt(e) || distCase(e)<=3 ) )
				e.hit(this, 99);

		for(e in Item.ALL)
			if( e!=this && e.isAlive() && distCase(e)<=rCase && ( sightCheckEnt(e) || distCase(e)<=3 ) && !e.cd.has("exploded") )
				e.onExplosion(this);
	}

	function onExplosion(from:Entity) {
		bumpAwayFrom(from, 0.2, rnd(0.2,0.3));
		switch item {
			case Barrel, Grenade: trigger(0.2);
			case _:
		}
	}

	function onTrigger() {
		switch item {
			case Barrel: explosion(6);
			case Grenade: explosion(4);
			case _:
		}
		destroy();
	}

	override function update() {
		super.update();

		// Entity collisions
		if( isMoving() || zr<0 )
			for(e in Mob.ALL)
				if( e.isAlive() && distCase(e)<=1.3 && !e.cd.has("touchLock"+uid) ) {
					if( cd.has("violentThrow") ) {
						e.bump(dirTo(e)*0.15, 0, 0.2);
						e.stunS(0.4);
						e.hit(e,1);
						e.triggerAlarm();
					}
					e.cd.setS("touchLock"+uid, 1);
					onTrigger();
					break;
				}

		if( isDepleted() && cd.has("selfDestructing") && !cd.has("selfDestruct") )
			onSelfDestruct();

		if( cd.has("trigger") && !cd.hasSetS("blink", cd.getS("trigger")<=0.3 ? 0.1 : 0.15) )
			blink(0xffcc00);

		switch item {
			case Barrel, Grenade:
				if( isDepleted() && !cd.has("trigger") )
					onTrigger();

			case _:
		}
	}
}
