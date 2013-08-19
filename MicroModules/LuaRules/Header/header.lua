local red = UnitDefNames.red.id
local green = UnitDefNames.green.id
local blue = UnitDefNames.blue.id
local black = UnitDefNames.black.id
local blobs= {
	[blue]={"Gunner","unitpics/blue.png"},
	[red]={"Cannon","unitpics/red.png"},
	[green]={"Missile Launcher","unitpics/green.png"},
	[black]={"Shadow",""},
}
local higherUnits={
	[UnitDefNames.tankblue.id]= {
		contents={ [blue] = 1 },
		contInv={"blue" },
		hpBonus=35,
		baseMass=20,
		propulsion=42,
	},
	[UnitDefNames.tankred.id]= {
		contents={ [blue] = 1, [red]=2 },
		contInv={"blue", "red" },
		hpBonus=30,
		baseMass=20,
		propulsion=42,
	},
	[UnitDefNames.tankgreen.id]= {
		contents={ [blue] = 1, [green]=2 },
		contInv={"blue","green" },
		hpBonus=20,
		baseMass=20,
		propulsion=42,
	},
	[UnitDefNames.turretblue.id]= {
		contents={ [blue] = 2, [red]=1 },
		contInv={"red", "blue" },
		hpBonus=60,
		baseMass=20,
		propulsion=42,
	},
	[UnitDefNames.turretred.id]= {
		contents={ [red]=1 },
		contInv={"red" },
		hpBonus=10,
		baseMass=20,
		propulsion=42,
	},
	[UnitDefNames.turretgreen.id]= {
		contents={ [red]=1, [green]=2 },
		contInv={"red", "green" },
		hpBonus=25,
		baseMass=20,
		propulsion=42,
	},
	[UnitDefNames.airblue.id]= {
		contents={ [green]=1,[blue]=2 },
		contInv={"green","blue" },
		hpBonus=35,
		baseMass=20,
		propulsion=42,
	},
	[UnitDefNames.airred.id]= {
		contents={ [green]=1,[red]=2 },
		contInv={"green","red" },
		hpBonus=5,
		baseMass=20,
		propulsion=42,
	},
	[UnitDefNames.airgreen.id]= {
		contents={ [green]=1 },
		contInv={"green" },
		hpBonus=30,
		baseMass=20,
		propulsion=42,
	},
	[UnitDefNames.master.id]= {
		contents={ [red]=1,[green]=1,[blue]=1 },
		contInv={"ANY" },
		hpBonus=60,
		baseMass=20,
		propulsion=42,
	},
	[UnitDefNames.tankblack.id]= {
		contents={ [black]=1 },
		contInv={"black" },
		hpBonus=150,
		baseMass=20,
		propulsion=42,
	},
}

--The merge table must contain entries for all combinations!
local mergeTable= {
	[blue]= {[blue]="tankblue",[red]="turretblue",[green]="airblue"},
	[red]=  {[blue]="tankred",[red]="turretred",[green]="airred"},
	[green]={[blue]="tankgreen",[red]="turretgreen",[green]="airgreen"},
}

local blobCount=1023

local CMD_JOIN = 31000
local CMD_MERGE = 31001
local CMD_EJECT = 31002 -- to 31004
local CMD_FORM = 31008
local CMD_WAVE = 31010
local CMD_WAVELEVEL = 31009
return red, green, blue, blobs, higherUnits, mergeTable, blobCount, CMD_JOIN, CMD_MERGE, CMD_EJECT, CMD_WAVE, CMD_WAVELEVEL, CMD_FORM
