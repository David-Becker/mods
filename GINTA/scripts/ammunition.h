//
//	Ammunition refill handler script
// Make sure your unit has a function called RefillAmmo()
//

#include "exptype.h"

#define IS_AMMOREFILLER h == H_MAIN_FACTORY
#define AMMO_REFILL_RADIUS [200]
// Let's assume that all units refill at the same range

// This is where the heights of all refillers would be listed, remember: UNIT_HEIGHT = s3o radius * 65536
#define H_MAIN_FACTORY 3342336 // 51 * 65536



static-var ammunition;
#ifdef MAX_SECONDARY_AMMO
static-var secondary_ammo;
#endif

CheckForRefills()
{
	//var selfid;
	//selfid = get 71; //MY_ID
	while(1) {
		sleep 5000; //this is slow so we won't try it often
		var uid;
#ifndef CUSTOM_CONDITION
#ifndef MAX_SECONDARY_AMMO
		if (ammunition < MAX_AMMO) { // don't check if already full
#else		
		if (ammunition < MAX_AMMO || secondary_ammo < MAX_SECONDARY_AMMO) { // don't check if already full
#endif
#else
		if (CUSTOM_CONDITION) {
#endif
			for (uid=0;uid < 5000;++uid) { //thanks, zwzsg
			// get 70 = get MAX_ID
			// for all units, 
				if (get 74(uid)) { // UNIT_ALLIED | that are allies,
					var h;
					h=get UNIT_HEIGHT(uid);
					if (IS_AMMOREFILLER) { // and are ammo supplies
						if (get XZ_HYPOT(get UNIT_XZ(uid) - get PIECE_XZ(body)) < AMMO_REFILL_RADIUS)
						// see, if they are closer than AMMO_REFILL_RADIUS
						{
							ammunition = MAX_AMMO;
#ifdef MAX_SECONDARY_AMMO
							secondary_ammo = MAX_SECONDARY_AMMO;
#endif
							start-script RefillAmmo();
						}
					}
				}
			}
		}
	}
}