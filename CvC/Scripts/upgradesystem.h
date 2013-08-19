static-var upgrades;

//Accepted options:
// UPGRADE_RATE: The delay between checks, default:1000
// UPGRADE_BREAK_ON: Stop looking for more upgrades when this combination has been found. default:Don't break
// UPGRADE_LOOP: Should this loop or run once? default:1
// UPGRADE_BREAK_TEMPORARY: If not defined the upgrade loop will be terminated completely once the break condition is reached

#define UPG_RADAR 1
#define UPG_TITANMISSILES 2
#define UPG_TITANSHIELD 4
#define UPG_MEXSHIELD 8
#define UPG_HEAVYWEAPONS 16
#define UPG_SUPERWEAPONS 32
#define UPG_DRONEMISSILES 64
#define UPG_CRUISEENGINES 128

#ifndef UPGRADE_RATE
#define UPGRADE_RATE 1000
#endif

#ifndef UPGRADE_LOOP
#define UPGRADE_LOOP 1
#endif

CheckForUpgrades()
{
	set-signal-mask 32768;
	var id, firstrun;
	firstrun=1;
	while(UPGRADE_LOOP || firstrun) {
		upgrades=0;
		for(id = get MAX_ID; id>0; --id) { //iterate through all units
			if (65536 >= (get UNIT_HEIGHT(id))) { //look for all upgrades
				if (get UNIT_ALLIED(id)) { //see if it's friendly
					if (!get UNIT_BUILD_PERCENT_LEFT(id)) {
						upgrades = upgrades | (32768/(get UNIT_HEIGHT(id)));
						#ifdef UPGRADE_ACTION
						UPGRADE_ACTION
						#endif
						#ifdef UPGRADE_BREAK_ON
						if (upgrades == (upgrades | UPGRADE_BREAK_ON)) {
							id=(get (MAX_ID))+1;
							#ifndef UPGRADES_BREAK_TEMPORARY
							signal 32768; //suicide
							#endif
							sleep UPGRADE_RATE;
							upgrades=0;
						}
						#endif
					}
				}
			}
		}
		sleep UPGRADE_RATE;
		firstrun=0;
	}
}