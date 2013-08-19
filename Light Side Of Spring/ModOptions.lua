-- losscondition is handled by the "Comm Continue / Comm End / Lineage" setting
-- eviless is handled by another sd7
local options={
--	{
--		key='losscondition',
--		name='Loss Condition',
--		desc='Loss Condition',
--		type='list',
--		def='Default',
--		items={
--			{key='Default', name='Default: Use the Lineage/Comm End/Com Continue settings!', desc='No need for this "Loss Condition" option, as: Lineage = Home, Comm End = Factories, Comm Continue = Everything'},
--			{key='Home', name='Home Base: Go for the Kernel/Hole!', desc='Player lose when he has no more Kernel or Hole'},
--			{key='Factories', name='Factories: Kill all Socket/Window/Kernel/Hole!', desc='Player lose when he has no more factories (Kernel, Hole, Socket, Window)'},
--			{key='Everything', name='Everything: Must hunt every unit!', desc='Player lose when he has no more units (not counting mines)'}
--		}
--	},
--	{
--		key="evilless",
--		name="Evilless",
--		desc="Terminals, Pointer NX flag, and the whole Hacker side, removed.",
--		type="bool",
--		def=false
--	},
--	{
--		key="ons", -- keys must be lower case
--		name="ONS",
--		desc="Kernel/Hole get an invulnerable shield as long as the team has one socket/window.",
--		type="bool",
--		def=false
--	},
	{
		key="minelauncher", -- keys must be lower case
		name="Div0's byte's minelauncher",
		desc="Enable the byte minelauncher in Division Zero.",
		type="bool",
		def=true
	},
	{
		key="nx", -- keys must be lower case
		name="Div0's pointer's NX flag",
		desc="Enable the pointer NX flag in Division Zero.",
		type="bool",
		def=true
	}
}
return options
