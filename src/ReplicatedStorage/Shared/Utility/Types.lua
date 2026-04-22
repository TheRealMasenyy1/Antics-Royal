-- UnitManagerTypes.luau
-- All shared type definitions for the UnitManager system

export type StatGrade = "F" | "E" | "D" | "C" | "B" | "A" | "S" | "SS" | "SSS"

export type UnitStats = {
	Damage: StatGrade,
	Cooldown: StatGrade,
	Range: StatGrade,
}

export type TraitInfo = {
	Name: string,
	Level: number,
}

export type UpgradeStats = {
	Cost: number,
	Range: number,
	Cooldown: number,
	Damage: number?,
	Profit: number?,
	Slowness: number?,
	Buff: number?,
	[string]: any,
}

export type UpgradesTable = {
	Tags: { string }?,
	[number]: UpgradeStats,
}

export type CustomUnitInfo = {
	Traits: TraitInfo?,
	Level: number,
	UnitType: string?,
	Stats: UnitStats?,
}

export type PriorityTable = {
	First: boolean,
	Strongest: boolean,
	Weakest: boolean,
	Fastest: boolean,
}

export type TargetData = {
	Id: number,
	Character: Model,
	Health: number,
	Team: string,
	MaxHealth: number?,
}

export type BuffInfo = {
	[string]: number,
}

-- The full self type for UnitManager instances
export type UnitManagerObject = {
	-- Core references
	Unit: Model,
	Name: string,
	Owner: Player?,
	Detector: BasePart?,
	Target: Model?,
	Tree: Folder?,
	Waypoints : {[number] : PathWaypoint},

	-- Configuration
	Upgrades: UpgradesTable,
	Traits: TraitInfo?,
	Tags: { string }?,
	Type: string,
	Team: "Blue" | "Red",
	Targeting: string,
	IsShiny: boolean,
	IsRunning: boolean,
	IsActive: boolean,

	-- Level tracking
	UnitLevel: number,
	ActualLevel: number,
	Level: number,

	-- Combat stats
	Stats: UnitStats,
	Range: number,
	Cooldown: number,
	Health: number,
	Damage: number,
	DefaultDamage: number,
	TotalDamage: number,
	Moneyspent: number,
	AttackInUse: boolean,
	InCooldown: boolean,
	Attacked: boolean,

	-- Targeting state
	LastTargetPosition: Vector3,
	InsideZone: { TargetData },
	TargetsInZone: number,
	Priority: PriorityTable,

	-- Optional ability hook
	Ability: ((...any) -> ...any)?,
	AbilityForLevel: { [number]: (...any) -> ...any }?,

	-- Methods
	HandleAnimation: (self: UnitManagerObject, Action : string, Name : string) -> (),
	CheckTraits: (self: UnitManagerObject, Trait: string) -> (number?, number?),
	CreateDetector: (self: UnitManagerObject, Unit: Model, Range: number) -> BasePart,
	SetCooldown: (self: UnitManagerObject) -> (),
	Sell: (self: UnitManagerObject) -> boolean,
	GetDictionaryLength: (self: UnitManagerObject, Table: { [any]: any }) -> number,
	DecideTarget: (self: UnitManagerObject) -> Model?,
	RemoveTarget: (self: UnitManagerObject, Id: number) -> (),
	FindTarget: (self: UnitManagerObject, Id: number) -> boolean,
	LoadSound: (self: UnitManagerObject, SoundFile: Sound, Volume: number?) -> Sound,
	BuffUnit: (self: UnitManagerObject, BuffInfo: BuffInfo) -> (),
	SlowUnit: (self: UnitManagerObject, Target: Model, burnTime: number, Type: string?) -> (),
	Burn: (self: UnitManagerObject, Target: Model, burnTime: number, Type: string) -> (),
	LoadAnimation: (self: UnitManagerObject, Animation: Animation, Speed: number?) -> AnimationTrack,
	ChangeTargeting: (self: UnitManagerObject) -> string?,
	ConvertGradeInGame: (self: UnitManagerObject, UnitData: UnitDataInGame, StatName: string, Level: number?) -> (number, StatGrade, string),
	GetDamageWithBenefitsInGame: (self: UnitManagerObject, UnitData: UnitDataInGame, StatName: string) -> string,
	ConvertGrade: (self: UnitManagerObject, UnitData: UnitDataGeneric, StatName: string) -> (number, StatGrade, string),
	GetDamageWithBenefits: (self: UnitManagerObject, UnitData: UnitDataGeneric, StatName: string) -> string,
	GetGrade: (self: UnitManagerObject, StatName: string) -> (number, StatGrade),
	Upgrade: (self: UnitManagerObject, player: Player) -> (boolean, UnitManagerObject),
	GetTargets: (self: UnitManagerObject, RootPart: BasePart) -> (),
	GetBuffUnit: (self: UnitManagerObject) -> (boolean, number?),
	OnZoneTouched: (self: UnitManagerObject, Attackfunc: () -> ()) -> (),
	Destroy: (self: UnitManagerObject) -> (),
}

-- UnitData shapes used in stat conversion helpers
export type UnitDataInGame = {
	Name: string,
	Level: number,
	Stats: UnitStats,
}

export type UnitDataGeneric = {
	Unit: string,
	Level: number,
	Stats: UnitStats,
}

-- Constructor / metatable type
export type UnitManagerClass = {
	new: (Unit: Model, CustomUnitInfo: CustomUnitInfo) -> UnitManagerObject,
	__index: UnitManagerClass,

	Update: (self: UnitManagerObject) -> (),

	-- Static method references (same signatures as instance methods)
	CheckTraits: (self: UnitManagerObject, Trait: string) -> (number?, number?),
	CreateDetector: (self: UnitManagerObject, Unit: Model, Range: number) -> BasePart,
	SetCooldown: (self: UnitManagerObject) -> (),
	Sell: (self: UnitManagerObject) -> boolean,
	GetDictionaryLength: (self: UnitManagerObject, Table: { [any]: any }) -> number,
	DecideTarget: (self: UnitManagerObject) -> Model?,
	RemoveTarget: (self: UnitManagerObject, Id: number) -> (),
	FindTarget: (self: UnitManagerObject, Id: number) -> boolean,
	LoadSound: (self: UnitManagerObject, SoundFile: Sound, Volume: number?) -> Sound,
	BuffUnit: (self: UnitManagerObject, BuffInfo: BuffInfo) -> (),
	SlowUnit: (self: UnitManagerObject, Target: Model, burnTime: number, Type: string?) -> (),
	Burn: (self: UnitManagerObject, Target: Model, burnTime: number, Type: string) -> (),
	LoadAnimation: (self: UnitManagerObject, Animation: Animation, Speed: number?) -> AnimationTrack,
	ChangeTargeting: (self: UnitManagerObject) -> string?,
	ConvertGradeInGame: (self: UnitManagerObject, UnitData: UnitDataInGame, StatName: string, Level: number?) -> (number, StatGrade, string),
	GetDamageWithBenefitsInGame: (self: UnitManagerObject, UnitData: UnitDataInGame, StatName: string) -> string,
	ConvertGrade: (self: UnitManagerObject, UnitData: UnitDataGeneric, StatName: string) -> (number, StatGrade, string),
	GetDamageWithBenefits: (self: UnitManagerObject, UnitData: UnitDataGeneric, StatName: string) -> string,
	GetGrade: (self: UnitManagerObject, StatName: string) -> (number, StatGrade),
	Upgrade: (self: UnitManagerObject, player: Player) -> (boolean, UnitManagerObject),
	GetTargets: (self: UnitManagerObject, RootPart: BasePart) -> (),
	GetBuffUnit: (self: UnitManagerObject) -> (boolean, number?),
	OnZoneTouched: (self: UnitManagerObject, Attackfunc: () -> ()) -> (),
	Destroy: (self: UnitManagerObject) -> (),
}

export type activeUnit = {
	[number] : UnitManagerObject
} 

return {}

