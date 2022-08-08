-- title:  Alchemy Courier
-- author: Blind Seer Studios
-- desc:   Courier dangerous potions
-- script: lua
-- input:  gamepad
-- saveid: beta

ver="v 0.7c"
releaseBuild=true
--Simplify math operations. Floor will round a decimal down
flr=math.floor
ceil=math.ceil
rnd=math.random
cos=math.cos
rad=math.rad
sin=math.sin
max=math.max
min=math.min
del=table.remove

dc=3 --debug txt color
--Variables for the screen area
w,h=240,136
hw,hh=w/2,h/2

win={}
txt=""

indicatorsOn=false
--Setup camera coordinates
cam={
	x=0,
	y=0
}

--Collision detectors
--[[These change where the collision detectors are for
the top and sides of a sprite (Bottom can not be changed
from here. The default is every corner and middle of a 
16x16 sprite.]]
coll={
	tlx=3,
	tly=1,
	trx=11,
	try=0
}

dirs={
	{1,0},
	{-1,0},
	{0,1},
	{0,-1},
	{1,1},
	{-1,-1},
	{1,-1},
	{-1,1}
}

--Player variables
p={
	idx=256,
	x=170,--was hw
	y=96,	--was hh
	vx=0,--Velocity X
	vy=0,--Velocity Y
	--curv=0,--Current movement velocity
	vmax=1.3,--Maximum velocity
	grounded=true,
	flp=0,
	type="player",
	curLife=3,
	maxLife=3,
	coins=0,
	stab=51,
	stabPot=0,
	stabPotMax=3,
	s={
		idle=256,
		run=288,
		jump=264,
		fall=320,
		dead=270,
		thru=2,--for platforms the character can move through
		duck=322
	},
	cpX=0,
	cpY=0,
	cpF=0,--which way did the player run through the checkpoint
	cpA=false,--is a checkpoint active
	canMove=true,
	ducking=false,
	damaged=false,
	onQuest=0,
	inTown=true,
	inShop=false
}

e={
	idx=416,
	x=0,
	y=0,
	vx=0,
	vy=0,
	l=true
}

s={
	coin=240,
	check=249,
	checkact=250,
	pit=5,
	heart=244,
	startSign=114,
	interact=448
}
--Control variables to make it easier
c={
	u=0,
	d=1,
	l=2,
	r=3,
	--Game controller controls
	a=4,--z
	b=5,--x
	x=6,--a
	y=7,--s
	mxt=0,
	myt=0
}

spawns={
	[7]=32,
	[8]=0
	--[240]=432
}

t=0
ti=0 --ti is time for the animated tiles

pit=false
meterY=16 --offset for the stab rect. as it decreases
meterC=6

quest={}
qnum=0
timer=0
mapStart=0
mapEnd=472 --Change this to what the end of the map will be (this will depend on level)
mapY=0
mapEndY=136
msgbox=false
pt=0
selX=75
selY=54
desctxt=""
stabplus=0
backpack=0
loadGame=false
sky=14
keyb=1

screenShake=false

screenShake={
	active=false,
	defaultDuration=15,
	duration=15,
	power=3
}
--sp=.4
--fr=4

--[[This function allows for changing animation timing on 
tiles. If the animation needs to change run this function
for the level loaders.]]
function InitAnim(lsp,lfr)
	local sp=lsp
	local fr=lfr
	--animation table
	tileAnims={
		[240]={s=.1,f=4},--coin
		[244]={s=.1,f=5},--heart
		[176]={s=sp,f=fr},--column 1
		[180]={s=sp,f=fr},--column 2
		[184]={s=sp,f=fr},--column 3
		[192]={s=sp,f=fr},--column 1
		[196]={s=sp,f=fr},--column 2
		[200]={s=sp,f=fr},--column 3
		[208]={s=sp,f=fr},--column 1
		[212]={s=sp,f=fr},--column 2
		[216]={s=sp,f=fr},--column 3
		[224]={s=sp,f=fr},--column 1
		[228]={s=sp,f=fr},--column 2
		[232]={s=sp,f=fr} --column 3
	}
end

function Init()
	InitAnim(.4,4)
	p.cpX=p.x
	p.cpY=p.y
	ents={}
	--EntLocations()
	if releaseBuild then
		TIC=Title
	else
		TIC=Update --Update is the main game loop that needs to run after the title screen
	end
end

function OVR()
	if TIC==Update then
		HUD()
		Text()
		ShopHUD()
		Debug()
	end
end
--[[
wavelimit=136/16
function scanline(row)
	-- skygradient
	--poke(0x3fc0,190-row)
	--poke(0x3fc1,140-row)
	--poke(0x3fc2,0)
	 --screen wave
	if row>wavelimit then
		poke(0x3ff9,math.sin((time()/200+row/5))*2)
	else
		poke(0x3ff9,0)
	end
end
]]
function HUD()
	print(ver,1,130,1,false,1,true)
	--BG Rectangles
	rect(1,1,15,77,2)
	rect(15,1,65,14,2)
	--HUD border
	line(15,15,15,78,0)
	line(0,78,14,78,0)
	line(16,15,79,15,0)
	line(80,0,80,15,0)
	line(0,0,79,0,0)
	line(0,0,0,77,0)
	--Coin
	spr(449,30,4,0)
	--string.format to display 00
	print(string.format("x%02d",p.coins),39,6,0,true,1,false)
	--Potion
	rect(7,meterY,2,p.stab,meterC)
	line(7,15,8,15,0)
	line(6,16,6,65,0)
	line(9,16,9,65,0)
	line(7,66,8,66,0)
	if p.curLife==0 then
		spr(454,4,68,6)
	elseif p.stab<5 then
		spr(453,4+t%rnd(1,4),68+t%rnd(1,2),6)
		meterC=3
	elseif p.stab<15 then
		spr(453,4+t%rnd(1,2),68,6)
		meterC=7
	elseif p.stab<26 then
		spr(453,4,68,6)
		meterC=8
	else
		spr(453,4,68,6)
		meterC=10
	end
 
 if--[[(time()%500>250) and]] p.stab<=10 and p.curLife>0 then
 	xprint("WARNING!",
										40,18,{0,3},false,1,false,
										0,false,0.5)
  --print('Warning!',18,18,3)
	end
	--Hearts
	for num=1,p.maxLife do
		spr(452,-4+8*num,4,6)
	end
	
	for num=1,p.curLife do
		spr(451,-4+8*num,4,6)
	end
	--Stabilizer
	spr(455,58,4,6)
	print("x"..p.stabPot,66,6,0,true,1,false)
	if stabplus==1 then
		spr(456,58,4,7)
	end
end

function ShopHUD()
	if p.inShop then
		rect(72,51,97,34,2)
		rectb(73,52,95,32,0)
		rectb(selX,selY,43,12,0)
		rect(117,40,52,12,2)
		rectb(118,41,50,12,0)
		spr(ctrlx(),120,43,0)
		print("- Purchase",129,45,0,false,1,true)
		--Stabilizer
		spr(455,77,56,6)
		print("-",86,58,0)
		spr(240,90,56,0)
		print("x10",99,58,0)
		--Heart
		spr(244,125,56,0)
		print("-",134,58,0)
		spr(240,138,56,0)
		print("x20",147,58,0)
		--Stabilizer Plus
		spr(455,77,72,6)
		print("-",86,74,0)
		spr(456,77,72,7)
		spr(240,90,72,0)
		print("x40",99,74,0)
		if stabplus==1 then
			line(76,76,116,76,0)
		end
		--Backpack
		spr(466,125,72,7)
		print("-",134,74,0)
		--spr(456,125,72,0)
		spr(240,138,72,0)
		print("x99",147,74,0)
		if backpack==1 then
			line(124,76,164,76,0)
		end
		--Description
		AddWin(121,94,95,17,2,desctxt)
		spr(ctrlb(),162,97+math.sin(time()//90),0)
		--spr(483,162,97+math.sin(time()//90),0)
	end
end

function Debug()	
	if indicatorsOn then
		print("FPS: "..fps:getValue(),w-24,0,dc,false,1,true)
		print(ver,w-24,8,dc,false,1,true)
		print("Indicators: " ..tostring(indicatorsOn),1,0,dc,false,1,true)
		print("MaxV: "..flr(p.vy),1,8,dc,false,1,true)
		print("Grounded: "..tostring(p.grounded),48,8,dc,false,1,true)
		print("Life: "..p.curLife,48,16,dc,false,1,true)
		print("Max Life: "..p.maxLife,72,16,dc,false,1,true)
		print("Move: "..tostring(p.canMove),48,24,dc,false,1,true)
		print("Saved: "..tostring(saved),48,32,dc,false,1,true)
		print("Stab: "..tostring(p.stab),48,40,dc,false,1,true)
		print("QNum: "..qnum,48,48,dc,false,1,true)
		print("Town: "..tostring(p.inTown),48,56,dc,false,1,true)		
		print("StabMax: "..p.stabPotMax,48,64,dc,false,1,true)				
		print("Backpak: "..tostring(backpack),48,72,dc,false,1,true)						
		print("X: "..p.x//8,1,16,dc,false,1,true)
		print("Y: "..p.y//8,1,24,dc,false,1,true)
		print("Check X: "..p.cpX,1,32,dc,false,1,true)
		print("Check Y: "..p.cpY,1,40,dc,false,1,true)
		print("Pit: "..tostring(pit),1,48,dc,false,1,true)
		print("Fall: "..p.vy,1,56,dc,false,1,true)
		print("Dmgd: "..tostring(p.damaged),1,64,dc,false,1,true)
		print("Timer: "..timer,1,72,dc,false,1,true)
		print("Quest: "..tostring(p.onQuest),1,80,dc,false,1,true)
		print("-Save Data-",1,88,dc,false,1,true)
		print("HP: "..pmem(0),1,96,dc,false,1,true)
		print("Stab: "..pmem(1),1,104,dc,false,1,true)
		print("X: "..pmem(2),1,112,dc,false,1,true)
		print("Y: "..pmem(3),1,120,dc,false,1,true)
		print("Meter: "..pmem(4),1,128,dc,false,1,true)
		print("Quest: "..pmem(5),36,96,dc,false,1,true)
		print("Coins: "..pmem(6),36,104,dc,false,1,true)
		print("Stab+: "..pmem(7),36,112,dc,false,1,true)
		print("Pack: "..pmem(8),36,120,dc,false,1,true)
		--Collision indicators
		pix(p.x+coll.tlx+p.vx-cam.x,p.y%136+coll.tly+p.vy,6) --top left
		pix(p.x+coll.trx+p.vx-cam.x,p.y%136+coll.tly+p.vy,6) --top right
		pix(p.x+7+p.vx-cam.x,p.y%136+coll.tly+p.vy,15) --top mid
		pix(p.x+8+p.vx-cam.x,p.y%136+coll.tly+p.vy,15) --top mid
		pix(p.x+coll.tlx+p.vx-cam.x,p.y%136+15+p.vy,6) --bottom left
		pix(p.x+coll.trx+p.vx-cam.x,p.y%136+15+p.vy,6) --bottom right
		pix(p.x+7+p.vx-cam.x,p.y%136+16+p.vy,7) --bottom mid
		pix(p.x+8+p.vx-cam.x,p.y%136+16+p.vy,7) --bottom mid
		--On ground indicators
		pix(p.x+coll.tlx-cam.x,p.y%136+16+p.vy,12) --bottom left
		pix(p.x+coll.trx-cam.x,p.y%136+16+p.vy,12) --bottom right
		--Middle left indicators
		pix(p.x+coll.tlx+p.vx-cam.x,p.y%136+7,8) --left center
		pix(p.x+coll.tlx+p.vx-cam.x,p.y%136+8,8) --left center
		--Middle right indicators
		pix(p.x+coll.trx+p.vx-cam.x,p.y%136+7,8) --right center
		pix(p.x+coll.trx+p.vx-cam.x,p.y%136+8,8) --right center
	end
end

function Title()
	ti=ti+1
	sync(0,7,false)
	cls(12)
	--print(pt,1,9,2)--Cursor position
	if timer<=100 then
		map()
		timer=timer+1
	elseif timer>=100 then
		spr(256,w/2-64,h/2-64,11,1,0,0,16,16)
		if not menu then
		--xprint(txt,x,y,col,fixed,scale,smallfont,align,thin,blink)
			xprint("Press ".."Z".." to Start",75,126,{0,4},false,1,false,2,false,1)
			--[[if (time()%600>300) then
				spr(242,109,125,0)
			end]]
		end
		
		if btnp(c.a) and not menu then
			TIC=Menu
		end
	end
end

function Menu()
	cls(12)
	spr(256,w/2-64,h/2-64,11,1,0,0,16,16)
	keyb=pmem(10)
	
	AddWin(w/2,h/2,64,29,12,"  New Game\n\n  Options\n  Exit")
	if pmem(0)~=0 then
		print("Load Game",99,62,0,true,1,true)
	else
		print("Load Game",99,62,13,true,1,true)
	end
	tri(92,55+pt,92,61+pt,95,58+pt,2)
	--Controls how far the cursor travels
	if btnp(c.d) and pt~=18 then
		pt=pt+6
	elseif pt==18 then
		pt=18
	end
	
	if btnp(c.u) and pt~=0 then
		pt=pt-6
	elseif pt==0 then
		pt=0
	end
	
	if btnp(c.a) and pt==0 then
		loadGame=true
		TIC=Update
	elseif btnp(c.a) and pt==6 then
		if pmem(0)==0 then
			return
		else
			loadGame=true
			Load()
			TIC=Update
		end
	elseif btnp(c.a) and pt==12 then
		TIC=Options
	elseif btnp(c.a) and pt==18 then
		exit()
	end

	if keyp(52) then
		pmem(0,0)
	end
end

pto=0
sslide=110
mslide=110
function Options()
	cls(12)
	--spr(256,w/2-64,h/2-64,11,1,0,0,16,16)
	--xprint(txt,x,y,col,fixed,scale,smallfont,align,thin,blink)
	xprint("Options",12,12,{12,0},true,1,false,-1,false)
	--xprint("" to Start",75,126,{0,4},false,1,false,2,false,1)
	tri(7,31+pto,10,34+pto,7,37+pto,2)
	--Controller Prompts
	if keyb==1 then
		print("Keyboard",121,32,2)
		spr(226,185,22,0)
		spr(227,194,22,0)
		spr(242,185,31,0)
		spr(243,194,31,0)
		tri(110,34,113,31,113,37,13)
		tri(175,31,178,34,175,37,15)
	else
		print("Controller",116,32,2)
		spr(224,185,22,0)
		spr(225,194,22,0)
		spr(240,185,31,0)
		spr(241,194,31,0)
		tri(110,34,113,31,113,37,15)
		tri(175,31,178,34,175,37,13)
	end
	--Sound volume slider
	line(106,44,106,48,15)
	line(106,46,212,46,15)
	line(212,44,212,48,15)
	circ(sslide,46,3,2)
	--Music volume slider
	line(106,56,106,60,15)
	line(106,58,212,58,15)
	line(212,56,212,60,15)
	circ(mslide,58,3,2)
	--Labels	
	print("Control Prompts:",12,32,0)
	print("Sound Volume:",12,44,0)
	print("Music Volume:",12,56,0)
	print("Erase Save Data:",12,68,0)
	print("Exit",12,80,0)
	--Move selector
	if btnp(c.d) and pto~=48 then
		pto=pto+12
	elseif pto==48 then
		pto=48
	end
	
	if btnp(c.u) and pto~=0 then
		pto=pto-12
	elseif pto==0 then
		pto=0
	end
	
	if btnp(c.r) and pto==0 and keyb==1 then
		keyb=0
	elseif btnp(c.l) and pto==0 and keyb==0 then
		keyb=1
	end

	if btnp(c.r) and sslide<=201 and pto==12 then
		sslide=sslide+7
	elseif btnp(c.l) and sslide>=117 and pto==12 then
		sslide=sslide-7
	end

	if btnp(c.r) and mslide<=201 and pto==24 then
		mslide=mslide+7
	elseif btnp(c.l) and mslide>=117 and pto==24 then
		mslide=mslide-7
	end
	
	if pmem(0)~=0 then
		print("Save data found",107,68,6)
	else
		print("No save data",107,68,2)
	end
	
	if btnp(c.a) and pto==36 then
		pmem(0,0)
	end

	if btnp(c.a) and pto==48 then
		pmem(10,keyb)
		TIC=Menu
	end
end

function Main()
	--NOTE!!!--
	--[[vbank() to switch to a different palette for
	background	and characters. Once 1.0 is usable]] 
	--[[initial placement of the camera these settings 
	place	the map tile centered on the screen]]
	cam.x=p.x-120
	cam.y=p.y-113

	if cam.x<mapStart then
		cam.x=mapStart
	elseif cam.x>mapEnd-232 then
		cam.x=mapEnd-232
	end
	--this will only work for two vertical map screens
	if cam.y<mapY then
		cam.y=mapY
	--[[113 may have to change to a variable if the map
	does not process correcly when starting on a lower screen]]
	elseif cam.y>mapEndY-113 then
		cam.y=mapEndY
	end
	
	map(cam.x//8,cam.y//8,31,18,-(cam.x%8),-(cam.y%8),0,1,remap)
	
	if p.damaged then
		if (time()%300>200) then
			spr(p.idx,p.x-cam.x,p.y-cam.y,0,1,p.flp,0,2,2)
	 end
 else
 	spr(p.idx,p.x-cam.x,p.y-cam.y,0,1,p.flp,0,2,2)
 end
 
	--Scrolling only along X but loading full map grid on Y
	--map(cam.x//8,(p.y//136)*17,31,18,-(cam.x%8),-(cam.y%8),0,1,remap)
	--[[if p.damaged then
		if (time()%300>200) then 
 		spr(p.idx,p.x-cam.x,p.y%136,0,1,p.flp,0,2,2)
  end
 else
 	spr(p.idx,p.x-cam.x,p.y%136,0,1,p.flp,0,2,2)
 end]]
end

function Update()
	if loadGame then
		sync(0,0,false)
		loadGame=false
	end
	update_psystems()
	cls(sky)
	if keyp(9) and indicatorsOn==false then
		indicatorsOn=true
	elseif keyp(9) and indicatorsOn==true then
		indicatorsOn=false
	end
	if keyp(28) then
		Save()
	elseif keyp(29) then
		Load()
	end
	
	Main()
	Town()
	Player()
	Collectiables()
	CheckPoint()
	Stabilizer()
	ShakeScreen()
	Blinky()
	--Enemy()
	draw_psystems()
	
	ti=ti+1
	
	if keyp(46) then
		table.insert(quest,1)
		p.onQuest=1
	end
	--[[trying to delete entities]]
	if keyp(41) then
		for k in pairs(ents) do
			ents[k]=nil
		end
		--table.remove(ents,1)
	end
	--[[if btnp(c.u) then
		make_smoke_ps(15*8,13*8)
	end]]
end

function Player(o)
	--this enables a running
	if p.canMove and not msgbox and not p.inShop then
		if btn(c.r) and btn(c.x) then
			p.vx=p.vmax+1
			if p.grounded then
				p.idx=p.s.run+t%80//10*2
				t=time()//5
				if not p.inTown then
					p.stab=p.stab-.1
					meterY=meterY+.1
				end
			end
			p.flp=1
		elseif btn(c.l) and btn(c.x) then
			p.vx=-p.vmax-1
			if p.grounded then
				p.idx=p.s.run+t%80//10*2
				t=time()//5
				if not p.inTown then
					p.stab=p.stab-.1
					meterY=meterY+.1
				end
			end
			p.flp=0
		elseif btn(c.l) then
			p.vx=-p.vmax
			if p.grounded then
				p.idx=p.s.run+t%80//10*2
				t=time()//5
			end
			p.flp=0
		elseif btn(c.r) then 
			p.vx=p.vmax
			if p.grounded then
				p.idx=p.s.run+t%80//10*2
				t=time()//5
			end
			p.flp=1
		else
			p.vx=0
			p.idx=p.s.idle+t%40//10*2
			t=time()//30
		end
	end
	--jump
	if p.vy==0 and btnp(c.a) and p.canMove and not msgbox and not p.ducking and not p.inShop then
		p.vy=-3.6
		p.grounded=false
		if not p.inTown then
			p.stab=p.stab-1
			meterY=meterY+1
		end
		if fget(mget(p.x//8,p.y//8),5) then
			p.vy=-4.3
		end
		--psfx(o,1)
		sfx(1)
	end
	--duck
	if btn(c.d) and p.vx==0 and not msgbox and not p.inShop then
		p.idx=p.s.duck
		p.ducking=true
		p.canMove=false
		coll.tly=6
	else
		p.canMove=true
		p.ducking=false
		coll.tly=1
	end
	--crawl
	if btn(c.l) and p.ducking then
		p.ducking=true
		p.idx=p.s.duck
		p.vx=p.vx+p.vmax+1
	end

	--check if there is something beside the player
	if solid(p.x+coll.tlx+p.vx,p.y+coll.tly+p.vy,0) or 
				solid(p.x+coll.trx+p.vx,p.y+coll.tly+p.vy,0) or
				solid(p.x+coll.tlx+p.vx,p.y+15+p.vy,0) or 
				solid(p.x+coll.trx+p.vx,p.y+15+p.vy,0) or
				solid(p.x+coll.tlx+p.vx,p.y+7,0) or
				solid(p.x+coll.tlx+p.vx,p.y+8,0) or
				solid(p.x+coll.trx+p.vx,p.y+7,0) or
				solid(p.x+coll.trx+p.vx,p.y+8,0) then
		p.vx=0
	end
	--checks if you are on the ground
	if solid(p.x+coll.tlx,p.y+16+p.vy,0) or
				solid(p.x+coll.trx,p.y+16+p.vy,0) or
				solid(p.x+7+p.vx,p.y+16+p.vy,0) or
				solid(p.x+8+p.vx,p.y+16+p.vy,0) or
				--some how this triggers when you run and jump onto it
				solid(p.x+coll.tlx,p.y+16+p.vy,1) or
				solid(p.x+coll.trx,p.y+16+p.vy,1) or
				solid(p.x+7+p.vx,p.y+16+p.vy,1) or
				solid(p.x+8+p.vx,p.y+16+p.vy,1) then
		p.vy=0
		p.grounded=true
	else
		p.vy=p.vy+0.2
		p.idx=p.s.fall
		p.grounded=false
	end
	--check if something is above
	if p.vy<0 and (solid(p.x+coll.tlx+p.vx,p.y+coll.tly+p.vy,0) or 
																solid(p.x+coll.trx+p.vx,p.y+coll.tly+p.vy,0) or
																solid(p.x+7+p.vx,p.y+coll.tly+p.vy,0) or 
																solid(p.x+8+p.vx,p.y+coll.tly+p.vy,0)) then
		p.vy=0
	elseif p.vy<0 and (solid(p.x+coll.tlx+p.vx,p.y+coll.tly+p.vy,1) or 
																solid(p.x+coll.trx+p.vx,p.y+coll.tly+p.vy,1) or
																solid(p.x+7+p.vx,p.y+coll.tly+p.vy,1) or 
																solid(p.x+8+p.vx,p.y+coll.tly+p.vy,1)) then
		fset(1,1,false)
		fset(2,1,false)
		fset(3,1,false)
	end
	--[[if the sprite is tile 2 and has flag 1 either set
	as true or false]]
	if p.grounded and not btnp(c.d) and p.canMove then
		fset(1,1,true)
		fset(2,1,true)
		fset(3,1,true)
	elseif p.grounded then
		fset(1,1,false)
		fset(2,1,false)
		fset(3,1,false)
	end
	--[[so close! at 0 won't work. 1.5 kinda works]]
	if p.vy>=1.5 then
		fset(1,1,true)
		fset(2,1,true)
		fset(3,1,true)
	end
	
	if p.x<mapStart then
		p.x=mapStart
	end
	if p.x>mapEnd-8 then
		p.x=mapEnd-8
	end

	p.x=p.x+p.vx
	p.y=p.y+p.vy
	
	Pit()
	if not p.inTown then
		Damage()
	end
end

function Dead()
	--[[not sure how to handle this once the player dies?
	do they just start the level over or is it game over
	and they go back to the last save?]]
	timer=0
	if p.curLife==0 then
		Explode()
		p.canMove=false
		p.stab=0
		p.coins=0
		AddWin(w/2,h/2-30,64,24,2,"You Died!\nPress A to\nreturn to town.")
		print("Dead!",p.x-cam.x,p.y-5-cam.y,7)
		p.idx=p.s.dead
		if btnp(c.a) then
			deleteallps()
			for k in pairs(ents) do
				ents[k]=nil
			end
			p.curLife=1
			BackToTown()
		end
	end 
end
--[[should probably move the p.stab/meterY to its own
function then return it back]]
function Damage()
	if p.vy>2 then
		p.stab=p.stab-.1
		meterY=meterY+.1
	end
	if p.vy>4 then
		p.stab=p.stab-.5
		meterY=meterY+.5
	end
	--Spikes are flag 7
	if fget(mget(p.x//8+1,p.y//8+1),7) --[[and fget(mget(p.x//8,p.y//8),7)]] and not p.damaged and p.curLife>0 then
		p.stab=p.stab-5
		meterY=meterY+5
		screenShake.active=true
		p.damaged=true
		psfx(o,4)
	end
	
	if p.curLife<=0 then
		Dead()
	elseif p.stab<=0 then
		Explode()
		p.idx=p.s.dead
		p.canMove=false
		AddWin(w/2,h/2-30,84,30,2,"Oh no!\nThe potion exploded!\nPress B to\ntry again.")
		if p.stab<=0 and p.curLife>0 and btnp(c.b) then
			p.curLife=p.curLife-1
			p.x=p.cpX
			p.y=p.cpY
			p.flp=p.cpF
			p.stab=51
			meterY=16
		end
	end
end

function Blinky()
	if p.damaged and timer<=100 then
		timer=timer+1
	elseif timer>=100 then
		p.damaged=false
		timer=0
	end
end

function Stabilizer()
	if btnp(c.y) and p.stabPot>0 and p.stab>=31 and p.stab<51 then
		p.stab=51
		meterY=16
		p.stabPot=p.stabPot-1
	elseif btnp(c.y) and p.stab<31 and p.stabPot>0 then
		if stabplus then
			p.stab=p.stab+20
			meterY=meterY-20
			p.stabPot=p.stabPot-1
		else
			p.stab=p.stab+15
			meterY=meterY-15
			p.stabPot=p.stabPot-1
		end
	end
end

function SingleEnemy()
	--Set initial velocity
	e.vx=0
	--[[if on solid ground move left,if velocity becomes 0
	set moving left to false and move in the other direction]]
	if solid(e.x+1,e.y+16+e.vy) and e.l then
		e.vx=e.vx-0.2
	elseif e.vx==0 then
		e.l=false
	end
	
	if solid(e.x+14,e.y+16+e.vy) and not e.l then
		e.vx=e.vx+0.2
	elseif e.vx==0 then
		e.l=true
	end
	--apply movement to the enemy
	e.x=e.x+e.vx
end

function Pit()
	if fget(mget(p.x//8+1,p.y//8),6) then
	--if mget(p.x//8+1,p.y//8)==s.pit then
		if p.cpA then
			p.x=p.cpX
			p.y=p.cpY
			p.flp=p.cpF
			sfx(5)
		else
			p.x=54
			p.y=112 --These should be beginning of level
		end
		p.curLife=p.curLife-1
	end
end

function CheckPoint()
	if mget(p.x//8+1,p.y//8+1)==s.check then
		mset(p.x//8+1,p.y//8+1,s.checkact)
		p.cpX=flr(p.x)
		p.cpY=flr(p.y)
		p.cpF=p.flp
		p.cpA=true
		psfx(o,19)
	end
end

function Collectiables()
	--[[Collisions with collectibles can be done either with
	flags set on the sprites,or by looking for the actual
	sprite itself.]]
	--rectb(p.x-1,p.y+1,8,8,7)
	if (mget(p.x//8+1,p.y//8+1)==s.coin or mget(p.x//8,p.y//8)==s.coin) and p.coins<99 then
		mset(p.x//8+1,p.y//8+1,0)
		mset(p.x//8,p.y//8,0)
		p.coins=p.coins+1
		--psfx(o,18)
		--table.remove(ents,i)
		sfx(18)
	end
	if (mget(p.x//8+1,p.y//8+1)==s.heart or mget(p.x//8,p.y//8)==s.heart) and p.curLife<3 then
		mset(p.x//8+1,p.y//8+1,0)
		mset(p.x//8,p.y//8,0)
		p.curLife=p.curLife+1
		--table.remove(ents,i)
		--sfx(01,'E-6',5)
	end
end

function Text()
	if msgbox==true then
		AddWin(hw,hh,128,65,2,txt)
		--spr(Ctrlspr(sprtb),178,95+math.sin(time()//90),0)
		spr(ctrlb(),178,95+math.sin(time()//90),0)
	end
end

function Town()
	switch(action,
		case(quest[1],function() NoQuest() end),
		case(quest[2],function() TownOne() end),
		case(quest[3],function() TownTwo() end),
		case(quest[4],function() TownThree() end),
		case(quest[5],function() ForestOne() end),
		default(function() print("End of table",w/2,0,7) end)
	)
	--Print out all the values in the quest table.
	--[[for counter=1,#quest do
		print(quest[counter],w/2,(counter*8),7)
	end]]
	
	--[[When the town loads it is spawning ents to the whole map on bank 0
	this is not affecting ents on bank 1 unsure why not]]
	--EntLocations()
	
	while qnum>0 do
		table.insert(quest,1)
		qnum=qnum-1
	end
	--quest giver sprite
	if p.inTown then
		spr(464,24-cam.x,88-cam.y,0,1,0,0,2,3)
		--shop keeper sprite
		spr(459,440-cam.x,80-cam.y,0,1,0,0,3,4)
	end
	--display interact bubble
	if mget(p.x//8,p.y//8)==7 or mget(p.x//8,p.y//8)==8 or mget(p.x//8,p.y//8)==9 then
		spr(448,p.x-cam.x+4,p.y-cam.y-8+math.sin(time()//90),0)
	end
	
	if (mget(p.x//8,p.y//8)==s.startSign or mget(p.x//8+2,p.y//8)==s.startSign or mget(p.x//8+1,p.y//8)==s.startSign) and p.onQuest==1 then
		spr(ctrlx(),p.x-cam.x+4,p.y-cam.y-8+math.sin(time()//90),0)		
	end
	--
	if (fget(mget(p.x//8,p.y//8),2) or fget(mget(p.x//8-1,p.y//8+1),2)) and btnp(c.a) and p.onQuest==0 and not msgbox then
		p.canMove=false
		msgbox=true
		p.onQuest=1
		table.insert(quest,"On quest")
		--for k in pairs(ents) do
		--	ents[k]=nil
		--end
	elseif fget(mget(p.x//8,p.y//8),2) and btnp(c.b) then
		p.canMove=true
		msgbox=false
	end
	
	if fget(mget(p.x//8,p.y//8),3) then
		p.onQuest=0
	end
	--Shop
	if (fget(mget(p.x//8,p.y//8),4) or fget(mget(p.x//8-1,p.y//8+1),4)) and btnp(c.a) and not p.inShop then
		p.canMove=false
		p.inShop=true
	elseif fget(mget(p.x//8,p.y//8),4) and btnp(c.b) and p.inShop then
		p.canMove=true
		p.inShop=false
	end
	if p.inShop then
		Shop()
	end
	--[[if keyp(13) and not p.inShop then
 	p.inShop=true
  p.canMove=false
 elseif keyp(13) and p.inShop then
 	p.inShop=false
  p.canMove=true
 end]]
 --Shop()
end

function Shop()	
	if p.inShop then
		if btnp(c.r) then
			selX=75+48
		elseif btnp(c.d) then
			selY=54+16
		elseif btnp(c.l) then
			selX=123-48
		elseif btnp(c.u) then
			selY=70-16
		end
		
		if selX==75 and selY==54 then
			desctxt="Adds Stabilizer"
			if btnp(c.x) and p.coins>=10 and p.stabPot<p.stabPotMax then
				p.stabPot=p.stabPot+1
				p.coins=p.coins-10
			end
		elseif selX==123 and selY==54 then
			desctxt="Fills one heart"
			if btnp(c.x) and p.coins>=50 and p.curLife<3 then
				p.curLife=p.curLife+1
				p.coins=p.coins-20
			end 
		elseif selX==75 and selY==70 then
			if stabplus==0 then
				desctxt="Stabilizers are\nmore effective"
			else
				desctxt="Out of stock"
			end
			if btnp(c.x) and p.coins>=40 and stabplus==0 then
				stabplus=1
				p.coins=p.coins-40
			end
		elseif selX==123 and selY==70 then
			if backpack==0 then
				desctxt="Bigger backpack. Holds\nmore stabilizers"
			else
				desctxt="Out of stock"
			end
			if btnp(c.x) and p.coins>=99 and backpack==0 then
				p.stabPotMax=6
				backpack=1
				p.coins=p.coins-1
			end
		end
	end
end

function NoQuest()
	print("No quest",w/2,0,7)
end

function TownOne()
	print("Town 1",w/2,0,7)
	spr(478,(176*8)-cam.x,(11*8)-cam.y,0,1,0,0,2,3)
	if p.onQuest==1 then
		txt="Courier,\nPlease take this potion to\nJanna at the edge of the\nforest. Please be careful\nand not break it. We don't\nwant to have what\nhappened last time."
	end
	
	--Sign
	--spr(192,78-cam.x,112-cam.y,0,1,0,0,1,2)
	if (mget(p.x//8,p.y//8)==s.startSign or mget(p.x//8+2,p.y//8)==s.startSign or mget(p.x//8+1,p.y//8)==s.startSign) and p.onQuest==1 and btnp(c.x) then
		MapCoord(60,179,0,136,64,12)
		p.cpX=p.x
		p.cpY=p.y
		p.cpF=p.flp
		p.cpA=true
		p.inTown=false
	end
	
	if fget(mget(p.x//8,p.y//8),3) and btnp(c.a) and not msgbox then
		txt="Thank you!\nThis will work nicely."
		msgbox=true
	elseif fget(mget(p.x//8,p.y//8),3) and btnp(c.b) then
		msgbox=false
		BackToTown()
	end
end

function TownTwo()
	print("Town 2",w/2,0,7)
	if p.onQuest==1 then
		txt="Quest text goes here"
	end
	spr(473,(124*8)-cam.x,(28*8)-cam.y,0,1,0,0,2,3)
	if (mget(p.x//8,p.y//8)==s.startSign or mget(p.x//8+2,p.y//8)==s.startSign or mget(p.x//8+1,p.y//8)==s.startSign) and p.onQuest==1 and btnp(c.x) then
		MapCoord(180,239,0,17,183,7)
		p.cpX=p.x
		p.cpY=p.y
		p.cpF=p.flp
		p.cpA=true
		p.inTown=false
		EntLocations()
	end
	
	Enemy()
	
	if p.y>136 then
		mapStart=120*8
	end
	
	if fget(mget(p.x//8,p.y//8),3) and btnp(c.a) and not msgbox then
		txt="Some platitude goes here"
		msgbox=true
	elseif fget(mget(p.x//8,p.y//8),3) and btnp(c.b) then
		msgbox=false
		BackToTown()
	end
end

function TownThree()
	print("Town 3",w/2,0,7)
	if p.onQuest==1 then
		txt="Quest text goes here"
	end
	spr(473,(124*8)-cam.x,(28*8)-cam.y,0,1,0,0,2,3)
	if (mget(p.x//8,p.y//8)==s.startSign or mget(p.x//8+2,p.y//8)==s.startSign or mget(p.x//8+1,p.y//8)==s.startSign) and p.onQuest==1 and btnp(c.x) then
		MapCoord(0,239,17,34,6,26)
		p.cpX=p.x
		p.cpY=p.y
		p.cpF=p.flp
		p.cpA=true
		p.inTown=false
		EntLocations()
	end
	
	Enemy()
	
	if fget(mget(p.x//8,p.y//8),3) and btnp(c.a) and not msgbox then
		txt="Some platitude goes here"
		msgbox=true
	elseif fget(mget(p.x//8,p.y//8),3) and btnp(c.b) then
		for k in pairs(ents) do
			ents[k]=nil
		end
		msgbox=false
		BackToTown()
	end
end

function ForestOne()
	--for k in pairs(ents) do
	--	ents[k]=nil
	--end
	
	print("Forest 1",w/2,0,7)
	if p.onQuest==1 then
		txt="Quest text goes here"
	end
	spr(473,(124*8)-cam.x,(28*8)-cam.y,0,1,0,0,2,3)
	if (mget(p.x//8,p.y//8)==s.startSign or mget(p.x//8+2,p.y//8)==s.startSign or mget(p.x//8+1,p.y//8)==s.startSign) and p.onQuest==1 and btnp(c.x) then
		InitAnim(.2,4)
		make_smoke_ps(14*8,15*8)	
		make_smoke_ps(17*8,15*8)	
		sync(0,1,false)
		sky=13
		MapCoord(0,239,0,17,8,10)
		p.cpX=p.x
		p.cpY=p.y
		p.cpF=p.flp
		p.cpA=true
		p.inTown=false
		EntLocations()
	end
	
	Enemy()
	
	if fget(mget(p.x//8,p.y//8),3) and btnp(c.a) and not msgbox then
		txt="Some platitude goes here"
		msgbox=true
	elseif fget(mget(p.x//8,p.y//8),3) and btnp(c.b) then
		msgbox=false
		BackToTown()
	end
end

function BackToTown()
	sync(0,0,false)
	MapCoord(0,59,0,0,21,12)
	p.flp=0
	p.stab=51
	meterY=16
	p.inTown=true
	sky=14
	Save()
end

function Save()
	--[[pmem
	pmem index -> val Retrieve data from persistent memory
	pmem index val -> val Save data to persistent memory
	]]
	--[[pmem can only store ints so floats have to be floored
	or ceiling]]
	local savStab=ceil(p.stab)
	local savMeter=ceil(meterY)-1
	local savX=flr(p.x)
	local savY=flr(p.y)
	--pmem(saveScoreIdx,bestScore)
 --bestScore=pmem(saveScoreIdx)
	pmem(0,p.curLife)
	pmem(1,savStab)
	pmem(2,savX)
	pmem(3,savY)	
	pmem(4,savMeter)
	pmem(5,#quest)
	pmem(6,p.coins)
	pmem(7,stabplus)
	pmem(8,backpack)
	pmem(9,p.onQuest)
end

function Load()
	p.curLife=pmem(0)
	p.stab=pmem(1)
	p.x=pmem(2)
	p.y=pmem(3)
	meterY=pmem(4)
	qnum=pmem(5)
	p.coins=pmem(6)
	stabplus=pmem(7)
	backpack=pmem(8)
	p.onQuest=pmem(9)
end

function AddEnt(t)
	table.insert(ents,{
		t=t.t or 0,
		x=t.x,
		y=t.y,
		vx=t.vx or 0,
		vy=t.vy or 0,
		l=t.l,
		flp=t.flp,
		spr=t.spr,
		type=t.type or "normal",
	})
end

function EntLocations()
	for x=0,240 do
		for y=0,136 do
			--if spawns[mget(x,y)] then
			--	mset(x,y,32)
			if mget(x,y)==160 then
			--if spawns[mget(x,y)] then
				AddEnt({spr=(mget(x,y)+256),x=x*8,y=y*8,type="flier"})
			elseif mget(x,y)==128 then
				AddEnt({spr=(mget(x,y)+256),x=x*8,y=y*8,type="blob"})
			end
		end
	end
end

function Enemy()
	for i,e in pairs(ents) do
		e.vx=0
		
		if e.type=="flier" then
			--[[if on solid ground move left,if velocity becomes 0
			set moving left to false and move in the other direction]]
			if not solid(e.x-1,e.y+15+e.vy,0) and solid(e.x+1,e.y+24+e.vy) and e.l then
				e.vx=e.vx-0.3
			elseif e.vx==0 then
				e.l=false
				e.flp=1
			end
			
			if not solid(e.x+14,e.y+15+e.vy,0) and solid(e.x+14,e.y+24+e.vy) and not e.l then
				e.vx=e.vx+0.3
			elseif e.vx==0 then
				e.l=true
				e.flp=0
			end
			--apply movement to the enemy
			e.x=e.x+e.vx
			--Draw the sprite and replace the map tile
			spr(e.spr+ti%40//10*2,e.x-cam.x,e.y-cam.y,0,1,e.flp,0,2,2)
			if mget(e.x//8,e.y//8)==160 then
				mset(e.x/8,e.y/8,0)
			end
			if indicatorsOn then
				print("x"..e.x//8,e.x-cam.x,e.y-13-cam.y,0,false,1,true)
				print("y"..e.y//8,e.x-cam.x,e.y-7-cam.y,0,false,1,true)
				
				print("x"..p.x//8,p.x-cam.x,p.y-13-cam.y,0,false,1,true)
				print("y"..p.y//8,p.x-cam.x,p.y-7-cam.y,0,false,1,true)
			end
			
			--should eventually update this to use the actual player collider
			if e.x//8==p.x//8 and (e.y//8==p.y//8 or e.y//8+1==p.y//8+1 or e.y//8+1==p.y//8) and not p.damaged and not p.ducking then
				print("hit",p.x-8-cam.x,p.y-cam.y,7)
				p.stab=p.stab-10
				meterY=meterY+10
				screenShake.active=true
				p.damaged=true
			end
		end
		
		if e.type=="blob" then
		
			if not solid(e.x-1,e.y+15+e.vy,0) and solid(e.x+1,e.y+16+e.vy) and e.l then
				e.vx=e.vx-0.3
			elseif e.vx==0 then
				e.l=false
				e.flp=0
			end
			
			if not solid(e.x+14,e.y+15+e.vy,0) and solid(e.x+14,e.y+16+e.vy) and not e.l then
				e.vx=e.vx+0.3
			elseif e.vx==0 then
				e.l=true
				e.flp=1
			end
			e.x=e.x+e.vx
			
			if indicatorsOn then
				print("x"..e.x//8,e.x-cam.x,e.y-13-cam.y,0,false,1,true)
				print("y"..e.y//8,e.x-cam.x,e.y-7-cam.y,0,false,1,true)
			end
			
			spr(e.spr+ti%40//10*2,e.x-cam.x,e.y-cam.y,0,1,e.flp,0,2,2)
			if mget(e.x/8,e.y/8)==128 then
				mset(e.x/8,e.y/8,0)
			end
			--if (e.x//8==p.x//8 or e.x//8+1==p.x//8+1 or e.x//8==p.y//8+1 or e.x//8+1==p.y//8+1) and (e.y//8==p.y//8 or e.y//8==p.y//8+1 or e.y//8+1==p.y//8) and not p.damaged then
			if (e.x//8==p.x//8 and e.y//8==p.y//8) or (e.x//8+1==p.x//8 and e.y//8+1==p.y//8) and not p.damaged and p.curLife>0 then
				print("hit",p.x-8-cam.x,p.y-cam.y,7)
				p.stab=p.stab-1
				meterY=meterY+1
				screenShake.active=true
				p.damaged=true
			end
		end
	end --for
end

Init()

--Tools

--Particle system
particle_systems={}

-- Call this,to create an empty particle system,and then fill the emittimers,emitters,
-- drawfuncs,and affectors tables with your parameters.
function make_psystem(minlife,maxlife,minstartsize,maxstartsize,minendsize,maxendsize)
	local ps={
	-- global particle system params

	-- if true,automatically deletes the particle system if all of it's particles died
	autoremove=true,

	minlife=minlife,
	maxlife=maxlife,

	minstartsize=minstartsize,
	maxstartsize=maxstartsize,
	minendsize=minendsize,
	maxendsize=maxendsize,

	-- container for the particles
	particles={},

	-- emittimers dictate when a particle should start
	-- they called every frame,and call emit_particle when they see fit
	-- they should return false if no longer need to be updated
	emittimers={},

	-- emitters must initialize p.x,p.y,p.vx,p.vy
	emitters={},

	-- every ps needs a drawfunc
	drawfuncs={},

	-- affectors affect the movement of the particles
	affectors={},
	}

	table.insert(particle_systems,ps)

	return ps
end

-- Call this to update all particle systems
function update_psystems()
	local timenow=time()
	for key,ps in pairs(particle_systems) do
		update_ps(ps,timenow)
	end
end

-- updates individual particle systems
-- most of the time,you don't have to deal with this,the above function is sufficient
-- but you can call this if you want (for example fast forwarding a particle system before first draw)
function update_ps(ps,timenow)
	for key,et in pairs(ps.emittimers) do
		local keep=et.timerfunc(ps,et.params)
		if not keep then
			table.remove(ps.emittimers,key)
		end
	end

	for key,p in pairs(ps.particles) do
		p.phase=(timenow-p.starttime)/(p.deathtime-p.starttime)

		for key,a in pairs(ps.affectors) do
			a.affectfunc(p,a.params)
		end

		p.x=p.x+p.vx
		p.y=p.y+p.vy

		local dead=false
		if (p.x<0 or p.x>240 or p.y<0 or p.y>136) then
			dead=true
		end

		if timenow>=p.deathtime then
			dead=true
		end

		if dead then
			table.remove(ps.particles,key)
		end
	end

	if (ps.autoremove and #ps.particles<=0) then
		local psidx=-1
		for pskey,pps in pairs(particle_systems) do
			if pps==ps then
				table.remove(particle_systems,pskey)
				return
			end
		end
	end
end
-- draw a single particle system
function draw_ps(ps,params)
	for key,df in pairs(ps.drawfuncs) do
		df.drawfunc(ps,df.params)
	end
end

function draw_ps_pixel(ps,params)
	for key,p in pairs(ps.particles) do
		cs=math.floor(p.phase*#params.colors)+1
		pix(p.x,p.y,params.colors[cs])
	end
end
-- draws all particle system
-- This is just a convinience function,you probably want to draw the individual particles,
-- if you want to control the draw order in relation to the other game objects for example
function draw_psystems()
	for key,ps in pairs(particle_systems) do
		draw_ps(ps)
	end
end
-- This need to be called from emitttimers,when they decide it is time to emit a particle
function emit_particle(psystem)
	local p={}

	local ecount=nil
	local e=psystem.emitters[math.random(#psystem.emitters)]
	e.emitfunc(p,e.params)

	p.phase=0
	p.starttime=time()
	p.deathtime=time()+frnd(psystem.maxlife-psystem.minlife)+psystem.minlife

	p.startsize=frnd(psystem.maxstartsize-psystem.minstartsize)+psystem.minstartsize
	p.endsize=frnd(psystem.maxendsize-psystem.minendsize)+psystem.minendsize

	table.insert(psystem.particles,p)
end

function frnd(max)
	return math.random()*max
end

function make_smoke_ps(ex,ey)
	local ps=make_psystem(200,2000,1,3,6,9)
	
	ps.autoremove=false

	table.insert(ps.emittimers,
		{
			timerfunc=emittimer_constant,
			params={nextemittime=time(),speed=100}
		}
	)
	table.insert(ps.emitters,
		{
			emitfunc=emitter_box,
			params={minx=ex-4,maxx=ex+14,miny=ey,maxy=ey+2,minstartvx=0,maxstartvx=0,minstartvy=0,maxstartvy=0}
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc=draw_ps_fillcirc,
			params={colors={13,14,15}}
		}
	)
	table.insert(ps.affectors,
		{ 
			--affectfunc=affect_force,
			--params={fx=0.003,fy=-0.009 }
			affectfunc=affect_forcezone,
			params={fx=0.003,fy=-0.009,zoneminx=0--[[64]],zonemaxx=127,zoneminy=64,zonemaxy=100}
		}
	)
end

function make_explosion_ps(ex,ey)
	local ps=make_psystem(100,500,9,14,1,3)
	
	table.insert(ps.emittimers,
		{
			timerfunc=emittimer_burst,
			params={ num=3 }
		}
	)
	table.insert(ps.emitters,
		{
			emitfunc=emitter_box,
			params={ minx=ex-4,maxx=ex+4,miny=ey-4,maxy= ey+4,minstartvx=0,maxstartvx=0,minstartvy=0,maxstartvy=0 }
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc=draw_ps_fillcirc,
			params={ colors={2,3,4} }
		}
	)
end

function make_explosmoke_ps(ex,ey)
	local ps=make_psystem(1500,2000,5,8,17,18)

	table.insert(ps.emittimers,
		{
			timerfunc=emittimer_burst,
			params={ num=1 }
		}
	)
	table.insert(ps.emitters,
		{
			emitfunc=emitter_point,
			params={ x=ex,y=ey,minstartvx=0,maxstartvx=0,minstartvy=0,maxstartvy=0 }
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc=draw_ps_fillcirc,
			params={ colors={3} }
		}
	)
	table.insert(ps.affectors,
		{ 
			affectfunc=affect_force,
			params={ fx=0.003,fy=-0.01 }
		}
	)
end

function make_explosparks_ps(ex,ey)
	local ps=make_psystem(300,700,1,2,0.5,0.5)
	
	table.insert(ps.emittimers,
		{
			timerfunc=emittimer_burst,
			params={ num=10}
		}
	)
	table.insert(ps.emitters,
		{
			emitfunc=emitter_point,
			params={ x=ex,y=ey,minstartvx=-1.5,maxstartvx=1.5,minstartvy=-1.5,maxstartvy=1.5 }
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc=draw_ps_pixel,
			params={ colors={1,2,3} }
		}
	)
	table.insert(ps.affectors,
		{ 
			affectfunc=affect_force,
			params={ fx=0,fy=0.1 }
		}
	)
end

-- EMIT TIMERS ==================================================--
function emittimer_burst(ps,params)
	for i=1,params.num do
		emit_particle(ps)
	end
	return false
end
-- Emits a particle every "speed" time
-- params:
-- speed - time between particle emits
function emittimer_constant(ps,params)
	if (params.nextemittime<=time()) then
		emit_particle(ps)
		params.nextemittime=params.nextemittime+params.speed
	end
	return true
end

-- EMITTERS =====================================================--

function emitter_point(p,params)
	p.x=params.x
	p.y=params.y

	p.vx=frnd(params.maxstartvx-params.minstartvx)+params.minstartvx
	p.vy=frnd(params.maxstartvy-params.minstartvy)+params.minstartvy
end
-- Emits particles from the surface of a rectangle
-- params:
-- minx,miny and maxx,maxy - the corners of the rectangle
-- minstartvx,minstartvy and maxstartvx,maxstartvy - the start velocity is randomly chosen between these values
function emitter_box(p,params)
	p.x=frnd(params.maxx-params.minx)+params.minx
	p.y=frnd(params.maxy-params.miny)+params.miny

	p.vx=frnd(params.maxstartvx-params.minstartvx)+params.minstartvx
	p.vy=frnd(params.maxstartvy-params.minstartvy)+params.minstartvy
end

-- AFFECTORS ====================================================--

-- Constant force applied to the particle troughout it's life
-- Think gravity,or wind
-- params: 
-- fx and fy - the force vector
function affect_force(p,params)
	p.vx=p.vx+params.fx
	p.vy=p.vy+params.fy
end

-- A rectangular region,if a particle happens to be in it,apply a constant force to it
-- params: 
-- zoneminx,zoneminy and zonemaxx,zonemaxy - the corners of the rectangular area
-- fx and fy - the force vector
function affect_forcezone(p,params)
	if (p.x>=params.zoneminx and p.x<=params.zonemaxx and p.y>=params.zoneminy and p.y<=params.zonemaxy) then
		p.vx=p.vx+params.fx
		p.vy=p.vy+params.fy
	end
end

-- DRAW FUNCS ===================================================--

-- Filled circle particle drawer,the particle animates it's size and color trough it's life
-- params:
-- colors array - indexes to the palette,the particle goes trough these in order trough it's lifetime
-- startsize and endsize is coming from the particle system parameters,not the draw func params!
function draw_ps_fillcirc(ps,params)
	for key,p in pairs(ps.particles) do
		cs=math.floor(p.phase*#params.colors)+1
		r=(1-p.phase)*p.startsize+p.phase*p.endsize
		circ(p.x-cam.x,p.y-cam.y,r,params.colors[cs])
	end
end

function Explode()
	local rx=p.x+8
	local ry=p.y+8
	make_explosmoke_ps(rx,ry)
	make_explosparks_ps(rx,ry)
	make_explosion_ps(rx,ry)
end

function deleteallps()
	for key,ps in pairs(particle_systems) do
		particle_systems[key] = nil
	end
end

function MapCoord(ms,me,myt,myb,px,py)
	mapStart=ms*8
	mapEnd=me*8
	mapY=myt*8
	mapEndY=myb*8 --this is the top of the map screen of the bottom y map screen
	p.x=px*8
	p.y=py*8
end

function psfx(o,i)
	if p.type=="player" then
		sfx(i)
	end 
end

function remap(animTile)
	local outTile,flip,rotate=animTile,0,0
	local at=tileAnims[animTile]
	if at then
		outTile=outTile+flr(ti*at.s)%at.f
	end
	return outTile,flip,rotate
end

function switch(n,...)
	for _,v in ipairs{...} do
		if v[1]==n or v[1]==nil then
			return v[2]()
		end
	end
end

function case(n,f)
	return {n,f}
end

function default(f)
	return{nil,f}
end
--this returns the x,y and flag for tile collisions
function solid(x,y,f)
	return fget(mget(flr(x//8),flr(y//8)),f)
end

function ShakeScreen()
 if screenShake.active==true then
		poke(0x3FF9,rnd(-screenShake.power,screenShake.power))
		poke(0x3FF9+1,rnd(-screenShake.power,screenShake.power))
		screenShake.duration=screenShake.duration-1
		
		if screenShake.duration<=0 then
			screenShake.active=false
		end
 else
  memset(0x3FF9,0,2)
  screenShake.active=false
  screenShake.duration=screenShake.defaultDuration
	end
end

function AddWin(x,y,w,h,col,txt)
	for i=1,#win do
		table.insert(win,i,#win)
	end
	rect(x-w/2,y-h/2,w,h,col)
	rectb(x-w/2+1,y-h/2+1,w-2,h-2,0) --no idea but it works
 print(txt,x-w/2+3,y-h/2+3,0,1,1,true)
end

function DrawWin()
	for w in pairs(win) do
		rect(w.x,w.y,w.w,w.h,2)
	end
end

function Timer(c)
	if(time()>c)then
  return c
 end
end

function ctrlb()
	--a/z
	--b/x
	--x/a
	--y/s
	sprt=0
	if keyb==1 then
		sprt=501
	else
		sprt=483
	end
	return sprt
end

function ctrla()
	--a/z
	--b/x
	--x/a
	--y/s
	sprt=0
	if keyb==1 then
		sprt=500
	else
		sprt=482
	end
	return sprt
end

function ctrlx()
	--a/z
	--b/x
	--x/a
	--y/s
	sprt=0
	if keyb==1 then
		sprt=484
	else
		sprt=498
	end
	return sprt
end

function ctrly()
	--a/z
	--b/x
	--x/a
	--y/s
	sprt=0
	if keyb==1 then
		sprt=485
	else
		sprt=499
	end
	return sprt
end

function xprint(txt,x,y,col,fixed,scale,smallfont,align,thin,blink)
	
	--[[
		txt=string 
			this is the only obligatory 
			argument. All others are	optional;
		
		x,y=coordinates;
		
		col=color
			number for borderless,
			table for outlined;
		
		fixed, scale, smallfont:
			same as in the	default TIC-80 
			print function;
			
		align=-1(left),0(center),1(right);
		
		thin=true/false
			outline thickness;
		
		blink=number (frequency of blinking)
	--]]
	
	if blink then
		if ti%(60*blink)//(30*blink)==1 then 
			return
		end
	end
	
	if not x then
		x=120
		align=0
	end
	if not y then 
		y=63
	end
	
	if not col then 
		col={12,0} 
	end
	if type(col)=="number" then
		col={col}
	end
	
	if not scale then scale=1 end
	
	local width=print(txt,0,-100,0,fixed,
														scale,smallfont)
	local posx=x
	if align==0 then
		posx=x-(width//2)
	elseif align==1 then
		posx=x-width
	end
	
	if col[2] then
		local len=8
		if thin then len=4 end
		for o=1,len do
			print(txt,posx+dirs[o][1],
				y+dirs[o][2],col[2],fixed,scale,
				smallfont)
		end
	end
	
	print(txt,posx,y,col[1],fixed,scale,
		smallfont)

end

FPS={}

function FPS:new(o)
	o=o or {}
	setmetatable(o,self)
	self.__index=self
	self.value=0
	self.frames=0
	self.lastTime=0
	return FPS
end

function FPS:getValue()
	if (time()-self.lastTime<=1000) then
		self.frames=self.frames+1
	else
		self.value=self.frames
		self.frames=0
		self.lastTime=time()
	end
	return self.value
end

fps=FPS:new()
-- <TILES>
-- 001:888888867777777677777776cccccccc00cccccc0cccccc0c5555c005555c000
-- 002:888888887777777777777777cccccccc00000000000000000000000000000000
-- 003:688888886777777767777777cccccccccccccc000cccccc000c5555c000c5555
-- 004:0000000000000000000770000077770000777700000770000000000000000000
-- 005:7777777770000007700000077000000770000007700000077000000777777777
-- 006:0000000000000000000000000000000000077000007007000700007070000007
-- 007:7777717777777177777771771111111177177777771777777717777711111111
-- 008:7777717777777177777771771111111177177777771777777717777711111111
-- 009:7777717777777177777771771111111177177777771777777717777711111111
-- 010:eeeeeeeee0cccc0ee0c0000ee0ccc00ee0000c0ee0c00c0ee00cc00eeeeeeeee
-- 011:eeeeeeeee00cc00ee0c0000ee0ccc00ee0c00c0ee0c00c0ee00cc00eeeeeeeee
-- 012:8888888677777776777777767777777607777776007777760007777600007776
-- 013:888888887777777777777777777777636666cc347777c3447777c3447777c344
-- 014:8888888877777777777777773677776343cccc34443cc3444433334444333344
-- 015:8888888877777777777777773677777743cc6666443c7777443c7777443c7777
-- 016:bbbabbbbbb9bbbbbb999bbbbaaa99bbbaa9aa9bba9aaaaabcaaaaaaaccaaaaaa
-- 017:bbbabbbbbbbb9bbbbbb999bbbb99aaabb9aaaaaaa9aaaaaaaacaaaaaacccaaac
-- 018:0022222002222222222020222022020202202022020202000020000000020022
-- 019:2022220022222220202022220202022200002022000002022000200000020000
-- 020:0000000000000000000000002220000020220000020200000020000002000000
-- 021:000aaabb0000aadb00000aad000000aa0000000a000000cc00000ddc0000dddd
-- 022:bbaaa000bdaa0000daa00000aa000000a0000000cc000000cdd00000dddd0000
-- 023:7777717777777177777771771111111177177777771777777717777711111111
-- 024:7777717777777177777771771111111177177777771777777717777711111111
-- 025:7777717777777177777771771111111177177777771777777717777711111111
-- 028:6888888867777777677777776777777767777770677777006777700067770000
-- 029:7777c3447777c3437777c3cc7777ccc37777cc347777c3447777c3447777c344
-- 030:4433334434333343cc3333cc3cc33cc343cccc34443cc3444433334444333344
-- 031:443c7777343c7777cc3c77773ccc777743cc7777443c7777443c7777443c7777
-- 032:9ccaaaaa999caaac999c9a9999c999999ccc9999ccccc999cccccc99ccccccc9
-- 033:cc999a9999c99999999c99999999c999999ccc9999ccccc99ccccccccccccccc
-- 034:0009900080099c99880c77998a9977c08a99c9900a0d099800d08a8000daa800
-- 035:00000000000000bb00bbb0bb00bbabbb000bbbbb0bababab0abbbabb00ababab
-- 036:0000bb000bb0bbb0bbb0bbb0abbbababbbbbbbbbababababbabababaabababab
-- 037:00009900bb909990bb9bbb90ababab99bbbbb999abababa9bababab9aaabaa99
-- 038:0000000099000000990999009999990099999000999999909999999099999900
-- 039:5555555556666666566666661555565577175677771756777717567711115611
-- 040:5555555566666666666666661655555576577777765777777657777716511111
-- 041:5555555566666665666666655565555177657777776577777765777711651111
-- 044:88888888cc888888cccc8888ccccc888cccccc88cccccc88cccc6cc8cccc6cc8
-- 045:7777c3446666c343777777777777777777777777888888886666666666666666
-- 046:4433334434333343777777777777777777777777888888886666666666666666
-- 047:443c7777343c6666777777777777777777777777888888886666666666666666
-- 048:6666c5556665c555666c5555666c5555666c5555666c55556665c5556666c555
-- 049:5555666655566666555666665556666655566666555666665556666655556666
-- 050:000440004434400844773088037744a8044344a88440d0a008a80d00008aad00
-- 051:0abababa0baaabaa099ababa00aaaaaa99aabaaa99aa9aaa09999aa900099999
-- 052:babababaabaaabaababababaaaaaaaaabaaabaaa9aaa9aaa9aaa9aa999aa9999
-- 053:bababab9abaaaaa9babaa999aaaaaa99aaaaaa99aaa9aa999aa9999999999999
-- 054:9999990099999990999999909999900099999999999999999999999099999000
-- 056:00000000000000000000000000000000000000770777776606666666066666cc
-- 057:77700000776000006660000065500000777777706666666066666660cccc6550
-- 058:000022aa0aaa22aa0022772200227722aaa922aa0aaa22aa00aa8aaa009888a8
-- 059:88800000a89aaa00a9aaa00088822000a8a22aaaa2277220822772208aa22a00
-- 060:cccc6ccccccc612199999c9c19191121c9c9c12199999c9cccccc121cccc6ccc
-- 061:9116777791116777911167779111611191116777911967779996777796666611
-- 062:7777717777777177777771771111111177177777771777777717777711111111
-- 063:7777611977761119777611191116111977761119777691197777699911666669
-- 064:6666555566666555666665556666655566666555666665556666655566665555
-- 065:555c6666555c56665555c6665555c6665555c6665555c666555c5666555c6666
-- 066:00000000000000aa00aaa0aa00aaaaaa000aaaaa0aaaaaaa0aaaaaaa00aaaaaa
-- 067:9999aa999aa9aaa9aaa9aaa9aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 068:99999999aa999999aa9aaa99aaaaaa99aaaaa999aaaaaaa9aaaaaaa9aaaaaa99
-- 069:0000000099000000990999009999990099999000999999909999999099999900
-- 070:0000000000222000020202002020200202000022202000200200000200200000
-- 071:0000000000222020220202022020002002000002200000000000000020000000
-- 072:0556666c0066666c006666c100666c1200066c11000556cc0006666600055555
-- 073:22c6666011c66660221c66602221c6661111c666cccc66666655555555500000
-- 074:0aaa9a22aaa9aa22099922770aaa2277aaa99a22999999220099999900099999
-- 075:8a922aa0aaa99aaa229999002299aaa099999aaa999999999999990099999000
-- 076:92cc6ccc91cc6ccc19cc6cccc2cc6ccc91cc6ccc91cc6ccc19cc6ccccccc6ccc
-- 077:9222227892222227922222279222222792222227922222979999997897777722
-- 078:8888828888888288888882882222222288288888882888888828888822222222
-- 079:8722222972222229722222297222222972222229792222298799999922777779
-- 081:0000000000000000000cc00000c12c000cccc2c0ccc1112cccccc111cccccccc
-- 082:0aaaaaaa0aaaaaaa099aaaaa00aaaaaa9caaaaaac9aa9aaa0cc9caa9000c9ccc
-- 083:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa9aaa9aaacaaacaa99caa9c9c
-- 084:aaaaaaa9aaaaaaa9aaaaac9caaaaaac9aaaaaa9caaa9aacccaac9cc99c9ccccc
-- 085:99999900c9c9c9c09c9c9c90c9c9c0009c9c9c9cccccc9cccc9ccc90ccccc000
-- 086:0000000020000000020200002020200002020020002002020000002000000000
-- 089:5550000055500000665067006656650066665000675500006750000067600000
-- 090:88888ccc888ccccc88cccc118ccc1111ccc11cc16c11ccc2661cccc2661cccc2
-- 091:ccc88888ccccc88811cccc881111ccc81cc11ccc2ccc11c62cccc1662cccc166
-- 092:cccc6ccccccc612199999c9c19191121c9c9c12199999c9cccccc121cccc6ccc
-- 093:9227888892227888922278889222722292227888922978889997888897777722
-- 094:8888828888888288888882882222222288288888882888888828888822222222
-- 095:8888722988872229888722292227222988872229888792298888799922777779
-- 096:0000000000000000000110000011110000111100000110000000000000000000
-- 097:cc7cc7cc0c7887c000c88c0000cccc0000cccc0000c21c0000cccc0000cccc00
-- 098:0ccccaaa0ccccaac000ccccc00cccccc00cccccc00cc0ccc00000cc000000000
-- 099:ccaaaaccccaaaccccccccccccccccccccccccccccccccccccccccccc00cccccc
-- 100:caaacaaacaaacaaccaaccccccccccccccccccccc666cccccc6766ccccc6776c6
-- 101:caaaaaaccaaacaaccaacccccccccccccccc6ccccc666cccc667ccc66776cc66c
-- 102:caaaacccccaaaccccccccccccccccccccccccccccccccccccccccccccccccc00
-- 103:aaacccc0caacccc0ccccc000cccccc00cccccc00ccc0cc000cc0000000000000
-- 104:0000000000000000000110000011110000111100000110000000000000000000
-- 105:0007000000766000076666000666660006666600066666000666660006565600
-- 106:662cccc2662cccc2662cccc26622222266222222662cccc2662cccc2662cccc2
-- 107:2cccc2662cccc2662cccc26622222266222222662cccc2662cccc2662cccc266
-- 108:8888888888888888888787878878777788878777887777778766666676666666
-- 109:8888888788888876777777667777776677777766777777666666666666666666
-- 110:777677777776777788868888666c6666666c6666666c6666cccccccccccccccc
-- 111:777677777776777788868888666c6666666c6666666c6666cccccccccccccccc
-- 113:00c21c0000cccc0000cccc000cccccc00cc211c00cccccc000cccc000cccccc0
-- 114:00cccc000cccccc00c1221c00cccccc000cccc00ccccccccc322323cc233232c
-- 115:0000ccc000000ccc000000c60000000c00000000000000000000000000000000
-- 116:0c6677670c6677676066676766666767c6666767067667670667676700676767
-- 117:776666c076676c0076676c0c76766ccc7676cccc7676ccc07676ccc07676cc00
-- 118:00ccc000cccc0000cc000000c000000000000000000000000000000000000000
-- 121:76666667565256c6656565c60556550005656500055555000555550005555500
-- 122:662cccc2662cccc2662cccc2662cccc2662cccc2662222226777777777777777
-- 123:2cccc2662cccc2662cccc2662cccc2662cccc266222222667777777677777777
-- 124:8888888888888888777777887777778877777788777777886666667866666667
-- 125:8888888788888876888787668878776688878766887777668766666676666666
-- 126:8888888888888888777777887777778877777788777777886666667866666667
-- 127:5555555565656565565656566565656566566656666666666666666666666666
-- 128:0000000000000000000110000011110000111100000110000000000000000000
-- 129:0cc211c00cccccc000cccc0000c21c0000cccc0000c21c0000cccc0000cccc00
-- 130:c232223ccccccccc00cc1c0000c1cc000cccccc00c1211c0cccc11ccc112211c
-- 132:0066776700667767006677670066776700667767006677670066776700667767
-- 133:7676cc007676cc007676cc007676cc007676cc007676cc007676cc007676cc00
-- 134:5566555655655566566555665665556656655566566555665565556655665556
-- 135:6555665566555655665556656655566566555665665556656655565565556655
-- 136:0000000000000000000110000011110000111100000110000000000000000000
-- 137:888888867777777677777776ccccccccc66cc66c6776677667766776c66cc66c
-- 138:00000000000000090000000900009009000099000000999b00009a9b00009aab
-- 139:000a0000000aa000900aaa00990aaaa0a999abaaaa99bbaabaabbbabbbabbaaa
-- 140:0a0000000ba0000a0bba00ababbbaabbaabbabbbaaababbabbaaabaabbbaaaab
-- 141:a00a0000a00aa000909aaa00999aaaa0a999abaaaa99bbaaaaabbbabbbabbaaa
-- 142:0a0000000ba000000bba0000abbba00aaabba0abaaabaabbbbaaabbbbbbaabba
-- 143:0000000000000000a0000000a0090000a0990000a9990000a999a000aa9aa000
-- 145:00cccc0000cccc000cccccc00cc211c0ccccccccccc2111ccccccccccccccccc
-- 146:0000000000000000000000000000000000bba0000bbbba00b0099ba000009999
-- 147:00000000000000000000000000000000000bbb0000bbbbbb0b99900099990000
-- 148:0066766700667667006676770067767700677677067766770676c776676cc776
-- 149:7676cc007676cc007676cc006676cc0066766c00c6676cc0cc6766c0ccc7766c
-- 150:5566555655566555555665555556655555566555555665555556655555665556
-- 151:6555665555566555555665555556655555566555555665555556655565556655
-- 152:cccccc000cccccc000c6666c000c66660000c66600000c66000000c60000000c
-- 153:00cccccc0cccccc0c6666c006666c000666c000066c000006c000000c0000000
-- 154:09999aaa009999aa00099bbb000aaabb9999aaab09999aaa0099999900000099
-- 155:bbabaaaaabaaabbbaaaabbbabaabbb99bb9aaaa999aaaaaa9aaa99aa99999999
-- 156:abbbaabbaaaaabbbaabbbaaaabbbaabbbbbaaaab9999aaaaa99aaaaa99aaa999
-- 157:baabaaaaaaaaabbbaaaabbbabaabbbaabbaaaaaabbbaaaaa9aaa99aa99999999
-- 158:abbbabaaaaaaaaaba9aaaabba9aa9bbb99a9a99a9999aaaaa99aaaaa99aaa999
-- 159:aaaaa990bbaa9900b9a99000a999aaa0a99aaa0099aaa999a999999099999900
-- 160:0000000000000000000990000099990000999900000990000000000000000000
-- 161:00babbbb0b9bbbbbb999bbbbaaa99bbbaa9aa9bba9aaaaabcaaaaaaaccaaaaaa
-- 162:bbbabb00bbbb9bb0bbb999bbbb99aaabb9aaaaaaa9aaaaaaaacaaaaaacccaaac
-- 168:0000000000000000000110000011110000111100000110000000000000000000
-- 170:11111111aaaaaaaaaaaaa1aaaaaaaaaaaaaaaaaaaa1aaaaaaaaaaaaaaaaaaaaa
-- 171:11111111aaaaa1aaaaaaaaaaaaaaaaaaaa1aaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 172:ddddddddddcdddcdddddddddcdcdcdcdddddddddcdcdcdcddcdcdcdccdcdcdcd
-- 173:ffffffffe222eefffeeeffeee99eeee99fff99999999ee999999999999ee9999
-- 174:8888888888888888887777778876666688767777887677778876777788767777
-- 175:8888888788888876777777666666776677778766777787667777876677778766
-- 176:cccccccccc11c11ccc21c21ccc21c21ccc21c21ccc21e21ecc21e21ecece2cc2
-- 177:cccccccccc11c11ccc21c21ccc21c21ccc21c21ccc21c21ccc21c21cccccecce
-- 178:cccccccccc11c11ccc21c21ccc21c21ccc21c21ccc21c21ccc21c21cccccecce
-- 179:cccccccccc11c11ccc21c21ccc21c21ccc21c21ccc212212cc212212c2c2cccc
-- 180:2eeeeeeeef222fffeeefffeedffddfffdddeedddffddddffdddddddddddffddd
-- 181:ee2eeeeeffe22fffeeefffeedffdd2ffdddeedddffddddffdddddddddddffddd
-- 182:eeee2eeeff22efffeeefffeedffddfffdddeedddffddddffdddddddddddffddd
-- 183:eeeeee2eff222fefeeefffeedf2ddfffdddeedddffddddffdddddddddddffddd
-- 188:dcdcdcdccdcccdccdcdcdcdcccccccccdcdcdcdccccccccccccccccccccccccc
-- 189:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 190:8876777788767777887677778876777788778888887777778766666676666666
-- 191:7777876677778766777787667777876688888766777777666666666666666666
-- 192:c22eee2eccc22222cec22cc2ceecccccceecceecceeeeeeeceeeeeeece2eeeee
-- 193:ceecccecc22eeeeecc2ee22eccc22222ccc22cc2cccccccccccccccccceccccc
-- 194:ceecccecc22eeeeecf2ee22ecff22222cff22222ccfffc22cccfccc2cceccccc
-- 195:ccc222c2ceecccccc2ecceecc22eeeeec22ee22ec2222222c2222222c2c22222
-- 204:88888888888888cc8888cccc888ccccc88cccc6688ccc6668ccc66668ccc6666
-- 205:cccccccccccccccccccccccc666c6666666c6666666c6666666c6666666c6666
-- 206:cccccccccccccccccccccccc6666c6666666c6666666c6666666c6666666c666
-- 207:88888888cc888888cccc8888ccccc88866cccc88666ccc886666ccc86666ccc8
-- 208:ccccccccc11cc11cc21cc21cc21cc21cc21cc21ce21ec21ce21ec21c2cc2ecec
-- 209:ccccccccc11cc11cc21cc21cc21cc21cc21cc21cc21cc21cc21cc21ceccecccc
-- 210:ccccccccc11cc11cc21cc21cc21cc21cc21cc21cc21cc21cc21cc21ceccecccc
-- 211:ccccccccc11cc11cc21cc21cc21cc21cc21cc21c2212c21c2212c21ccccc2c2c
-- 220:ccc6666612166666c9c991111219121112191c11c9c99111121cccccccc66666
-- 221:666c6666666c666611111111121112111c111c1111111111cccccccc666c6666
-- 222:6666c6666666c666111111111121112111c111c111111111cccccccc6666c666
-- 223:66666ccc66666ccc11196ccc11219ccc11c19ccc1119cccccccc6ccc66666ccc
-- 224:2ee2222c22222ccc2cc22cccceccceeceecceeeceeeceeeceeeeeeeceeeee2ec
-- 225:ecceeeeceeeee22ce22ee22c2c222ccccc22ccccccc2cccccccccccccccccecc
-- 226:ecceeeeceeeee22ce22ee22c2f222ffcff22fffcfcf2fcccccfffccccccfcecc
-- 227:c22cccccccccceecceecceece2eee22c22ee222c222e222c2222222c22222c2c
-- 236:ccc66666ccc66656ccc66566ccc65656ccc56565ccc55656ccc56565ccc55555
-- 237:666c6666665c6656666c6566565c5656656c6665565c5656656c6565555c5555
-- 238:6666c6666656c6566566c5665656c6566565c5655655c6566565c5655555c555
-- 239:61116ccc61216ccc99199ccc1ccc1ccc16661ccc19991cccc122cccc5ccc5ccc
-- 240:00cccc000c8888c0c867768cc877888cc878878cc868768c0c8888c000cccc00
-- 241:000cc00000c7cc0000678c0000688c0000682c0000682c000022cc00000cc000
-- 242:000cc000000cc000000cc000000cc000000cc000000cc000000cc000000cc000
-- 243:000cc00000cc7c0000c6670000c6680000c6680000c6680000cc7c00000cc000
-- 244:00000000033003c03333333c3333333c033333c000333c000003c00000000000
-- 245:00000000033003c03333332c3333322c033322c000322c000002c00000000000
-- 246:00000000033002c03333223c3332233c032233c000233c000003c00000000000
-- 247:00000000033003c03322333c3223333c023333c000333c000003c00000000000
-- 248:00000000022003c02233333c2333333c033333c000333c000003c00000000000
-- 249:0120000001200000012000000120000001200000012000000cc00000cccc0000
-- 250:01cc000001c2cc0001c222cc01c22cc001ccc00001c000000cc00000cccc0000
-- 252:ccc5655512155555c9c991111219121112191c11c9c99111121cccccccc55555
-- 253:655c6555555c555511111111121112111c111c1111111111cccccccc555c5555
-- 254:6555c5555555c555111111111121112111c111c111111111cccccccc5555c555
-- 255:65556ccc55555ccc11195ccc11219ccc11c19ccc1119cccccccc5ccc55555ccc
-- </TILES>

-- <TILES1>
-- 007:eeeeeeeee000000ee000000ee000000ee000000ee000000ee000000eeeeeeeee
-- 008:eeeeeeeee000000ee000000ee000000ee000000ee000000ee000000eeeeeeeee
-- 009:eeeeeeeee000000ee000000ee000000ee000000ee000000ee000000eeeeeeeee
-- 010:eeeeeeeee000000ee000000ee000000ee000000ee000000ee000000eeeeeeeee
-- 011:eeeeeeeee000000ee000000ee000000ee000000ee000000ee000000eeeeeeeee
-- 012:00000000000033500003235500333cc200c23cc000ccc7700000078800000077
-- 013:0000000005330000553230002cc333000cc32c00077ccc008870000077000000
-- 014:000000090000009100000cc100000cc100007c1c0003991100c0c99c00ccccc0
-- 015:1220000022220000cc220000cc2200001229f00021937f00199937000c0ccc30
-- 016:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 017:cccccccccccccccccccccccccccccccccccccccccc9cccc9c9caccc999a9ccc9
-- 018:ccccccccccccc9ccccc9cc99cc9ccc99c99ccc99999cccc9c9ccca99a9cccaa9
-- 019:cccccccccccccccccccccc9c9ccc9ccc9ccc99ccc9c999ccc9a9999a9caa99aa
-- 020:cccccccccccccccccccccccccccccccccccccccc9cccc9cc9cccac9c9ccc9a99
-- 022:0009999900cccc920ccccc9b9cc9cc9b99bb9c9992bbba999bbaaaa99b9aa99a
-- 023:999cccbcbb99cb99bbb9c999bbaa9c9b9aaa9ccb9aa9ccca99acbbc999abbaa9
-- 024:cbccc99999bc99bb999c9bbbb9c9aabbbcc9aaa9accc9aa99cbbca999aabba99
-- 025:9999900029cccc00b9ccccc0b9cc9cc999c9bb9999abbb299aaaabb9a99aa9b9
-- 026:0000aa0a0aa9aaaa0aaa9bba09aaabbbaa9aaaaaaaaabbbaaaabbbab0abbbabb
-- 027:a00bb0aaaaabbbaaaaaabbaaabbaaaaaabbbabbabbbbbbbabbbbbbaabbbbbbba
-- 028:00aa0000a9aaa900aa9aa990aaaaa990aaaa9990aaaaa999bbbbaa99bbbbaa90
-- 029:0055660000555500005555000055550000555500005655000056550000565500
-- 032:ccccccccccccccccccccc9ccccccc9ccccccc99ccccccc99cccccc99ccccccc9
-- 033:99aa9ccccaa9a999ca9b9aabca9bb9abccabbbaacc99b2a9999a99929aabbc9a
-- 034:aa9c9aa9baa9aabbbbaacabbb2aa9bb2aaaa99aa9abb999bc9bbb99bcc9b2aaa
-- 035:9caa9aaaa9cacaabaa9ccabbaaacc9bbabbcc9b2bb29b9ccb29cbb99a9ccbb2a
-- 036:ccc9aa99999a9aacbaa9b9acba9bb9acaabbbacc9a2b99cc2999a999a9cbbaa9
-- 037:cccccccccccccccccc9ccccccc9cccccc99ccccc99cccccc99cccccc9ccccccc
-- 038:99999999cc99c9999bbba99bbbbbaa9a2bbaaaa99bb999a9c999999acc9aaaa9
-- 039:c99baaa9ba99aaa9aaa9aa99aaa99a99aaa9999c9aa9999c99a9c9cc99a9c9cc
-- 040:9aaab99c9aaa99ab99aa9aaa99a99aaac9999aaac9999aa9cc9c9a99cc9c9a99
-- 041:99999999999c99ccb99abbb9a9aabbbb9aaaabb29a999bb9a999999c9aaaa9cc
-- 042:0aaaabbbaaaabbbaaa9bbbaa09abbaaaaaaaaaabaaaa9aaaaaa9aaaa099aaaaa
-- 043:bbbbbbbbbbbbbbaaabbabbabaaabbbabbbabbaaabbabaabbabaaaabbaaaaaaab
-- 044:abbba900aabb9990ba9a9990bbacc990bbaa9900aaaaa990b9aaaa99baccc999
-- 045:0056550000665500006655000066650000566500005655000056550000565500
-- 046:c0c0000cc090000ccc90000cc0c0900cc0c0900c90cc9009c0000000c090000c
-- 047:000c00c0000c0c00000c090c000c0c09000c0090000090000000c0000000c000
-- 048:ccccccaacc9ccc9acccc9999ccc99999ccccc99accccccaaccccc99cccc99cc9
-- 049:abbb2c9aaabbbc92aaa999bb9ccccbbbaaccc9ccac9ab29cc9aabb299aaaabba
-- 050:ccccccccccccccccccccccccccccccccccccccccccccccc2cccccc22ccccc22b
-- 051:ccccccccccccccccccccccccccccccccccccccccccccccccacccccccaacccccc
-- 052:cc9abbbac9aa2baa9bbaaaa9bbbaaa9c2b999ca9a999baaaa99abbbaabba2bb9
-- 053:ac9ccccc9999cccccc999cccccccc9ccccccccccaacccc9ca9c999cc999999cc
-- 054:cc9aaaa9c999999a9bb999a92bbaaaa9bbbbaa9a9bbba99bcc99c99999999999
-- 055:99a9c9cc99a9c9cc9aa9999caaa9999caaa99a99aaa9aa99ba99aaa9c99baaa9
-- 056:cc9c9a99cc9c9a99c9999aa9c9999aaa99a99aaa99aa9aaa9aaa99ab9aaab99c
-- 057:9aaaa9cca999999c9a999bb99aaaabb2a9aabbbbb99abbb9999c99cc99999999
-- 058:099aacaa999999ca99999aa999099aaa009999aa099909990990000900000000
-- 059:999aaaca9aa9aa9c9aaa999999aa99aa9cc995aaccc9559acc95550900c55500
-- 060:aac9aa00aaa9aaa0caa99aa0ccc99900acc99cc0a999ccc09990cc0000000000
-- 061:00565500006655000066650000666500006655000666c660666cc66666cccc66
-- 062:9009000c0990000c0000090c00009009000009c0000000000000000000000000
-- 063:0000c00000000c000000090000c9090000900900009990000000000000000000
-- 064:cc999999cc999c9ac9ccccaacccccccccc9cccccccc999cccccc9999ccccc9ca
-- 065:9bb2abbaabbba99aaaab999a9ac999b2c9aaabbb9aaaabb9aab2aa9cabbba9cc
-- 066:ccccccbccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 067:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 068:abbaaaa992bbaa9cc92ba9cacc9cccaabbbcccc9bb999aaa29cbbbaaa9c2bbba
-- 069:9cc99cccc99cccccaacccccca99ccccc99999ccc9999cccca9ccc9ccaacccccc
-- 070:9b9aa99a9bbaaaa992bbba9999bb9c999cc9cc9b0ccccc9b00cccc9200099999
-- 071:99abbaa999acbbc99aa9ccca9aaa9ccbbbaa9c9bbbb9c999bb99cb99999cccbc
-- 072:9aabba999cbbca99accc9aa9bcc9aaa9b9c9aabb999c9bbb99bc99bbcbccc999
-- 073:a99aa9b99aaaabb999abbb2999c9bb99b9cc9cc9b9ccccc029cccc0099999000
-- 074:000000000000000000000000000000000000073500003232000373330037cccc
-- 075:00000000000000000000000000000000500000005500000032500000cc350000
-- 076:000000000000000000003350000325c300035c0c003577800003c07300000ccc
-- 077:000000000330000033230000cccc3000c87c00000730000003cc0000cccccc00
-- 078:000000000000000c00c0000000c00000000c0000c000c0000cccc0000000c000
-- 079:c0000000c000c0000c00c00000cc0000000cc0000000c00c000ccccc000ccc00
-- 080:ccccccc9cccccc99cccccc99ccccc99cccccc9ccccccc9cccccccccccccccccc
-- 081:9aabbc9a999a9992cc99b2a9ccabbbaaca9bb9abca9b9aabcaa9a99999aa9ccc
-- 082:a2bbcc9a99bbc92bcc9b92bb2b9ccbbabb9ccaaabbacc9aabaacac9aaaa9aac9
-- 083:aaa2b9ccb99bbb9cb999bba9aa99aaaa2bb9aa2bbbacaabbbbaa9aab9aa9c9aa
-- 084:a9cbbaa92999a9999a2b99ccaabbbaccba9bb9acbaa9b9ac999a9aacccc9aa99
-- 085:9ccccccc99cccccc99ccccccc99ccccccc9ccccccc9ccccccccccccccccccccc
-- 086:0550000056650000666600005777660055557760566500765665000755550555
-- 087:6666666605500550000000000000000000000000000000000000000000000000
-- 088:0000055000005665000066660066777506775555670056657000566555505555
-- 090:003cc555000c58770000078800000088000000770000003300000ccc000ccccc
-- 091:5cc3000085c0000070000000000000000000000000000000c0000000cc000000
-- 094:0c000c0000c00c0000c00c00000cccc0000000cc0000000c0000000c00000000
-- 095:00ccc00000ccc0000cccc000cccc0000ccc00000ccc00000ccc00000ccc00000
-- 096:0000000000000000000440000044440000444400000440000000000000000000
-- 097:99a9ccc9c9caccc9cc9cccc9cccccccccccccccccccccccccccccccccccccccc
-- 098:aa99aac9a9999a9ccc999c9ccc99ccc9ccc9ccc9c9cccccccccccccccccccccc
-- 099:9aaccc9a99accc9c9cccc99999ccc99c99ccc9cc99cc9ccccc9ccccccccccccc
-- 100:9ccc9a999cccac9c9cccc9cccccccccccccccccccccccccccccccccccccccccc
-- 104:0000000000000000000440000044440000444400000440000000000000000000
-- 110:000000000000000000000000000000000000000000000000000000000000000c
-- 111:0ccc00000ccc00000ccc0000cccc0000ccccc000ccccc000ccccc000ccccc000
-- 124:0000000000000000000000000000000000aab0000aaaab00a0099ab000009999
-- 125:00000000000000000000000000000000000aaa0000aaaaaa0aa9900099990000
-- 126:0000000c0000000c000000cc00000ccc0000cccc0ccccccccccc9cccccccc9c9
-- 127:ccccc000cccccc00cccccc00ccccccc0ccccccc0cccccccc9cc9cccc099ccc9c
-- 128:0000000000000000000440000044440000444400000440000000000000000000
-- 136:0000000000000000000440000044440000444400000440000000000000000000
-- 138:00000000000000090000000900009009000099000000999b00009a9b00009aab
-- 139:000a0000000aa000900aaa00990aaaa0a999abaaaa99bbaabaabbbabbbabbaaa
-- 140:0a000000aba0000aabba00ababbbaabbaabbabbbaaababbabbaaabaabbbaaaab
-- 141:a00a0000a09aa000909aaa00999aaaa0a999abaaaa99bbaaaaabbbabbbabbaaa
-- 142:0a000000aba00000abba0000abbba00aaabba0abaaabaabbbbaaabbbbbbaabba
-- 143:0000000000000000a0000000a0090000a0990000a9990000a999a000aa9aa000
-- 154:09999aaa009999aa00099bbb000aaabb9999aaab09999aaa0099999900000099
-- 155:bbabaaaaabaaabbbaaaabbbabaabbb99bb9aaaa999aaaaaa9aaa99aa99999999
-- 156:abbbaabbaaaaabbbaabbbaaaabbbaabbbbbaaaab9999aaaaa99aaaaa99aaa999
-- 157:baabaaaaaaaaabbbaaaabbbabaabbbaabbaaaaaabbbaaaaa9aaa99aa99999999
-- 158:abbbabaaaaaaaaaba9aaaabba9aa9bbb99a9a99a9999aaaaa99aaaaa99aaa999
-- 159:aaaaa990bbaa9900b9a99000a999aaa0a99aaa0099aaa999a999999099999900
-- 160:0000000000000000000440000044440000444400000440000000000000000000
-- 168:0000000000000000000440000044440000444400000440000000000000000000
-- 176:cefefececefeefeceeecefeceeeccefefccecefefcceecefecefecefeceffece
-- 177:efefecefefeffececffefececffeefeceeecefeceeeccefefececefefeceecef
-- 178:fececefefeceecefeeefecefeeeffececffefececffeefecefecefecefeccefe
-- 179:ececefecececcefefccecefefcceecefeeefecefeeeffececefefececefeefec
-- 180:eeccecceecececcfeceececfcefecececeffefeecfefefeccfeefeeceecefeee
-- 181:ffeefeecfecefeeefecceceeecececefeceececfeefececeeeffefcecfefefcc
-- 182:eeffeffeefefeffcefeefefcfecefefefecceceefcececeffceeceefeefeceee
-- 183:cceeceefcefeceeeceffefeeefefefecefeefefceecefefeeeccecfefcececff
-- 184:eeccceeecececcceefcccccccccccccccecefceccccccecccceccccccccccccc
-- 185:eeccceeecececcceefcccccccccccccccfcfccfccccccecccceccccccecccccc
-- 186:ffcccfffcfcfcccffecccccccccccccccccceccccccccfccccfccccccecccccc
-- 187:cccccccccccccccccecccccccccccccccccceccccccccfccccfccccccecccccc
-- 192:cefefececefeefeceeecefeceeeccefeffcecefeffceecefefefecefefeffece
-- 193:ecefecefeceffececcfefececcfeefeceeecefeceeeccefefececefefeceecef
-- 194:fececefefeceecefeeefecefeeeffececcfefececcfeefecececefecececcefe
-- 195:efecefecefeccefeffcecefeffceecefeeefecefeeeffececefefececefeefec
-- 196:eeccecfeecececfffceecefffefeceeefeffefeeffefefecffeefeeceecefece
-- 197:cfeefeeccecefeeeeecceceeecececffeceeceffeefecefeeeffeffeffefefec
-- 198:eeffefceefefefcccfeefecccecefeeececceceeccececefcceeceefeefecefe
-- 199:fceeceeffefeceeeeeffefeeefefefccefeefecceecefeceeeccecceccececef
-- 200:ccccccccceccccecccccccccceccceccccccccccccccccccccccccccccccccec
-- 201:ccccccecceccccfccccccccccfccceccccccccccccccccccccccccecccccccfc
-- 202:cccccceccfcccccccccccccccccccfcccccccccccccccccccccccceccccccccc
-- 203:cccccceccfcccccccccccccccccccfcccccccccccccccccccccccceccccccccc
-- 208:fecefcfeeccefcfeececeeecceeceeeccefececeeffececeefefefeffeefefef
-- 209:efefeeeffeefeeeffecefcfeeccefcfeececececceecececcefececeeffecece
-- 210:cefecfceeffecfceefefeeeffeefeeeffecefefeeccefefeececececceececec
-- 211:ececeeecceeceeeccefecfceeffecfceefefefeffeefefeffecefefeeccefefe
-- 212:cececefecececefeefecefefefecefefffecefceffecefceeefefeeceefefeec
-- 213:ecefecececefececcececefecececefeeececeefeececeefcfecefcecfecefce
-- 214:fefefecefefefeceecefecececefececccefecfeccefecfeeececeefeececeef
-- 215:efecefefefecefeffefefecefefefeceeefefeeceefefeecfcefecfefcefecfe
-- 216:eeeeeeeceeeceecceccccecccfcccccfececccceccccceccececcccccccccccc
-- 217:eeeeeeeceeeceecceccccecccfcccccfecfccccfccccceccececccccceccccce
-- 218:fffffffcfffcffccfccccfcccecccccefccccccccccccfccfcfcccccceccccce
-- 219:cccccccccccccccccccccccccecccccefccccccccccccfccfcfcccccceccccce
-- 224:fecefffeeccefffeececeeecceeceeeccefececeeffececeefefeceffeefecef
-- 225:efefeeeffeefeeeffecefffeeccefffeececefecceecefeccefececeeffecece
-- 226:cefeccceeffeccceefefeeeffeefeeeffecefefeeccefefeececefecceecefec
-- 227:ececeeecceeceeeccefeccceeffeccceefefeceffeefeceffecefefeeccefefe
-- 228:cefefefecefefefeecefecefecefeceffcefeccefcefecceeececeeceececeec
-- 229:efecefecefecefeccefefefecefefefeeefefeefeefefeeffcefeccefcefecce
-- 230:fecececefecececeefecefecefecefeccfeceffecfeceffeeefefeefeefefeef
-- 231:ecefecefecefeceffecececefecececeeececeeceececeeccfeceffecfeceffe
-- 232:cfccccccccccccceccccccccccccccccececcccccccccccccfccccecccccccec
-- 233:ccccccccccccccceccccccccccccccccececccccccccccccccccccecccccccec
-- 234:cecccccccccccccfccccccccccccccccfcfcccccccccccccceccccecccccccec
-- 235:cecccccccccccccfccccccccccccccccfcfcccccccccccccceccccecccccccec
-- 240:0022220007766670776886677888886778888887568888670568865000555500
-- 241:0002200000282200007872000078770000787700007877000066660000055000
-- 242:0002200000022000000270000007700000077000000770000007600000055000
-- 243:0002200000228200002787000077870000778700007787000066660000055000
-- 244:00000000033003c03333333c3333333c033333c000333c000003c00000000000
-- 245:00000000033003c03333332c3333322c033322c000322c000002c00000000000
-- 246:00000000033002c03333223c3332233c032233c000233c000003c00000000000
-- 247:00000000033003c03322333c3223333c023333c000333c000003c00000000000
-- 248:00000000022003c02233333c2333333c033333c000333c000003c00000000000
-- 249:0120000001200000012000000120000001200000012000000cc00000cccc0000
-- 250:01cc000001c2cc0001c222cc01c22cc001ccc00001c000000cc00000cccc0000
-- </TILES1>

-- <TILES2>
-- 001:1111111111111111111111111111111111111111111111111111111111111111
-- 002:3333333303000000003000000003000000003000000003000000003000000003
-- 003:6000000600000000006006000006600000066000006006000000000060000006
-- 004:fffffffffffffffffff77fffff7777ffff7777fffff77fffffffffffffffffff
-- 005:7777777770000007700000077000000770000007700000077000000777777777
-- 006:0000000000000000000000000000000000077000007007000700007070000007
-- 007:aaaaaaaaa008800aa080080aa000800aa008000aa080000aa088880aaaaaaaaa
-- 008:aaaaaaaaa008800aa000080aa000800aa000080aa080080aa008800aaaaaaaaa
-- 009:aaaaaaaaa008800aa008800aa080800aa088880aa000800aa000800aaaaaaaaa
-- 010:4443444444244444422244443332244433233244323333341333333311333333
-- 011:4443444444442444444222444422333442333333323333333313333331113331
-- 012:3333333333333333333333333333332222221123333312333333123333331233
-- 013:3333333333333333333333332233332232111123332112333322223333222233
-- 014:3333333333333333333333332233332232111123332112333322223333222233
-- 015:3333333333333333333333332233332232111123332112333322223333222233
-- 016:0100000013100000133100001333100013333100133110000113100000000000
-- 024:0000000000000000000000000000000000000000111111113333333322222222
-- 025:0000000000000000000000000000000000000000111111113333333122222221
-- 026:2113333322213331222123222212222221112222111112221111112211111112
-- 027:1122232222122222222122222222122222211122221111122111111111111111
-- 028:3333123333331232333312113333111233331123333312333333123333331233
-- 029:3322223323222232112222112112211232111123332112333322223333222233
-- 030:3322223323222232112222112112211232111123332112333322223333222233
-- 031:3322223323222232112222112112211232111123332112333322223333222233
-- 035:0000000000000033003330330033333300033333033333330333333300333333
-- 036:0000330003303330333033303333333333333333333333333333333333333333
-- 037:0000220033202220332333203333332233333222333333323333333233333322
-- 038:0000000022000000220222002222220022222000222222202222222022222200
-- 040:0211111102100000021000000210000002100000021000000210000002100000
-- 041:1121111000210000002100000021000000210000002100000021000000210000
-- 042:3333122233321222333122223331222233312222333122223332122233331222
-- 043:2222333322233333222333332223333322233333222333332223333322223333
-- 044:3333123333331232333312113333111233331123333312333333123333331233
-- 045:3322223323222232112222112112211232111123332112333322223333222233
-- 046:3322223323222232112222112112211232111123332112333322223333222233
-- 047:3322223323222232112222112112211232111123332112333322223333222233
-- 051:0333333303333333022333330033333322333333223323330222233200022222
-- 052:3333333333333333333333333333333333333333233323332333233222332222
-- 053:3333333233333332333332223333332233333322333233222332222222222222
-- 054:2222220022222220222222202222200022222222222222222222222022222000
-- 056:0000000000000000000000000000000000000033033333220222222202222222
-- 057:3330000033200000222000002110000033333330222222202222222011222110
-- 058:3333222233333222333332223333322233333222333332223333322233332222
-- 059:2221333322212333222213332222133322221333222213332221233322213333
-- 060:3322223323222232333333333333333333333333333333332222222222222222
-- 061:3322223323222232333333333333333333333333333333332222222222222222
-- 062:3322223323222232333333333333333333333333333333332222222222222222
-- 063:3322223323222232333333333333333333333333333333332222222222222222
-- 066:0000000000000033003330330033333300033333033333330333333300333333
-- 067:2222332223323332333233323333333333333333333333333333333333333333
-- 068:2222332223323332333233323333333333333333333333333333333333333333
-- 069:2222332223323332333233323333333333333333333333333333333333333333
-- 070:2222222233222222332333223333332233333222333333323333333233333322
-- 071:0000000022000000220222002222220022222000222222202222222022222200
-- 072:0112222200221122002211110022211100022122000112220002222200011111
-- 073:1111222021111220111122202112222221222222222222222211111111100000
-- 074:5555555555555555555555555555555555555555555555555555555555555555
-- 075:5555555555555555555555555555555555555555555555555555555555555555
-- 076:0000000011000000111200001221200022221200222212002222312022223120
-- 077:2332333323332333233323332333233323332333233223332222333322222233
-- 078:3333333333333333333333333333333333333333333333333333333333333333
-- 079:3333233233323332333233323332333233323332333223323333222233222222
-- 082:0333333303333333022333330033333322333333223323330222233200022222
-- 083:3333333333333333333333333333333333333333233323332333233222332222
-- 084:3333333333333333333333333333333333333333233323332333233222332222
-- 085:3333333333333333333333333333333333333333233323332333233222332222
-- 086:3333333233333332333332223333332233333322333233222332222222222222
-- 087:2222220022222220222222202222200022222222222222222222222022222000
-- 089:1110000011100000221023002212210022221000231100002310000023200000
-- 090:5555555555555555555555555555555555555555555555555555555555555555
-- 091:5555555555555555555555555555555555555555555555555555555555555555
-- 092:2222322222223242111111112121224211111242111111112222224222223222
-- 093:2444443324444443244444432444444324444443244444232222223323333344
-- 094:3333343333333433333334334444444433433333334333333343333344444444
-- 095:3344444234444442344444423444444234444442324444423322222244333332
-- 096:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 098:0111122201111221000111110011111100111111001101110000011000000000
-- 099:1122221111222111111111111111111111111111111111111111111100111111
-- 100:1222122212221122122111111111111111111111222111111232211111232212
-- 101:2111222121111221111111111111111111121111122211112231112223211221
-- 102:1222211111222111111111111111111111111111111111111111111111111100
-- 103:2221111012211110111110001111110011111100111011000110000000000000
-- 104:5555555555555555000dd05500dddd5500dddd55000dd0550000005500000055
-- 105:0003000000322000032222000222220002222200022222000222220002222200
-- 106:5555555555555555555555555555555555555555555555555555555555555555
-- 107:5555555555555555555555555555555555555555555555555555555555555555
-- 108:1422312212223122212231222422312212223122122231222122312222223122
-- 109:2443333324443333244433332444344424443333244233332223333323333344
-- 110:3333343333333433333334334444444433433333334333333343333344444444
-- 111:3333344233334442333344424443444233334442333324423333322244333332
-- 115:0000111000000111000000120000000100000000000000000000000000000000
-- 116:0122332301223323202223232222232312222323023223230223232300232323
-- 117:2321221033222101332221123222212132321111332211103322111033221100
-- 118:0111000011100000110000001000000000000000000000000000000000000000
-- 120:0000005500000055000000550000005500000055000000550000005500000055
-- 121:3222222322212212222222120222220002222200022222000222220002222200
-- 122:5555555555555555555555555555555555555555555555555555555555555555
-- 123:5555555555555555555555555555555555555555555555555555555555555555
-- 124:2222322222223242111111112121224211111242111111112222224222223222
-- 125:2444443324444443244444432444444324444443244444232222223323333344
-- 126:3333343333333433333334334444444433433333334333333343333344444444
-- 127:3344444234444442344444423444444234444442324444423322222244333332
-- 128:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 132:0022332300223323002233230022332300223323002233230022332300223323
-- 133:3232110032321100323211003232110032321100323211003232110032321100
-- 136:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 137:5555555555555555555555555555555555555555555555555555555555555555
-- 138:4444444444444444443333334433333344333333443333334322222232222222
-- 139:4444444344444432333333223333332233333322333333222222222222222222
-- 140:3332333333323333444244442221222222212222222122221111111111111111
-- 141:3332333333323333444244442221222222212222222122221111111111111111
-- 142:3333333333333333333333333333333333333333333333333322222232222222
-- 143:3333333333333332333333223333332233333322333333222222222222222222
-- 148:0022322300223223002232330023323300233233023322330232133223211332
-- 149:3232110032321100323211002232110022322100122321101123221011133221
-- 150:0003300033233004331120440211333403323334433010300434010000433100
-- 151:5555555555555555555555555555555555555555555555555555555555555555
-- 152:0000005500000055000000550000005500000055000000550000005500000055
-- 153:5555555555555555555555555555555555555555555555555555555555555555
-- 154:4444444344444432333333223333332233333322333333222222222222222222
-- 155:4444444344444432443333224433332244333322443333224322222232222222
-- 156:4444444344444432333333223333332233333322333333222222222222222222
-- 157:4444444444444444443333334433333344333333443333334322222232222222
-- 158:1111111111111111222222222222222222222222222222222222222222222222
-- 159:3333333333333333333333333333333333333333333333333322222232222222
-- 160:0000000000000000000990000099990000999900000990000000000000000000
-- 161:0000000000000001000000010000100100001100000011130000121300001223
-- 162:0002000000022000100222001102222021112322221133223223332333233222
-- 163:0200000003200002033200232333223322332333222323323322232233322223
-- 164:2002000020022000101222001112222021112322221133222223332333233222
-- 165:0200000003200000033200002333200222332023222322333322233333322332
-- 166:0000000000000000200000002001000020110000211100002111200022122000
-- 168:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 169:5555555555555555555555555555555555555555555555555555555555555555
-- 170:4444444444444444443333334432222244323333443233334432333344323333
-- 171:4444444344444432333333222222332233334322333343223333432233334322
-- 172:4444444444444444443333334433333344333333443333334322222232222222
-- 173:4444444344444432333333223333332233333322333333222222222222222222
-- 174:1111111111111111222222222222222222222222222222222222222222222222
-- 175:1111111111111111222222222222222222222222222222222222222222222222
-- 177:0111122200111122000113330002223311112223011112220011111100000011
-- 178:3323222223222333222233323223331133122221112222221222112211111111
-- 179:2333223322222333223332222333223333322223111122222112222211222111
-- 180:3223222222222333222233323223332233222222333222221222112211111111
-- 181:2333232222222223212222332122133311212112111122222112222211222111
-- 182:2222211033221100312115552111222021122200112221112111111011111100
-- 183:0000000000000000555555550000000000000000000000000000000000000000
-- 184:0000005500000055555555550000000000000000000000000000000000000000
-- 185:5555555555555555555555550000000000000000000000000000000000000000
-- 186:4432333344323333443233334432333344334444443333334322222232222222
-- 187:3333432233334322333343223333432244444322333333222222222222222222
-- 188:4444444344444432443333224433332244333322443333224322222232222222
-- 189:1111111111111111222222222222222222222222222222222222222222222222
-- 190:4444444344444432333333223333332233333322333333222222222222222222
-- 191:4444444444444444443333334433333344333333443333334322222232222222
-- 192:0011110001122110012334100112211000122100111111111233232113223231
-- 202:5555555555555555555555555555555555555555555555555555555555555555
-- 203:5555555555555555555555555555555555555555555555555555555555555555
-- 204:5555555555555555555555555555555555555555555555555555555555555555
-- 205:5555555555555555555555555555555555555555555555555555555555555555
-- 208:1323332111111111001121000012110001111110012344101111221112233441
-- 218:5555555555555555555555555555555555555555555555555555555555555555
-- 219:5555555555555555555555555555555555555555555555555555555555555555
-- 220:5555555555555555555555555555555555555555555555555555555555555555
-- 221:5555555555555555555555555555555555555555555555555555555555555555
-- 224:0230000002300000023000000230000002300000023000000110000011110000
-- 225:0211000002131100021333110213311002111000021000000110000011110000
-- 240:0033330003322330332442233444443334444443124444230124423000111100
-- 241:0003300000343300002423000024220000242200002422000011110000011000
-- 242:0003300000033000000320000002200000022000000220000002100000011000
-- 243:0003300000334300003242000022420000224200002242000011110000011000
-- 244:0000000002200210222222212222222102222210002221000002100000000000
-- 245:0000000002200210222222312222233102223310002331000003100000000000
-- 246:0000000002200310222233212223322102332210003221000002100000000000
-- 247:0000000002200210223322212332222103222210002221000002100000000000
-- 248:0000000003300210332222213222222102222210002221000002100000000000
-- </TILES2>

-- <TILES3>
-- 001:1111111111111111111111111111111111111111111111111111111111111111
-- 002:3333333303000000003000000003000000003000000003000000003000000003
-- 003:6000000600000000006006000006600000066000006006000000000060000006
-- 004:fffffffffffffffffff77fffff7777ffff7777fffff77fffffffffffffffffff
-- 005:7777777770000007700000077000000770000007700000077000000777777777
-- 006:0000000000000000000000000000000000077000007007000700007070000007
-- 007:aaaaaaaaa008800aa080080aa000800aa008000aa080000aa088880aaaaaaaaa
-- 008:aaaaaaaaa008800aa000080aa000800aa000080aa080080aa008800aaaaaaaaa
-- 009:aaaaaaaaa008800aa008800aa080800aa088880aa000800aa000800aaaaaaaaa
-- 010:4443444444244444422244443332244433233244323333341333333311333333
-- 011:4443444444442444444222444422333442333333323333333313333331113331
-- 012:3333333333333333333333333333332222221123333312333333123333331233
-- 013:3333333333333333333333332233332232111123332112333322223333222233
-- 014:3333333333333333333333332233332232111123332112333322223333222233
-- 015:3333333333333333333333332233332232111123332112333322223333222233
-- 016:0100000013100000133100001333100013333100133110000113100000000000
-- 024:0000000000000000000000000000000000000000111111113333333322222222
-- 025:0000000000000000000000000000000000000000111111113333333122222221
-- 026:2113333322213331222123222212222221112222111112221111112211111112
-- 027:1122232222122222222122222222122222211122221111122111111111111111
-- 028:3333123333331232333312113333111233331123333312333333123333331233
-- 029:3322223323222232112222112112211232111123332112333322223333222233
-- 030:3322223323222232112222112112211232111123332112333322223333222233
-- 031:3322223323222232112222112112211232111123332112333322223333222233
-- 035:0000000000000033003330330033333300033333033333330333333300333333
-- 036:0000330003303330333033303333333333333333333333333333333333333333
-- 037:0000220033202220332333203333332233333222333333323333333233333322
-- 038:0000000022000000220222002222220022222000222222202222222022222200
-- 040:0211111102100000021000000210000002100000021000000210000002100000
-- 041:1121111000210000002100000021000000210000002100000021000000210000
-- 042:3333122233321222333122223331222233312222333122223332122233331222
-- 043:2222333322233333222333332223333322233333222333332223333322223333
-- 044:3333123333331232333312113333111233331123333312333333123333331233
-- 045:3322223323222232112222112112211232111123332112333322223333222233
-- 046:3322223323222232112222112112211232111123332112333322223333222233
-- 047:3322223323222232112222112112211232111123332112333322223333222233
-- 051:0333333303333333022333330033333322333333223323330222233200022222
-- 052:3333333333333333333333333333333333333333233323332333233222332222
-- 053:3333333233333332333332223333332233333322333233222332222222222222
-- 054:2222220022222220222222202222200022222222222222222222222022222000
-- 056:0000000000000000000000000000000000000033033333220222222202222222
-- 057:3330000033200000222000002110000033333330222222202222222011222110
-- 058:3333222233333222333332223333322233333222333332223333322233332222
-- 059:2221333322212333222213332222133322221333222213332221233322213333
-- 060:3322223323222232333333333333333333333333333333332222222222222222
-- 061:3322223323222232333333333333333333333333333333332222222222222222
-- 062:3322223323222232333333333333333333333333333333332222222222222222
-- 063:3322223323222232333333333333333333333333333333332222222222222222
-- 066:0000000000000033003330330033333300033333033333330333333300333333
-- 067:2222332223323332333233323333333333333333333333333333333333333333
-- 068:2222332223323332333233323333333333333333333333333333333333333333
-- 069:2222332223323332333233323333333333333333333333333333333333333333
-- 070:2222222233222222332333223333332233333222333333323333333233333322
-- 071:0000000022000000220222002222220022222000222222202222222022222200
-- 072:0112222200221122002211110022211100022122000112220002222200011111
-- 073:1111222021111220111122202112222221222222222222222211111111100000
-- 074:5555555555555555555555555555555555555555555555555555555555555555
-- 075:5555555555555555555555555555555555555555555555555555555555555555
-- 076:0000000011000000111200001221200022221200222212002222312022223120
-- 077:2332333323332333233323332333233323332333233223332222333322222233
-- 078:3333333333333333333333333333333333333333333333333333333333333333
-- 079:3333233233323332333233323332333233323332333223323333222233222222
-- 082:0333333303333333022333330033333322333333223323330222233200022222
-- 083:3333333333333333333333333333333333333333233323332333233222332222
-- 084:3333333333333333333333333333333333333333233323332333233222332222
-- 085:3333333333333333333333333333333333333333233323332333233222332222
-- 086:3333333233333332333332223333332233333322333233222332222222222222
-- 087:2222220022222220222222202222200022222222222222222222222022222000
-- 089:1110000011100000221023002212210022221000231100002310000023200000
-- 090:5555555555555555555555555555555555555555555555555555555555555555
-- 091:5555555555555555555555555555555555555555555555555555555555555555
-- 092:2222322222223242111111112121224211111242111111112222224222223222
-- 093:2444443324444443244444432444444324444443244444232222223323333344
-- 094:3333343333333433333334334444444433433333334333333343333344444444
-- 095:3344444234444442344444423444444234444442324444423322222244333332
-- 096:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 098:0111122201111221000111110011111100111111001101110000011000000000
-- 099:1122221111222111111111111111111111111111111111111111111100111111
-- 100:1222122212221122122111111111111111111111222111111232211111232212
-- 101:2111222121111221111111111111111111121111122211112231112223211221
-- 102:1222211111222111111111111111111111111111111111111111111111111100
-- 103:2221111012211110111110001111110011111100111011000110000000000000
-- 104:5555555555555555000dd05500dddd5500dddd55000dd0550000005500000055
-- 105:0003000000322000032222000222220002222200022222000222220002222200
-- 106:5555555555555555555555555555555555555555555555555555555555555555
-- 107:5555555555555555555555555555555555555555555555555555555555555555
-- 108:1422312212223122212231222422312212223122122231222122312222223122
-- 109:2443333324443333244433332444344424443333244233332223333323333344
-- 110:3333343333333433333334334444444433433333334333333343333344444444
-- 111:3333344233334442333344424443444233334442333324423333322244333332
-- 115:0000111000000111000000120000000100000000000000000000000000000000
-- 116:0122332301223323202223232222232312222323023223230223232300232323
-- 117:2321221033222101332221123222212132321111332211103322111033221100
-- 118:0111000011100000110000001000000000000000000000000000000000000000
-- 120:0000005500000055000000550000005500000055000000550000005500000055
-- 121:3222222322212212222222120222220002222200022222000222220002222200
-- 122:5555555555555555555555555555555555555555555555555555555555555555
-- 123:5555555555555555555555555555555555555555555555555555555555555555
-- 124:2222322222223242111111112121224211111242111111112222224222223222
-- 125:2444443324444443244444432444444324444443244444232222223323333344
-- 126:3333343333333433333334334444444433433333334333333343333344444444
-- 127:3344444234444442344444423444444234444442324444423322222244333332
-- 128:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 132:0022332300223323002233230022332300223323002233230022332300223323
-- 133:3232110032321100323211003232110032321100323211003232110032321100
-- 136:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 137:5555555555555555555555555555555555555555555555555555555555555555
-- 138:4444444444444444443333334433333344333333443333334322222232222222
-- 139:4444444344444432333333223333332233333322333333222222222222222222
-- 140:3332333333323333444244442221222222212222222122221111111111111111
-- 141:3332333333323333444244442221222222212222222122221111111111111111
-- 142:3333333333333333333333333333333333333333333333333322222232222222
-- 143:3333333333333332333333223333332233333322333333222222222222222222
-- 148:0022322300223223002232330023323300233233023322330232133223211332
-- 149:3232110032321100323211002232110022322100122321101123221011133221
-- 150:0003300033233004331120440211333403323334433010300434010000433100
-- 151:5555555555555555555555555555555555555555555555555555555555555555
-- 152:0000005500000055000000550000005500000055000000550000005500000055
-- 153:5555555555555555555555555555555555555555555555555555555555555555
-- 154:4444444344444432333333223333332233333322333333222222222222222222
-- 155:4444444344444432443333224433332244333322443333224322222232222222
-- 156:4444444344444432333333223333332233333322333333222222222222222222
-- 157:4444444444444444443333334433333344333333443333334322222232222222
-- 158:1111111111111111222222222222222222222222222222222222222222222222
-- 159:3333333333333333333333333333333333333333333333333322222232222222
-- 160:0000000000000000000990000099990000999900000990000000000000000000
-- 161:0000000000000001000000010000100100001100000011130000121300001223
-- 162:0002000000022000100222001102222021112322221133223223332333233222
-- 163:0200000003200002033200232333223322332333222323323322232233322223
-- 164:2002000020022000101222001112222021112322221133222223332333233222
-- 165:0200000003200000033200002333200222332023222322333322233333322332
-- 166:0000000000000000200000002001000020110000211100002111200022122000
-- 168:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 169:5555555555555555555555555555555555555555555555555555555555555555
-- 170:4444444444444444443333334432222244323333443233334432333344323333
-- 171:4444444344444432333333222222332233334322333343223333432233334322
-- 172:4444444444444444443333334433333344333333443333334322222232222222
-- 173:4444444344444432333333223333332233333322333333222222222222222222
-- 174:1111111111111111222222222222222222222222222222222222222222222222
-- 175:1111111111111111222222222222222222222222222222222222222222222222
-- 177:0111122200111122000113330002223311112223011112220011111100000011
-- 178:3323222223222333222233323223331133122221112222221222112211111111
-- 179:2333223322222333223332222333223333322223111122222112222211222111
-- 180:3223222222222333222233323223332233222222333222221222112211111111
-- 181:2333232222222223212222332122133311212112111122222112222211222111
-- 182:2222211033221100312115552111222021122200112221112111111011111100
-- 183:0000000000000000555555550000000000000000000000000000000000000000
-- 184:0000005500000055555555550000000000000000000000000000000000000000
-- 185:5555555555555555555555550000000000000000000000000000000000000000
-- 186:4432333344323333443233334432333344334444443333334322222232222222
-- 187:3333432233334322333343223333432244444322333333222222222222222222
-- 188:4444444344444432443333224433332244333322443333224322222232222222
-- 189:1111111111111111222222222222222222222222222222222222222222222222
-- 190:4444444344444432333333223333332233333322333333222222222222222222
-- 191:4444444444444444443333334433333344333333443333334322222232222222
-- 192:0011110001122110012334100112211000122100111111111233232113223231
-- 202:5555555555555555555555555555555555555555555555555555555555555555
-- 203:5555555555555555555555555555555555555555555555555555555555555555
-- 204:5555555555555555555555555555555555555555555555555555555555555555
-- 205:5555555555555555555555555555555555555555555555555555555555555555
-- 208:1323332111111111001121000012110001111110012344101111221112233441
-- 218:5555555555555555555555555555555555555555555555555555555555555555
-- 219:5555555555555555555555555555555555555555555555555555555555555555
-- 220:5555555555555555555555555555555555555555555555555555555555555555
-- 221:5555555555555555555555555555555555555555555555555555555555555555
-- 224:0230000002300000023000000230000002300000023000000110000011110000
-- 225:0211000002131100021333110213311002111000021000000110000011110000
-- 240:0033330003322330332442233444443334444443124444230124423000111100
-- 241:0003300000343300002423000024220000242200002422000011110000011000
-- 242:0003300000033000000320000002200000022000000220000002100000011000
-- 243:0003300000334300003242000022420000224200002242000011110000011000
-- 244:0000000002200210222222212222222102222210002221000002100000000000
-- 245:0000000002200210222222312222233102223310002331000003100000000000
-- 246:0000000002200310222233212223322102332210003221000002100000000000
-- 247:0000000002200210223322212332222103222210002221000002100000000000
-- 248:0000000003300210332222213222222102222210002221000002100000000000
-- </TILES3>

-- <TILES4>
-- 001:1111111111111111111111111111111111111111111111111111111111111111
-- 002:3333333303000000003000000003000000003000000003000000003000000003
-- 003:6000000600000000006006000006600000066000006006000000000060000006
-- 004:fffffffffffffffffff77fffff7777ffff7777fffff77fffffffffffffffffff
-- 005:7777777770000007700000077000000770000007700000077000000777777777
-- 006:0000000000000000000000000000000000077000007007000700007070000007
-- 007:aaaaaaaaa008800aa080080aa000800aa008000aa080000aa088880aaaaaaaaa
-- 008:aaaaaaaaa008800aa000080aa000800aa000080aa080080aa008800aaaaaaaaa
-- 009:aaaaaaaaa008800aa008800aa080800aa088880aa000800aa000800aaaaaaaaa
-- 010:4443444444244444422244443332244433233244323333341333333311333333
-- 011:4443444444442444444222444422333442333333323333333313333331113331
-- 012:3333333333333333333333333333332222221123333312333333123333331233
-- 013:3333333333333333333333332233332232111123332112333322223333222233
-- 014:3333333333333333333333332233332232111123332112333322223333222233
-- 015:3333333333333333333333332233332232111123332112333322223333222233
-- 016:0100000013100000133100001333100013333100133110000113100000000000
-- 024:0000000000000000000000000000000000000000111111113333333322222222
-- 025:0000000000000000000000000000000000000000111111113333333122222221
-- 026:2113333322213331222123222212222221112222111112221111112211111112
-- 027:1122232222122222222122222222122222211122221111122111111111111111
-- 028:3333123333331232333312113333111233331123333312333333123333331233
-- 029:3322223323222232112222112112211232111123332112333322223333222233
-- 030:3322223323222232112222112112211232111123332112333322223333222233
-- 031:3322223323222232112222112112211232111123332112333322223333222233
-- 035:0000000000000033003330330033333300033333033333330333333300333333
-- 036:0000330003303330333033303333333333333333333333333333333333333333
-- 037:0000220033202220332333203333332233333222333333323333333233333322
-- 038:0000000022000000220222002222220022222000222222202222222022222200
-- 040:0211111102100000021000000210000002100000021000000210000002100000
-- 041:1121111000210000002100000021000000210000002100000021000000210000
-- 042:3333122233321222333122223331222233312222333122223332122233331222
-- 043:2222333322233333222333332223333322233333222333332223333322223333
-- 044:3333123333331232333312113333111233331123333312333333123333331233
-- 045:3322223323222232112222112112211232111123332112333322223333222233
-- 046:3322223323222232112222112112211232111123332112333322223333222233
-- 047:3322223323222232112222112112211232111123332112333322223333222233
-- 051:0333333303333333022333330033333322333333223323330222233200022222
-- 052:3333333333333333333333333333333333333333233323332333233222332222
-- 053:3333333233333332333332223333332233333322333233222332222222222222
-- 054:2222220022222220222222202222200022222222222222222222222022222000
-- 056:0000000000000000000000000000000000000033033333220222222202222222
-- 057:3330000033200000222000002110000033333330222222202222222011222110
-- 058:3333222233333222333332223333322233333222333332223333322233332222
-- 059:2221333322212333222213332222133322221333222213332221233322213333
-- 060:3322223323222232333333333333333333333333333333332222222222222222
-- 061:3322223323222232333333333333333333333333333333332222222222222222
-- 062:3322223323222232333333333333333333333333333333332222222222222222
-- 063:3322223323222232333333333333333333333333333333332222222222222222
-- 066:0000000000000033003330330033333300033333033333330333333300333333
-- 067:2222332223323332333233323333333333333333333333333333333333333333
-- 068:2222332223323332333233323333333333333333333333333333333333333333
-- 069:2222332223323332333233323333333333333333333333333333333333333333
-- 070:2222222233222222332333223333332233333222333333323333333233333322
-- 071:0000000022000000220222002222220022222000222222202222222022222200
-- 072:0112222200221122002211110022211100022122000112220002222200011111
-- 073:1111222021111220111122202112222221222222222222222211111111100000
-- 074:5555555555555555555555555555555555555555555555555555555555555555
-- 075:5555555555555555555555555555555555555555555555555555555555555555
-- 076:0000000011000000111200001221200022221200222212002222312022223120
-- 077:2332333323332333233323332333233323332333233223332222333322222233
-- 078:3333333333333333333333333333333333333333333333333333333333333333
-- 079:3333233233323332333233323332333233323332333223323333222233222222
-- 082:0333333303333333022333330033333322333333223323330222233200022222
-- 083:3333333333333333333333333333333333333333233323332333233222332222
-- 084:3333333333333333333333333333333333333333233323332333233222332222
-- 085:3333333333333333333333333333333333333333233323332333233222332222
-- 086:3333333233333332333332223333332233333322333233222332222222222222
-- 087:2222220022222220222222202222200022222222222222222222222022222000
-- 089:1110000011100000221023002212210022221000231100002310000023200000
-- 090:5555555555555555555555555555555555555555555555555555555555555555
-- 091:5555555555555555555555555555555555555555555555555555555555555555
-- 092:2222322222223242111111112121224211111242111111112222224222223222
-- 093:2444443324444443244444432444444324444443244444232222223323333344
-- 094:3333343333333433333334334444444433433333334333333343333344444444
-- 095:3344444234444442344444423444444234444442324444423322222244333332
-- 096:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 098:0111122201111221000111110011111100111111001101110000011000000000
-- 099:1122221111222111111111111111111111111111111111111111111100111111
-- 100:1222122212221122122111111111111111111111222111111232211111232212
-- 101:2111222121111221111111111111111111121111122211112231112223211221
-- 102:1222211111222111111111111111111111111111111111111111111111111100
-- 103:2221111012211110111110001111110011111100111011000110000000000000
-- 104:5555555555555555000dd05500dddd5500dddd55000dd0550000005500000055
-- 105:0003000000322000032222000222220002222200022222000222220002222200
-- 106:5555555555555555555555555555555555555555555555555555555555555555
-- 107:5555555555555555555555555555555555555555555555555555555555555555
-- 108:1422312212223122212231222422312212223122122231222122312222223122
-- 109:2443333324443333244433332444344424443333244233332223333323333344
-- 110:3333343333333433333334334444444433433333334333333343333344444444
-- 111:3333344233334442333344424443444233334442333324423333322244333332
-- 115:0000111000000111000000120000000100000000000000000000000000000000
-- 116:0122332301223323202223232222232312222323023223230223232300232323
-- 117:2321221033222101332221123222212132321111332211103322111033221100
-- 118:0111000011100000110000001000000000000000000000000000000000000000
-- 120:0000005500000055000000550000005500000055000000550000005500000055
-- 121:3222222322212212222222120222220002222200022222000222220002222200
-- 122:5555555555555555555555555555555555555555555555555555555555555555
-- 123:5555555555555555555555555555555555555555555555555555555555555555
-- 124:2222322222223242111111112121224211111242111111112222224222223222
-- 125:2444443324444443244444432444444324444443244444232222223323333344
-- 126:3333343333333433333334334444444433433333334333333343333344444444
-- 127:3344444234444442344444423444444234444442324444423322222244333332
-- 128:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 132:0022332300223323002233230022332300223323002233230022332300223323
-- 133:3232110032321100323211003232110032321100323211003232110032321100
-- 136:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 137:5555555555555555555555555555555555555555555555555555555555555555
-- 138:4444444444444444443333334433333344333333443333334322222232222222
-- 139:4444444344444432333333223333332233333322333333222222222222222222
-- 140:3332333333323333444244442221222222212222222122221111111111111111
-- 141:3332333333323333444244442221222222212222222122221111111111111111
-- 142:3333333333333333333333333333333333333333333333333322222232222222
-- 143:3333333333333332333333223333332233333322333333222222222222222222
-- 148:0022322300223223002232330023323300233233023322330232133223211332
-- 149:3232110032321100323211002232110022322100122321101123221011133221
-- 150:0003300033233004331120440211333403323334433010300434010000433100
-- 151:5555555555555555555555555555555555555555555555555555555555555555
-- 152:0000005500000055000000550000005500000055000000550000005500000055
-- 153:5555555555555555555555555555555555555555555555555555555555555555
-- 154:4444444344444432333333223333332233333322333333222222222222222222
-- 155:4444444344444432443333224433332244333322443333224322222232222222
-- 156:4444444344444432333333223333332233333322333333222222222222222222
-- 157:4444444444444444443333334433333344333333443333334322222232222222
-- 158:1111111111111111222222222222222222222222222222222222222222222222
-- 159:3333333333333333333333333333333333333333333333333322222232222222
-- 160:0000000000000000000990000099990000999900000990000000000000000000
-- 161:0000000000000001000000010000100100001100000011130000121300001223
-- 162:0002000000022000100222001102222021112322221133223223332333233222
-- 163:0200000003200002033200232333223322332333222323323322232233322223
-- 164:2002000020022000101222001112222021112322221133222223332333233222
-- 165:0200000003200000033200002333200222332023222322333322233333322332
-- 166:0000000000000000200000002001000020110000211100002111200022122000
-- 168:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 169:5555555555555555555555555555555555555555555555555555555555555555
-- 170:4444444444444444443333334432222244323333443233334432333344323333
-- 171:4444444344444432333333222222332233334322333343223333432233334322
-- 172:4444444444444444443333334433333344333333443333334322222232222222
-- 173:4444444344444432333333223333332233333322333333222222222222222222
-- 174:1111111111111111222222222222222222222222222222222222222222222222
-- 175:1111111111111111222222222222222222222222222222222222222222222222
-- 177:0111122200111122000113330002223311112223011112220011111100000011
-- 178:3323222223222333222233323223331133122221112222221222112211111111
-- 179:2333223322222333223332222333223333322223111122222112222211222111
-- 180:3223222222222333222233323223332233222222333222221222112211111111
-- 181:2333232222222223212222332122133311212112111122222112222211222111
-- 182:2222211033221100312115552111222021122200112221112111111011111100
-- 183:0000000000000000555555550000000000000000000000000000000000000000
-- 184:0000005500000055555555550000000000000000000000000000000000000000
-- 185:5555555555555555555555550000000000000000000000000000000000000000
-- 186:4432333344323333443233334432333344334444443333334322222232222222
-- 187:3333432233334322333343223333432244444322333333222222222222222222
-- 188:4444444344444432443333224433332244333322443333224322222232222222
-- 189:1111111111111111222222222222222222222222222222222222222222222222
-- 190:4444444344444432333333223333332233333322333333222222222222222222
-- 191:4444444444444444443333334433333344333333443333334322222232222222
-- 192:0011110001122110012334100112211000122100111111111233232113223231
-- 202:5555555555555555555555555555555555555555555555555555555555555555
-- 203:5555555555555555555555555555555555555555555555555555555555555555
-- 204:5555555555555555555555555555555555555555555555555555555555555555
-- 205:5555555555555555555555555555555555555555555555555555555555555555
-- 208:1323332111111111001121000012110001111110012344101111221112233441
-- 218:5555555555555555555555555555555555555555555555555555555555555555
-- 219:5555555555555555555555555555555555555555555555555555555555555555
-- 220:5555555555555555555555555555555555555555555555555555555555555555
-- 221:5555555555555555555555555555555555555555555555555555555555555555
-- 224:0230000002300000023000000230000002300000023000000110000011110000
-- 225:0211000002131100021333110213311002111000021000000110000011110000
-- 240:0033330003322330332442233444443334444443124444230124423000111100
-- 241:0003300000343300002423000024220000242200002422000011110000011000
-- 242:0003300000033000000320000002200000022000000220000002100000011000
-- 243:0003300000334300003242000022420000224200002242000011110000011000
-- 244:0000000002200210222222212222222102222210002221000002100000000000
-- 245:0000000002200210222222312222233102223310002331000003100000000000
-- 246:0000000002200310222233212223322102332210003221000002100000000000
-- 247:0000000002200210223322212332222103222210002221000002100000000000
-- 248:0000000003300210332222213222222102222210002221000002100000000000
-- </TILES4>

-- <TILES5>
-- 001:1111111111111111111111111111111111111111111111111111111111111111
-- 002:3333333303000000003000000003000000003000000003000000003000000003
-- 003:6000000600000000006006000006600000066000006006000000000060000006
-- 004:fffffffffffffffffff77fffff7777ffff7777fffff77fffffffffffffffffff
-- 005:7777777770000007700000077000000770000007700000077000000777777777
-- 006:0000000000000000000000000000000000077000007007000700007070000007
-- 007:aaaaaaaaa008800aa080080aa000800aa008000aa080000aa088880aaaaaaaaa
-- 008:aaaaaaaaa008800aa000080aa000800aa000080aa080080aa008800aaaaaaaaa
-- 009:aaaaaaaaa008800aa008800aa080800aa088880aa000800aa000800aaaaaaaaa
-- 010:4443444444244444422244443332244433233244323333341333333311333333
-- 011:4443444444442444444222444422333442333333323333333313333331113331
-- 012:3333333333333333333333333333332222221123333312333333123333331233
-- 013:3333333333333333333333332233332232111123332112333322223333222233
-- 014:3333333333333333333333332233332232111123332112333322223333222233
-- 015:3333333333333333333333332233332232111123332112333322223333222233
-- 016:0100000013100000133100001333100013333100133110000113100000000000
-- 024:0000000000000000000000000000000000000000111111113333333322222222
-- 025:0000000000000000000000000000000000000000111111113333333122222221
-- 026:2113333322213331222123222212222221112222111112221111112211111112
-- 027:1122232222122222222122222222122222211122221111122111111111111111
-- 028:3333123333331232333312113333111233331123333312333333123333331233
-- 029:3322223323222232112222112112211232111123332112333322223333222233
-- 030:3322223323222232112222112112211232111123332112333322223333222233
-- 031:3322223323222232112222112112211232111123332112333322223333222233
-- 035:0000000000000033003330330033333300033333033333330333333300333333
-- 036:0000330003303330333033303333333333333333333333333333333333333333
-- 037:0000220033202220332333203333332233333222333333323333333233333322
-- 038:0000000022000000220222002222220022222000222222202222222022222200
-- 040:0211111102100000021000000210000002100000021000000210000002100000
-- 041:1121111000210000002100000021000000210000002100000021000000210000
-- 042:3333122233321222333122223331222233312222333122223332122233331222
-- 043:2222333322233333222333332223333322233333222333332223333322223333
-- 044:3333123333331232333312113333111233331123333312333333123333331233
-- 045:3322223323222232112222112112211232111123332112333322223333222233
-- 046:3322223323222232112222112112211232111123332112333322223333222233
-- 047:3322223323222232112222112112211232111123332112333322223333222233
-- 051:0333333303333333022333330033333322333333223323330222233200022222
-- 052:3333333333333333333333333333333333333333233323332333233222332222
-- 053:3333333233333332333332223333332233333322333233222332222222222222
-- 054:2222220022222220222222202222200022222222222222222222222022222000
-- 056:0000000000000000000000000000000000000033033333220222222202222222
-- 057:3330000033200000222000002110000033333330222222202222222011222110
-- 058:3333222233333222333332223333322233333222333332223333322233332222
-- 059:2221333322212333222213332222133322221333222213332221233322213333
-- 060:3322223323222232333333333333333333333333333333332222222222222222
-- 061:3322223323222232333333333333333333333333333333332222222222222222
-- 062:3322223323222232333333333333333333333333333333332222222222222222
-- 063:3322223323222232333333333333333333333333333333332222222222222222
-- 066:0000000000000033003330330033333300033333033333330333333300333333
-- 067:2222332223323332333233323333333333333333333333333333333333333333
-- 068:2222332223323332333233323333333333333333333333333333333333333333
-- 069:2222332223323332333233323333333333333333333333333333333333333333
-- 070:2222222233222222332333223333332233333222333333323333333233333322
-- 071:0000000022000000220222002222220022222000222222202222222022222200
-- 072:0112222200221122002211110022211100022122000112220002222200011111
-- 073:1111222021111220111122202112222221222222222222222211111111100000
-- 074:5555555555555555555555555555555555555555555555555555555555555555
-- 075:5555555555555555555555555555555555555555555555555555555555555555
-- 076:0000000011000000111200001221200022221200222212002222312022223120
-- 077:2332333323332333233323332333233323332333233223332222333322222233
-- 078:3333333333333333333333333333333333333333333333333333333333333333
-- 079:3333233233323332333233323332333233323332333223323333222233222222
-- 082:0333333303333333022333330033333322333333223323330222233200022222
-- 083:3333333333333333333333333333333333333333233323332333233222332222
-- 084:3333333333333333333333333333333333333333233323332333233222332222
-- 085:3333333333333333333333333333333333333333233323332333233222332222
-- 086:3333333233333332333332223333332233333322333233222332222222222222
-- 087:2222220022222220222222202222200022222222222222222222222022222000
-- 089:1110000011100000221023002212210022221000231100002310000023200000
-- 090:5555555555555555555555555555555555555555555555555555555555555555
-- 091:5555555555555555555555555555555555555555555555555555555555555555
-- 092:2222322222223242111111112121224211111242111111112222224222223222
-- 093:2444443324444443244444432444444324444443244444232222223323333344
-- 094:3333343333333433333334334444444433433333334333333343333344444444
-- 095:3344444234444442344444423444444234444442324444423322222244333332
-- 096:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 098:0111122201111221000111110011111100111111001101110000011000000000
-- 099:1122221111222111111111111111111111111111111111111111111100111111
-- 100:1222122212221122122111111111111111111111222111111232211111232212
-- 101:2111222121111221111111111111111111121111122211112231112223211221
-- 102:1222211111222111111111111111111111111111111111111111111111111100
-- 103:2221111012211110111110001111110011111100111011000110000000000000
-- 104:5555555555555555000dd05500dddd5500dddd55000dd0550000005500000055
-- 105:0003000000322000032222000222220002222200022222000222220002222200
-- 106:5555555555555555555555555555555555555555555555555555555555555555
-- 107:5555555555555555555555555555555555555555555555555555555555555555
-- 108:1422312212223122212231222422312212223122122231222122312222223122
-- 109:2443333324443333244433332444344424443333244233332223333323333344
-- 110:3333343333333433333334334444444433433333334333333343333344444444
-- 111:3333344233334442333344424443444233334442333324423333322244333332
-- 115:0000111000000111000000120000000100000000000000000000000000000000
-- 116:0122332301223323202223232222232312222323023223230223232300232323
-- 117:2321221033222101332221123222212132321111332211103322111033221100
-- 118:0111000011100000110000001000000000000000000000000000000000000000
-- 120:0000005500000055000000550000005500000055000000550000005500000055
-- 121:3222222322212212222222120222220002222200022222000222220002222200
-- 122:5555555555555555555555555555555555555555555555555555555555555555
-- 123:5555555555555555555555555555555555555555555555555555555555555555
-- 124:2222322222223242111111112121224211111242111111112222224222223222
-- 125:2444443324444443244444432444444324444443244444232222223323333344
-- 126:3333343333333433333334334444444433433333334333333343333344444444
-- 127:3344444234444442344444423444444234444442324444423322222244333332
-- 128:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 132:0022332300223323002233230022332300223323002233230022332300223323
-- 133:3232110032321100323211003232110032321100323211003232110032321100
-- 136:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 137:5555555555555555555555555555555555555555555555555555555555555555
-- 138:4444444444444444443333334433333344333333443333334322222232222222
-- 139:4444444344444432333333223333332233333322333333222222222222222222
-- 140:3332333333323333444244442221222222212222222122221111111111111111
-- 141:3332333333323333444244442221222222212222222122221111111111111111
-- 142:3333333333333333333333333333333333333333333333333322222232222222
-- 143:3333333333333332333333223333332233333322333333222222222222222222
-- 148:0022322300223223002232330023323300233233023322330232133223211332
-- 149:3232110032321100323211002232110022322100122321101123221011133221
-- 150:0003300033233004331120440211333403323334433010300434010000433100
-- 151:5555555555555555555555555555555555555555555555555555555555555555
-- 152:0000005500000055000000550000005500000055000000550000005500000055
-- 153:5555555555555555555555555555555555555555555555555555555555555555
-- 154:4444444344444432333333223333332233333322333333222222222222222222
-- 155:4444444344444432443333224433332244333322443333224322222232222222
-- 156:4444444344444432333333223333332233333322333333222222222222222222
-- 157:4444444444444444443333334433333344333333443333334322222232222222
-- 158:1111111111111111222222222222222222222222222222222222222222222222
-- 159:3333333333333333333333333333333333333333333333333322222232222222
-- 160:0000000000000000000990000099990000999900000990000000000000000000
-- 161:0000000000000001000000010000100100001100000011130000121300001223
-- 162:0002000000022000100222001102222021112322221133223223332333233222
-- 163:0200000003200002033200232333223322332333222323323322232233322223
-- 164:2002000020022000101222001112222021112322221133222223332333233222
-- 165:0200000003200000033200002333200222332023222322333322233333322332
-- 166:0000000000000000200000002001000020110000211100002111200022122000
-- 168:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 169:5555555555555555555555555555555555555555555555555555555555555555
-- 170:4444444444444444443333334432222244323333443233334432333344323333
-- 171:4444444344444432333333222222332233334322333343223333432233334322
-- 172:4444444444444444443333334433333344333333443333334322222232222222
-- 173:4444444344444432333333223333332233333322333333222222222222222222
-- 174:1111111111111111222222222222222222222222222222222222222222222222
-- 175:1111111111111111222222222222222222222222222222222222222222222222
-- 177:0111122200111122000113330002223311112223011112220011111100000011
-- 178:3323222223222333222233323223331133122221112222221222112211111111
-- 179:2333223322222333223332222333223333322223111122222112222211222111
-- 180:3223222222222333222233323223332233222222333222221222112211111111
-- 181:2333232222222223212222332122133311212112111122222112222211222111
-- 182:2222211033221100312115552111222021122200112221112111111011111100
-- 183:0000000000000000555555550000000000000000000000000000000000000000
-- 184:0000005500000055555555550000000000000000000000000000000000000000
-- 185:5555555555555555555555550000000000000000000000000000000000000000
-- 186:4432333344323333443233334432333344334444443333334322222232222222
-- 187:3333432233334322333343223333432244444322333333222222222222222222
-- 188:4444444344444432443333224433332244333322443333224322222232222222
-- 189:1111111111111111222222222222222222222222222222222222222222222222
-- 190:4444444344444432333333223333332233333322333333222222222222222222
-- 191:4444444444444444443333334433333344333333443333334322222232222222
-- 192:0011110001122110012334100112211000122100111111111233232113223231
-- 202:5555555555555555555555555555555555555555555555555555555555555555
-- 203:5555555555555555555555555555555555555555555555555555555555555555
-- 204:5555555555555555555555555555555555555555555555555555555555555555
-- 205:5555555555555555555555555555555555555555555555555555555555555555
-- 208:1323332111111111001121000012110001111110012344101111221112233441
-- 218:5555555555555555555555555555555555555555555555555555555555555555
-- 219:5555555555555555555555555555555555555555555555555555555555555555
-- 220:5555555555555555555555555555555555555555555555555555555555555555
-- 221:5555555555555555555555555555555555555555555555555555555555555555
-- 224:0230000002300000023000000230000002300000023000000110000011110000
-- 225:0211000002131100021333110213311002111000021000000110000011110000
-- 240:0033330003322330332442233444443334444443124444230124423000111100
-- 241:0003300000343300002423000024220000242200002422000011110000011000
-- 242:0003300000033000000320000002200000022000000220000002100000011000
-- 243:0003300000334300003242000022420000224200002242000011110000011000
-- 244:0000000002200210222222212222222102222210002221000002100000000000
-- 245:0000000002200210222222312222233102223310002331000003100000000000
-- 246:0000000002200310222233212223322102332210003221000002100000000000
-- 247:0000000002200210223322212332222103222210002221000002100000000000
-- 248:0000000003300210332222213222222102222210002221000002100000000000
-- </TILES5>

-- <TILES6>
-- 001:1111111111111111111111111111111111111111111111111111111111111111
-- 002:3333333303000000003000000003000000003000000003000000003000000003
-- 003:6000000600000000006006000006600000066000006006000000000060000006
-- 004:fffffffffffffffffff77fffff7777ffff7777fffff77fffffffffffffffffff
-- 005:7777777770000007700000077000000770000007700000077000000777777777
-- 006:0000000000000000000000000000000000077000007007000700007070000007
-- 007:aaaaaaaaa008800aa080080aa000800aa008000aa080000aa088880aaaaaaaaa
-- 008:aaaaaaaaa008800aa000080aa000800aa000080aa080080aa008800aaaaaaaaa
-- 009:aaaaaaaaa008800aa008800aa080800aa088880aa000800aa000800aaaaaaaaa
-- 010:4443444444244444422244443332244433233244323333341333333311333333
-- 011:4443444444442444444222444422333442333333323333333313333331113331
-- 012:3333333333333333333333333333332222221123333312333333123333331233
-- 013:3333333333333333333333332233332232111123332112333322223333222233
-- 014:3333333333333333333333332233332232111123332112333322223333222233
-- 015:3333333333333333333333332233332232111123332112333322223333222233
-- 016:0100000013100000133100001333100013333100133110000113100000000000
-- 024:0000000000000000000000000000000000000000111111113333333322222222
-- 025:0000000000000000000000000000000000000000111111113333333122222221
-- 026:2113333322213331222123222212222221112222111112221111112211111112
-- 027:1122232222122222222122222222122222211122221111122111111111111111
-- 028:3333123333331232333312113333111233331123333312333333123333331233
-- 029:3322223323222232112222112112211232111123332112333322223333222233
-- 030:3322223323222232112222112112211232111123332112333322223333222233
-- 031:3322223323222232112222112112211232111123332112333322223333222233
-- 035:0000000000000033003330330033333300033333033333330333333300333333
-- 036:0000330003303330333033303333333333333333333333333333333333333333
-- 037:0000220033202220332333203333332233333222333333323333333233333322
-- 038:0000000022000000220222002222220022222000222222202222222022222200
-- 040:0211111102100000021000000210000002100000021000000210000002100000
-- 041:1121111000210000002100000021000000210000002100000021000000210000
-- 042:3333122233321222333122223331222233312222333122223332122233331222
-- 043:2222333322233333222333332223333322233333222333332223333322223333
-- 044:3333123333331232333312113333111233331123333312333333123333331233
-- 045:3322223323222232112222112112211232111123332112333322223333222233
-- 046:3322223323222232112222112112211232111123332112333322223333222233
-- 047:3322223323222232112222112112211232111123332112333322223333222233
-- 051:0333333303333333022333330033333322333333223323330222233200022222
-- 052:3333333333333333333333333333333333333333233323332333233222332222
-- 053:3333333233333332333332223333332233333322333233222332222222222222
-- 054:2222220022222220222222202222200022222222222222222222222022222000
-- 056:0000000000000000000000000000000000000033033333220222222202222222
-- 057:3330000033200000222000002110000033333330222222202222222011222110
-- 058:3333222233333222333332223333322233333222333332223333322233332222
-- 059:2221333322212333222213332222133322221333222213332221233322213333
-- 060:3322223323222232333333333333333333333333333333332222222222222222
-- 061:3322223323222232333333333333333333333333333333332222222222222222
-- 062:3322223323222232333333333333333333333333333333332222222222222222
-- 063:3322223323222232333333333333333333333333333333332222222222222222
-- 066:0000000000000033003330330033333300033333033333330333333300333333
-- 067:2222332223323332333233323333333333333333333333333333333333333333
-- 068:2222332223323332333233323333333333333333333333333333333333333333
-- 069:2222332223323332333233323333333333333333333333333333333333333333
-- 070:2222222233222222332333223333332233333222333333323333333233333322
-- 071:0000000022000000220222002222220022222000222222202222222022222200
-- 072:0112222200221122002211110022211100022122000112220002222200011111
-- 073:1111222021111220111122202112222221222222222222222211111111100000
-- 074:5555555555555555555555555555555555555555555555555555555555555555
-- 075:5555555555555555555555555555555555555555555555555555555555555555
-- 076:0000000011000000111200001221200022221200222212002222312022223120
-- 077:2332333323332333233323332333233323332333233223332222333322222233
-- 078:3333333333333333333333333333333333333333333333333333333333333333
-- 079:3333233233323332333233323332333233323332333223323333222233222222
-- 082:0333333303333333022333330033333322333333223323330222233200022222
-- 083:3333333333333333333333333333333333333333233323332333233222332222
-- 084:3333333333333333333333333333333333333333233323332333233222332222
-- 085:3333333333333333333333333333333333333333233323332333233222332222
-- 086:3333333233333332333332223333332233333322333233222332222222222222
-- 087:2222220022222220222222202222200022222222222222222222222022222000
-- 089:1110000011100000221023002212210022221000231100002310000023200000
-- 090:5555555555555555555555555555555555555555555555555555555555555555
-- 091:5555555555555555555555555555555555555555555555555555555555555555
-- 092:2222322222223242111111112121224211111242111111112222224222223222
-- 093:2444443324444443244444432444444324444443244444232222223323333344
-- 094:3333343333333433333334334444444433433333334333333343333344444444
-- 095:3344444234444442344444423444444234444442324444423322222244333332
-- 096:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 098:0111122201111221000111110011111100111111001101110000011000000000
-- 099:1122221111222111111111111111111111111111111111111111111100111111
-- 100:1222122212221122122111111111111111111111222111111232211111232212
-- 101:2111222121111221111111111111111111121111122211112231112223211221
-- 102:1222211111222111111111111111111111111111111111111111111111111100
-- 103:2221111012211110111110001111110011111100111011000110000000000000
-- 104:5555555555555555000dd05500dddd5500dddd55000dd0550000005500000055
-- 105:0003000000322000032222000222220002222200022222000222220002222200
-- 106:5555555555555555555555555555555555555555555555555555555555555555
-- 107:5555555555555555555555555555555555555555555555555555555555555555
-- 108:1422312212223122212231222422312212223122122231222122312222223122
-- 109:2443333324443333244433332444344424443333244233332223333323333344
-- 110:3333343333333433333334334444444433433333334333333343333344444444
-- 111:3333344233334442333344424443444233334442333324423333322244333332
-- 115:0000111000000111000000120000000100000000000000000000000000000000
-- 116:0122332301223323202223232222232312222323023223230223232300232323
-- 117:2321221033222101332221123222212132321111332211103322111033221100
-- 118:0111000011100000110000001000000000000000000000000000000000000000
-- 120:0000005500000055000000550000005500000055000000550000005500000055
-- 121:3222222322212212222222120222220002222200022222000222220002222200
-- 122:5555555555555555555555555555555555555555555555555555555555555555
-- 123:5555555555555555555555555555555555555555555555555555555555555555
-- 124:2222322222223242111111112121224211111242111111112222224222223222
-- 125:2444443324444443244444432444444324444443244444232222223323333344
-- 126:3333343333333433333334334444444433433333334333333343333344444444
-- 127:3344444234444442344444423444444234444442324444423322222244333332
-- 128:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 132:0022332300223323002233230022332300223323002233230022332300223323
-- 133:3232110032321100323211003232110032321100323211003232110032321100
-- 136:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 137:5555555555555555555555555555555555555555555555555555555555555555
-- 138:4444444444444444443333334433333344333333443333334322222232222222
-- 139:4444444344444432333333223333332233333322333333222222222222222222
-- 140:3332333333323333444244442221222222212222222122221111111111111111
-- 141:3332333333323333444244442221222222212222222122221111111111111111
-- 142:3333333333333333333333333333333333333333333333333322222232222222
-- 143:3333333333333332333333223333332233333322333333222222222222222222
-- 148:0022322300223223002232330023323300233233023322330232133223211332
-- 149:3232110032321100323211002232110022322100122321101123221011133221
-- 150:0003300033233004331120440211333403323334433010300434010000433100
-- 151:5555555555555555555555555555555555555555555555555555555555555555
-- 152:0000005500000055000000550000005500000055000000550000005500000055
-- 153:5555555555555555555555555555555555555555555555555555555555555555
-- 154:4444444344444432333333223333332233333322333333222222222222222222
-- 155:4444444344444432443333224433332244333322443333224322222232222222
-- 156:4444444344444432333333223333332233333322333333222222222222222222
-- 157:4444444444444444443333334433333344333333443333334322222232222222
-- 158:1111111111111111222222222222222222222222222222222222222222222222
-- 159:3333333333333333333333333333333333333333333333333322222232222222
-- 160:0000000000000000000990000099990000999900000990000000000000000000
-- 161:0000000000000001000000010000100100001100000011130000121300001223
-- 162:0002000000022000100222001102222021112322221133223223332333233222
-- 163:0200000003200002033200232333223322332333222323323322232233322223
-- 164:2002000020022000101222001112222021112322221133222223332333233222
-- 165:0200000003200000033200002333200222332023222322333322233333322332
-- 166:0000000000000000200000002001000020110000211100002111200022122000
-- 168:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 169:5555555555555555555555555555555555555555555555555555555555555555
-- 170:4444444444444444443333334432222244323333443233334432333344323333
-- 171:4444444344444432333333222222332233334322333343223333432233334322
-- 172:4444444444444444443333334433333344333333443333334322222232222222
-- 173:4444444344444432333333223333332233333322333333222222222222222222
-- 174:1111111111111111222222222222222222222222222222222222222222222222
-- 175:1111111111111111222222222222222222222222222222222222222222222222
-- 177:0111122200111122000113330002223311112223011112220011111100000011
-- 178:3323222223222333222233323223331133122221112222221222112211111111
-- 179:2333223322222333223332222333223333322223111122222112222211222111
-- 180:3223222222222333222233323223332233222222333222221222112211111111
-- 181:2333232222222223212222332122133311212112111122222112222211222111
-- 182:2222211033221100312115552111222021122200112221112111111011111100
-- 183:0000000000000000555555550000000000000000000000000000000000000000
-- 184:0000005500000055555555550000000000000000000000000000000000000000
-- 185:5555555555555555555555550000000000000000000000000000000000000000
-- 186:4432333344323333443233334432333344334444443333334322222232222222
-- 187:3333432233334322333343223333432244444322333333222222222222222222
-- 188:4444444344444432443333224433332244333322443333224322222232222222
-- 189:1111111111111111222222222222222222222222222222222222222222222222
-- 190:4444444344444432333333223333332233333322333333222222222222222222
-- 191:4444444444444444443333334433333344333333443333334322222232222222
-- 192:0011110001122110012334100112211000122100111111111233232113223231
-- 202:5555555555555555555555555555555555555555555555555555555555555555
-- 203:5555555555555555555555555555555555555555555555555555555555555555
-- 204:5555555555555555555555555555555555555555555555555555555555555555
-- 205:5555555555555555555555555555555555555555555555555555555555555555
-- 208:1323332111111111001121000012110001111110012344101111221112233441
-- 218:5555555555555555555555555555555555555555555555555555555555555555
-- 219:5555555555555555555555555555555555555555555555555555555555555555
-- 220:5555555555555555555555555555555555555555555555555555555555555555
-- 221:5555555555555555555555555555555555555555555555555555555555555555
-- 224:0230000002300000023000000230000002300000023000000110000011110000
-- 225:0211000002131100021333110213311002111000021000000110000011110000
-- 240:0033330003322330332442233444443334444443124444230124423000111100
-- 241:0003300000343300002423000024220000242200002422000011110000011000
-- 242:0003300000033000000320000002200000022000000220000002100000011000
-- 243:0003300000334300003242000022420000224200002242000011110000011000
-- 244:0000000002200210222222212222222102222210002221000002100000000000
-- 245:0000000002200210222222312222233102223310002331000003100000000000
-- 246:0000000002200310222233212223322102332210003221000002100000000000
-- 247:0000000002200210223322212332222103222210002221000002100000000000
-- 248:0000000003300210332222213222222102222210002221000002100000000000
-- </TILES6>

-- <TILES7>
-- 000:ccccccccccccccccc000000cc000000cc000000cc000000cc000000cc000000c
-- 001:cccccccccccccccccc000ecccc0000cccc000dcccc00dccccc0dccceccde0dcc
-- 002:ccccccccccccccccc000dcc0c000dcc0c000dcc0c000dcc00000dcc0c000dcc0
-- 003:cccccccccccccccc0ecce00000ee00000000000000ece00d0cccd0ec00ccd00c
-- 004:cccccccccccccccc000000000000000000000000ce0dcce0cccccccdcce0eccc
-- 005:cccccccccccccccc0000000000000000000000000000edcd000dccdc00ccce00
-- 006:ccccccccccccccccdcc00000dcc00000dcc00000dcc00000ccc00000dcc00000
-- 007:cccccccccccccccc0000dccc0000cccc0000cccc0000cccc0000dccc000000ed
-- 008:cccccccccccccccc00000c0000000e00d0000000cde00000ccccde00ccccccd0
-- 009:cccccccccccccccc000000000000000000000000000edccd00eccdcc0cce000c
-- 010:cccccccccccccccc00000000000000000000000000000edcd000cccdc00ccc00
-- 011:cccccccccccccccc000000000000000000000000ce0000dcdcc00dcc0ccd00cc
-- 012:cccccccccccccccc00000000000000000000000000dd0000ddcc8000cc000000
-- 013:cc000000cc0000000c0000000c0000000c0000000c0000000c0000000c000000
-- 016:c000000cc000000cc000000cc000000cc000ccccc000ccccc000ccccc000cccc
-- 017:cc0000cccc0000eccc00000ccc0000dccccccccccccccccccccccccccccccccc
-- 018:cd00dcc0cc00dcc0cc00dcc0cc00dcc0cccccccccccccccccccccccccccccccc
-- 019:00ccd00c00ccd00c00ccd00c00ccd00ccccccccccccccccccccccccccccccccc
-- 020:cc800ccccc008ccccc008ccccc008cccccccdccccccddccccc000000c0000000
-- 021:eeccc000edccc000edccc000eeccce00ccccccccd0edcccc0000000000000000
-- 022:dcc00000dcc00000dcc00000dcc00000cccc0000dccd00000000000000000000
-- 023:00000000000000000000d0000000cc000000eccc000000ed0000000000000000
-- 024:0dccccc0000eccc00000ccc00000ccd0cccccccccccccccc0000eccc000000cc
-- 025:dcc008ccdccdccccdccccde8eccd0000cccccccccccccccccccccccccccccccc
-- 026:c08ccd0000ecccdc000ccccd080ccc00cccccccccccccccccccccccccccccccc
-- 027:ecc000cccc0000ccd00000cc000e00cccccccccccccccccccccccccccccccccc
-- 028:ce000000c0000000c8000000c8000000ccccc000ccccc000ccccc000ccccc000
-- 029:0c0000000c0000000c0000000c0000000c0000000c0000000c0000000c000000
-- 032:c000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000cccc
-- 033:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 034:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 035:ccccccccccccccc0ccccccc0ccccccc0cccccce0cccccc00ccccc000ccccd000
-- 037:0000000000000000000000000000000000000000000000440e44444404444444
-- 038:000000000000000000000000000000000ede000044444d004444444044444440
-- 040:000000dc00000000000000000000000000000000000000000000000000000000
-- 041:ccccccccccccccccdccccccc8ccccccc0dcccccc00cccccc00eccccc000ccccc
-- 042:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 043:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 044:ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000
-- 045:0c0000000c0000000c0000000c0000000c0000000c0000000c0000000c000000
-- 048:c000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000cccc
-- 049:ccccccccccccccc0ccccccd0ccccccd0ccccccc0ccccccc0cccccccdcccccccc
-- 050:e00dcccc0cd0ccccdccddcccdc084ccc8ccccccc0ccccccd000ee000ce000080
-- 051:cccce000cccc0000ccc00000cc400000ce0000008000000000008000dcccce00
-- 052:0000000000000000000000000000000000000000000000000000000300000004
-- 053:0444444404444444e4444444d444444444444444444444444444444444444d8a
-- 054:44444440444444404444444444444444444444444444444444444444aaaaa880
-- 055:000000000000000000000000d00000004e00000044e00000444d0000ed444e00
-- 057:000ccccc000ccccc0000eccc000000cc0000000e000000000000000000000000
-- 058:ccccccccccccccccccccccccccccccccccccccccdccccccc0ecccccc000000ec
-- 059:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 060:ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000
-- 061:0c0000000c0000000c0000000c0000000c0000000c0000000c0000000c000000
-- 064:c000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000cccc
-- 065:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 066:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 067:ccccc000ccccc000ccccd000cccce000ccce0000ccc00000ccd00000cd000000
-- 068:00000034000000440000004400000e4d0000000a000008aa00000aaa0000aaaa
-- 069:4444e0aa4430008a4800008a0088aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 070:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 071:a80e4440aaaa0e44aaaaa00eaaaaaa80aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa88
-- 072:00000000d00000004e00000004400000a0004400aaa00e30aaaaa0808aaaaa00
-- 074:000000000000000000000000000000000000dccc0000cccc0000cccc0000cccc
-- 075:8ccccccc0dcccccc00dccccc000cccccc000cccccd00dccccc000ccccce00ccc
-- 076:ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000
-- 077:0c0000000c0000000c0000000c0000000c0000000c0000000c0000000c000000
-- 080:c000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000cccd
-- 081:cccccccccccccccdcccce000ccce0000cce00000ce0000000000dccc00ee0080
-- 082:ccccccccdddddd0000000000000000000000000000000000ccccc000eccccc00
-- 083:e000000000000000000000000000000000000000000000000000000000000000
-- 084:0000aaaa0000aaaa0000aaaa0000aaaa0000aaaa0000aaaa0000a8000000008a
-- 085:aaaaaaaaaaaaaaaaaaaaaaaaaaa808aaa800aaaa80aaaaaaaaaaaaa8aaaaaa0d
-- 086:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa808aaa00e300004444444444444444
-- 087:a00aaaaaaaaaaaaaaaaaaaa8aaaaaaa8aaaaaaaa08aaaaaa44e008804444eeee
-- 088:88000000aa88000a00000008aaaaaa00aaaaaa00aaaaa000000034e03dd444e8
-- 089:0000000080000000a0000000a0000000a0000000a00000008800000008000000
-- 090:0000cccc0000cccc00000ded0000008c00000dcc0000eccc00000dcc000000cc
-- 091:ccc00eccccce00cccccd00cccccd00cccccc00cccccc00ccccce0eccccce0dcc
-- 092:ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000
-- 093:0c0000000c0000000c0000000c0000000c0000000c0000000c0000000c000000
-- 096:c000ccc0c000ccc0c000ccc0c000ccc0c000ccc8c000ccccc000ccccc000cccc
-- 097:0ed0e0000c80ccc80c0ecccd0ecccccc008dccd800000000c0000000cccccccc
-- 098:0ccccc000ccccc000dcccc000dcccc000dcccc000ccccc00eccccd00ccccc800
-- 100:00000aaa00000aaa00000aaa000000aa00000000000000000000000000000000
-- 101:aaaaa8e4aaaa0e44aa8e444484444444d44444444444444444444444d4444444
-- 102:44444444444444444444444444444d4e444d0033e044d80d30e44de444444444
-- 103:4444444444444444444444444444444444444444444444444444444444444444
-- 104:444444084444440a4444440a44444d8844444ea0444440a04444d080444d080a
-- 105:0800000000000000800000008000000080000000800000008000000000000000
-- 106:000000dc000000ec0000000c0000000e0000000e0000000e0000000e0000000d
-- 107:ccc00cccccd00ccccce0dccccd0eccccce0cccccc00cccccc0dccccccecccccc
-- 108:ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000
-- 109:0c0000000c0000000c0000000c0000000c0000000c0000000c0000000c000000
-- 112:c000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000cccc
-- 113:ccccccccccccccccccccccccccccccccccccccccccccccc0ccccce00cccc0000
-- 114:ccccd000cccd0000ccc00000cc800000e00000000000dd00000ccc000eccd000
-- 117:e44444440444444404444444044444440d4444440044444400d4444400e44444
-- 118:4444444444444434442220024202222024222223444444444244444242022220
-- 119:444444444444444444444444044444442024444440444444004444440244444d
-- 120:44400a0844d00a8044008aa04d00aaa0400aa000408a800030aa080000aa0a00
-- 122:0000000c000000ec000000cc00000ecc0000eccc0000cccc0000cccc0000cccc
-- 123:ccccccccdcccccccecccccccecccccccdcc0cccccdc8dcccc80ecccccccccccc
-- 124:ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000
-- 125:0c0000000c0000000c0000000c0000000c0000000c0000000c0000000c000000
-- 128:c000ccccc000ccccc000ccc0c000ccc0c000cce0c000cd0ec000000cc000000c
-- 129:ccce000dd000cccd008cde0000cd000eece00dcccd00ccccc00eccc0d00dcc00
-- 130:ccd000000000000000000000dd000000c8000000c00000000000000000000000
-- 133:000444440000344400000d4400000044000000440000000d0000000000000000
-- 134:4402000044444444444444444444444444444444444444440044444400044444
-- 135:2444444044444e004444d00044440000444400084448008a40000aaa00008aaa
-- 136:08a08a000a80a0000a088000a80a0000a08a0000a0a80000aa8000000a000000
-- 137:000000000000000000000000000000000000000000000000800000003000000c
-- 138:000dcccc00cccccc0ecccccc0ccccccceccccccccccccccccccccccccccccccc
-- 139:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 140:ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000
-- 141:0c0000000c0000000c0000000c0000000c0000000c0000000c0000000c000000
-- 144:c00000ecc00000dcc00000dcc000000cc000000cc000e000c0000000c000ccce
-- 145:d00cc000d00c0000d00d0000d0000000d000000000000000000000e000004000
-- 150:0000e440000000000000000000000000000000000000000a0000000a00008aaa
-- 151:0000aaaa0000aaa0000aaaa008aaaa0a8aaaa08aaaaa80aaaaaa08a8aaa88aa0
-- 152:0a0000000800000ea0000004a00000d480000044000000440000004400000044
-- 153:4e0000ec4d0000dc440000dc44e000cc443000cc444000dc4440000c44400000
-- 154:ccccccccccccccccccccccccccccccccccccccccce00ccccc0cc0ccccccc0dcc
-- 155:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 156:ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000
-- 157:0c0000000c0000000c0000000c0000000c0000000c0000000c0000000c000000
-- 160:c000ccccc000cccdc000cccec000ccc0c000cc44c000cce4c000cc04c000cd34
-- 161:000400000e4400000444d0004444440044444448444444404444444044444440
-- 162:00000000000000000000000000000000000000000000000d0000004400008d44
-- 163:00de000000444e000044444000444443e4444444444444444444444444444444
-- 164:000000000000000000000000000000004d000000444000004444dee044444444
-- 165:00000000000000000000000000000000000000aa00000aaa0008aaaad8aaaaaa
-- 166:0008aaaa000aaaaa00aaaaaa8aaaaaaaaaaaaaa0aaaaaaa0aaaaaa08aaaaa00a
-- 167:aaa0aa00aa00aa00a808a000a00aa0000aaa00008aaa0000aaaa0000aaa80000
-- 168:0000004400000044000000440000004400000044000000440000004400000044
-- 169:444d00004444e000444440004444440044444444444444444444444444444444
-- 170:cccd0ccceee0dccc0000cccc000ecccc0000000e30000ecc4e00000000080000
-- 171:cecccccccecccccccdccccccdccccccccccccccccccccccc0000000000000000
-- 172:ccccc000ccccc000ccccc000ccccc000ccccc000ccccc000eeddc00000000000
-- 173:0c0000000c0000000c0000000c0000000c0000000c0000000c0000000c000000
-- 176:c000c044c000d344c000e444c0000444c0000d44c000000ec0000000c0000000
-- 177:444444404444448044444e004444d0004444000eeee000030000000000000000
-- 178:000044440e44444404444444e4444444444444cc33333dcc0000dcc00000ccc0
-- 179:44444444444444444440e4444440444dcccde3e0cccccd080000cc0000000d00
-- 180:4444444e444408aa44e0aaaa008aaaaa8aaaaaaa8888888800cc00000ecc0000
-- 181:0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa8aaaaaa08888800080000000000000000
-- 182:aaa8000aaa000aaaa000aaaa000aaaaaaa0aaaaa8888888a0000000000000000
-- 183:aaa00000aa000000a8000000a0000000adcc0000cccc000d0ccc00dc8ccc000e
-- 184:00000044000000d3000000000000000000000000c0000000c0000000e0000000
-- 185:4444444e333e000000000008000008aa000aaaaa088888800000000000000000
-- 186:000a8008aaa0808aa80080aa800800aa000a00aa008800880000000000000000
-- 187:0000d4440004444400e444440044444403444444033333330000000000000000
-- 188:dee0000044444000444440004444400044444000333338000000000000000000
-- 189:0c0000000c0000000c0000000c0000000c0000000c0000000c0000000c000000
-- 192:c0000000c0000000c0000000c0000000c0000000c0000000c0000000c0000000
-- 194:0000cccc0000cccc0000eccc000000ec0000000000000000000ece00000ecc00
-- 195:e0000000ccd0000cccccd00dccccccc08edcccc0000cccc0000dccc0000cccd0
-- 196:0ccc0000cccccd0eccccde0ceccc0000eccc0000eccc0000eccc0000eccc0008
-- 197:00000000dc000ecccce00dcccce000cccce000cccce000cccce000cccce00ecc
-- 198:00000000e000edcce00dcccde00ccc00e00ccd00e0ecce00e00ccd00e00ccc00
-- 199:8ccc0000dccc00edcccc0ecc0ccc00ec8ccc00ec8ccc00ec8ccc00ececcc00ec
-- 200:00000000c00000ccc0000cccc00ecc00c00dcc00c00dcc00c00dcc00c00ecce0
-- 201:00000000ccc00000edcc000000ecce0d008ccd0e000ccd00000cce0000ecc00e
-- 202:00080000dcccce00ccdecc00ccd00000cccce000cccccc000dccccd0000eccd0
-- 205:0c0000000c0000000c0000000c0000000c0000000c0000000c0000000c000000
-- 208:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 209:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 210:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 211:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 212:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 213:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 214:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 215:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 216:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 217:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 218:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 219:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 220:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 221:cc000000cc000000000000000000000000000000000000000000000000000000
-- 224:06666660666cc66666c66c6666c66c6666cccc6666c66c668666666808888880
-- 225:0222222022ccc22222c22c2222ccc22222c22c2222ccc2228222222808888880
-- 226:0ffffff0fdcccddffccddcdffccddcdffcccccdffccddcdffeeeeeefffffffff
-- 227:0ffffff0fdccccdffcccdddffdcccddffddcccdffccccddffeeeeeefffffffff
-- 240:0aaaaaa0aacaacaaaacaacaaaaaccaaaaacaacaaaacaacaa8aaaaaa808888880
-- 241:0333333033c33c3333c33c33333ccc3333333c33333cc3338333333808888880
-- 242:0ffffff0fcccccdffddccddffdccdddffccddddffcccccdffeeeeeefffffffff
-- 243:0ffffff0fccddcdffccddcdffdcccddffccddcdffccddcdffeeeeeefffffffff
-- </TILES7>

-- <SPRITES>
-- 000:00000000000c55550000c7770000c888000cc888000c55550000c5550000c555
-- 001:000000005555c0007575cc0085552350555c1250555c125055dc255055cd5550
-- 002:0000000000000000000c55550000c7770000c888000cc888000c55550000c555
-- 003:00000000000000005555c0007575cc00855c2350555c125055dc125055cd2550
-- 004:0000000000000000000c55550000c7770000c888000cc888000c55550000c555
-- 005:00000000000000005555c0007575cc00855c2350555c125055dc125055cd2550
-- 006:0000000000000000000c55550000c7770000c888000cc888000c55550000c555
-- 007:00000000000000005555cc0075752350855c1250555c125055dc255055cd5550
-- 008:0000000000000000000c55550000c7770000c888000cc888000c55550000c555
-- 009:00000000000000005555c0007575cc00855c2350555c125055dc125055cd2550
-- 010:000000000000000000000000000c55550000c7770000c888000cc888000c5555
-- 011:0000000000000000000000005555c0007575cc00855c2d50555c1250551c1250
-- 012:00000000000000000000000000000000000555570000c7770000c8880000c885
-- 013:00000000000000000000000000000000751d550015552d505555125055551250
-- 014:00000000000000000000000000000000000000000000000000000000000ccccc
-- 015:00000000000000000000000000000000000000000000000000000000c00000c0
-- 016:000cc55d00c8c5de00c88ccc000ccd110000cccc0000cddc0000cc5c00000ccc
-- 017:dccc3550ec8c3350c88ccc00ddcc0000cccc0000cddc0000cc5c0000cccc0000
-- 018:000cc55d00c8c5de00c88ccc000ccd110000cccc0000cddc0000cc5c00000ccc
-- 019:dccc5550ec8c3550c88c3350ddcccc00cccc0000cddc0000cc5c0000cccc0000
-- 020:0000c55d000cc5de00c8cccc00c88d11000ccccc0000cddc0000cc5c00000ccc
-- 021:dccc5550ecec3550cc8c3350d88ccc00cccc0000cddc0000cc5c0000cccc0000
-- 022:000cc55d00c8c5de00c88ccc000ccd110000cccc0000cddc0000cc5c00000ccc
-- 023:dccc3550ec8c3350c88ccc00ddcc0000cccc0000cddc0000cc5c0000cccc0000
-- 024:0000c5550000c555000c8ccc000c8ddd0000cccc00000cd500000ccc00000000
-- 025:5ccc55505c8c3550cc8c3350ddcccc00cccc0000cddc0000ccc5c00000ccc000
-- 026:0000c5550000c5550000c55500000ccc00000cdd00000ccc000000c50000000c
-- 027:55c125505ccc5550558cd550cc8cdd50ddcccc00cccc0000cddc0000cccc0000
-- 028:0000c5550000c555000cc555000c1555000cc1cc0000cccd0000000500000000
-- 029:5515255055c155505cccd5505c1cdd50cc1ccc00dddcc0001cc1c000ccccc000
-- 030:0ccddc550c5cdc5500ccdcc50c5ddce50cccc35e0c88133c0c88c13300555522
-- 031:5ccccc50558887505888875058877750c5875550c5555550c557555055555500
-- 032:00000000000c55550000c7770000c8880cccc8880c8855550c88c55500ccc55d
-- 033:000000005555c0007575cc008555c350555c1250555c125055dc2550ddec5550
-- 034:00000000000c55550000c7770000c8880cccc8880c8855550c88c55500ccc55d
-- 035:000000005555c0007575cc008555c350555c1250555c125055dc2550ddec5550
-- 036:00000000000c55550000c7770000c888000cc888000c555500ccc55500c8c55d
-- 037:000000005555c0007575cc008555c350555c1250555c125055dc2550ddec5550
-- 038:000c55550000c7770000c888000cc888000c55550000c5550000c5550000c55d
-- 039:5555c0007575c0008555c000555ccc00555c235055cc12505dcc1250dec32550
-- 040:000c55550000c7770000c888000cc888000c55550000c5550000c5550000c55d
-- 041:5555c0007575c0008555c000555ccc00555c235055cc12505dcc1250dec32550
-- 042:000c55550000c7770000c888000cc888000c55550000c5550000c5550000c55d
-- 043:5555c0007575c0008555c000555ccc00555c235055cc12505dcc1250dec32550
-- 044:000c55550000c7770000c888000cc888000c55550000c5550000c5550000c55d
-- 045:5555c0007575c0008555c000555ccc00555c235055cc12505dcc1250dec32550
-- 046:00000000000c55550000c7770000c888000cc888000c555500ccc55500c8c55d
-- 047:000000005555c0007575cc008555c350555c1250555c125055dc2550ddec3550
-- 048:0000c55d0000c5de0000cccc0000cd110000cccc0000cd5c00000ccc00000000
-- 049:eeec3550eec88350ccc78c00ddccc000cccc0000cddc0000cc5c00000ccc0000
-- 050:0000c55d0000c5de0000cccc0000cd110000cccc0000cd5c00000ccc00000000
-- 051:eeec3550eec88350ccc78c00ddccc000cccc0000cddc0000cc5c00000ccc0000
-- 052:00c7c55d000cc5de000ccccc0000cd110000cccc0000ccd500000ccc00000000
-- 053:eeec3550eec88350ccc88c00ddccc000ccccc000ccddc0000cc5c00000ccc000
-- 054:00ccc55d00c8c5de000ccccc0000cd110000cccc0000cddc0000cc5c00000cc0
-- 055:eecc5550e88c3550c88d3350ddcccc00ccccc0000cd5c0000cccc00000000000
-- 056:0000c55d000cc5de000c8ccc0000cd110000cccc0000cddc0000c5cc0000ccc0
-- 057:88cc555088cc3550cccd3350ddcccc00ccccc0000cd5c0000cccc00000000000
-- 058:0000c55d000cc5de000c8ccc0000cd110000cccc0000cddc0000c5cc0000ccc0
-- 059:88cc555088cc3550cccd3350ddcccc00ccccc0000cd5c0000cccc00000000000
-- 060:00ccc55d00c8c5de000ccccc0000cd110000cccc0000cddc0000cc5c00000cc0
-- 061:eecc5550e88c3550c88d3350ddcccc00ccccc0000cd5c0000cccc00000000000
-- 062:00c7c55d000cc5de000ccccc0000cd110000cccc0000ccd500000ccc00000000
-- 063:eeec5550eec88350ccc88c00ddccc000ccccc000ccddc0000cc5c00000ccc000
-- 064:00000000000c55550000c7770000c8880cccc8880c8855550c88c55500ccc55d
-- 065:000000005555c0007575cc008555c350555cc2505558855055c78550ddcccd50
-- 066:00000000000000000000000000000000000000000000000000555555000c7777
-- 067:000000000000000000000000000000000000000000000000555c0000575cc000
-- 080:0000c55d0000c5de0000cccc0000cd110000cccc0000cd5c00000ccc00000000
-- 081:eeec3250eecc3350cccc3500ddccc000cccc0000cddc0000cc5c00000ccc0000
-- 082:000c888800cc888500c55555000c5555000cccdd000cccce000c8ccc000c77cc
-- 083:55c2cc0055cc2cc05dcc555c5ccccccccc88ccccec88ccc0ccccdcc0cccccc00
-- 128:000000000000000000cc0ccc0c99c99900cc92aa00c92aaa00c9aaaa0c92aaaa
-- 129:0000000000000000cc00cc0099cc99c0aa99cc00aaaa9c00aaaaa9c0aaaaa99c
-- 130:000000000000000000c000000c9c0ccc00c9c999000c92aa00c92aaa00c9aaaa
-- 131:000000000000000000000c00cc00c9c099cc9c00aa99c000aaaa9c00aaaaa9c0
-- 132:00000000000000000000000000c000cc0c9c0c9900c9c2aa000c2aaa00c9aaaa
-- 133:000000000000000000000000cc0000c099cc0c9caa99c9c0aaaa9c00aaaaa9c0
-- 134:000000000000000000c000000c9c0ccc00c9c999000c92aa00c92aaa00c9aaaa
-- 135:000000000000000000000c00cc00c9c099cc9c00aa99c000aaaac000aaaaac00
-- 144:0c92aaaac999aaaa9c99aaaacc999aaa0c9999990cc9999900ccc999000ccccc
-- 145:aaaaa9c9aaaaa9ccaaaaa9c0aaaa99c0aaa999c099999cc09999cc00ccccc000
-- 146:0c92aaaa0c92aaaac999aaaa9c99aaaacc999aaa0cc9999900ccc999000ccccc
-- 147:aaaaa99caaaaa9c9aaaaa9ccaaaaa9c0aaaa99c0aaa99cc09999cc00ccccc000
-- 148:0c92aaaacc92aaaa9999aaaac999aaaac9999aaacc9999990cccc99900cccccc
-- 149:aaaaa99caaaaa9c9aaaaa9ccaaaaa99caaaa999caaa999cc9999ccc0cccccc00
-- 150:0c92aaaa0c92aaaac999aaaa9c999aaacc9999990cc9999900ccc999000ccccc
-- 151:aaaaa9c0aaaaac90aaaaacc0aaaa9c00aaa99c009999cc009999c000ccccc000
-- 160:1110000091110000099100000009110b0000bbbb0000bbb5000b555a00b55355
-- 161:000001110000111900011990b1199000559000005550000055500000a5000000
-- 162:00000000011111009119911b0990099b0000bbb5000b555a00b553550009555a
-- 163:0000000000111100b1199110559009905550000055500000a500000059000000
-- 164:000000000000111b00111bbb009bbbb5000b555a00b553550009555a00009990
-- 165:00000000b1111000559911105550991055500090a5000000590000009a000000
-- 166:0000000000000000011111009119911b0990099b0000bbb5000b555a00b55355
-- 167:000000000000000000111100b1199110559009905550000055500000a5000000
-- 176:0009555a00009990000000000000000a0000000a0000000a0000000000000000
-- 177:590000009a000000aa0000001aa00000aaa00000aaa00000aa00000000000000
-- 178:00009990000000000000000a000000aa000000aa0000000a0000000000000000
-- 179:9a000000aa000000aa0000001a000000aa000000a00000000000000000000000
-- 180:000000000000000a0000000a0000000a00000000000000000000000000000000
-- 181:aa000000a1a00000aaa00000aaa00000aa000000000000000000000000000000
-- 182:0009555a00009990000000000000000000000000000000000000000000000000
-- 183:590000009a0000000aa00000aa1a0000aaaa0000aaaa00000aa0000000000000
-- 192:000000000cccccc0c222222cc211112cc21222c00c22cc0000cc000000c00000
-- 193:00cccc000c8888c0c867768cc877888cc878878cc868768c0c8888c000cccc00
-- 194:0a5500000a5155000a5111550a5115500a5550000a5000000550000055550000
-- 195:666666666cc6cc66c33c33c6c37373c6c37773c66c373c6666c3c666666c6666
-- 196:666666666cc6cc66c22c22c6c22222c6c22222c66c222c6666c2c666666c6666
-- 197:666666666cccccc666c66c6666ceec666ceffec6ceffffecceeeeeec6cccccc6
-- 198:66666666666666666666666666c66c666cacecc6caeeceaccaaeecac6cccccc6
-- 199:666666666cc66cc666ceec6666cedc6666cddc6666cdcc6666cccc66666cc666
-- 200:7377777733377777737777777777777777777777777777377777733377777737
-- 203:00000000000000000000000000000000000000000000000000000000000000cc
-- 204:0ccccccc0c5c55c500c555550c555555c5777775c58888870c888885cc788875
-- 205:00000000c0000000cc000000c5c000005c0000005c00000055c00000cccc0000
-- 208:000000000000000000000000000000cc00000c110000c111006c1114056c1133
-- 209:000000000000000000000000c0c000001c1c0000c111c00044411c0033311c00
-- 210:77333377731cc13773c56c3773c65c3773c56c3773c65c3733c56c3373c33c37
-- 217:0000000000000000000000000000000000000c000000cacc00ccccec0cacceee
-- 218:000000000000000000000000000000000000c000c00cac00cccacac0caccac00
-- 219:000ccc3300c333330c333333c3333333c3333344c2222444c8888444c78887cc
-- 220:3ccccc3cc333c33cccc33cc3444c33334444cccc44444c33444444c3cc444444
-- 221:3333c0003cc33c00cc4333c0cc4433c03444333cccc4433c4cc7444cccc7777c
-- 222:0000000000000000000000000000000c000000c700000ccd0000c777000c7777
-- 223:000000000000000000000000cc00000077c00000d77c00007d77c00077d77c00
-- 224:056c1118056cc111056cc511056cc511c88d5511c87dd511056dd51105655511
-- 225:88811c0088811c005555c000555d5c00dddd5c00dddd5c00dddddc00dddd58c0
-- 226:0aaaaaa0aaa22aaaaa2aa2aaaa2aa2aaaa2222aaaa2aa2aacaaaaaac0cccccc0
-- 227:033333303322233333233233332223333323323333222333c333333c0cccccc0
-- 228:0cccccc0cf222ffcc22ff2fcc22ff2fcc22222fcc22ff2fccddddddccccccccc
-- 229:0cccccc0cf2222fcc222fffccf222ffccff222fcc2222ffccddddddccccccccc
-- 233:00caaeee000caaee00cccaaa000c55cc00c335ae00ca3aaa00cccaaa00caccaa
-- 234:ec0cac00eccccc00cc0cac0053cccc00533ccc00e3acac00accacac0cccccc00
-- 235:0c78887c0c78887c00c7888c000c78870000c78800000c78000000c80000000c
-- 236:cccc4444cccccccccccc3cc3c3cc3333733c33337888c333888c8c3388c833cc
-- 237:ccc7888cccc778873ccc88873c78887c37787cc038887000337c0000337c0000
-- 238:000c7777c0c77777c00c6866000c88880000c88800000c44000cc499000c4949
-- 239:77d77c0067d77c0086c77c0088c7c000cccc7c00c000c0004cc0000049c00000
-- 240:056c5511056c5c1c056cccc4056c0c4c056c04c5066c0c5c0c6c00cc00c0000c
-- 241:cccd58c0444c5c004444c000555c4000ccc5c000cccc0000cccc0000cccc0000
-- 242:0dddddd0dd2dd2dddd2dd2ddddd22ddddd2dd2dddd2dd2ddcddddddc0cccccc0
-- 243:077777707727727777277277777222777777727777722777c777777c0cccccc0
-- 244:0cccccc0c22222fccff22ffccf22fffcc22ffffcc22222fccddddddccccccccc
-- 245:0cccccc0c22ff2fcc22ff2fccf222ffcc22ff2fcc22ff2fccddddddccccccccc
-- 249:000cc3330000c535000c5c3c0000cacc0000cacc0000cacc0000cacc0000cccc
-- 250:5c0ccc003c0cac005c0cac00cc0cac00ac0ccc00ac0ccc00ac0ccc00cc0ccc00
-- 251:00000000000000000000000c0000000c0000000c000000cc000000cc000000cc
-- 252:cd8dddddcdddddddddddddddddddddddddddddddddddcdddcccc0ccccccc0ccc
-- 253:dcc00000dc000000dc000000dc000000dc000000dcc00000ccc00000ccc00000
-- 254:000cc444000c8c44000c8c44000ccc440000cccc0000c5cc000c65cc000ccccc
-- 255:44cc0000cc8c0000cc8c0000cccc0000ccc00000c5c0000065c00000ccc00000
-- </SPRITES>

-- <SPRITES1>
-- 000:00000000000c55550000c7770000c888000cc888000c55550000c5550000c555
-- 001:000000005555c0007575cc0085552350555c1250555c125055dc255055cd5550
-- 002:0000000000000000000c55550000c7770000c888000cc888000c55550000c555
-- 003:00000000000000005555c0007575cc00855c2350555c125055dc125055cd2550
-- 004:0000000000000000000c55550000c7770000c888000cc888000c55550000c555
-- 005:00000000000000005555c0007575cc00855c2350555c125055dc125055cd2550
-- 006:0000000000000000000c55550000c7770000c888000cc888000c55550000c555
-- 007:00000000000000005555cc0075752350855c1250555c125055dc255055cd5550
-- 008:0000000000000000000c55550000c7770000c888000cc888000c55550000c555
-- 009:00000000000000005555c0007575cc00855c2350555c125055dc125055cd2550
-- 010:000000000000000000000000000c55550000c7770000c888000cc888000c5555
-- 011:0000000000000000000000005555c0007575cc00855c2d50555c1250551c1250
-- 012:00000000000000000000000000000000000555570000c7770000c8880000c885
-- 013:00000000000000000000000000000000751d550015552d505555125055551250
-- 014:00000000000000000000000000000000000000000000000000000000000ccccc
-- 015:00000000000000000000000000000000000000000000000000000000c00000c0
-- 016:000cc55d00c8c5de00c88ccc000ccd110000cccc0000cddc0000cc5c00000ccc
-- 017:dccc3550ec8c3350c88ccc00ddcc0000cccc0000cddc0000cc5c0000cccc0000
-- 018:000cc55d00c8c5de00c88ccc000ccd110000cccc0000cddc0000cc5c00000ccc
-- 019:dccc5550ec8c3550c88c3350ddcccc00cccc0000cddc0000cc5c0000cccc0000
-- 020:0000c55d000cc5de00c8cccc00c88d11000ccccc0000cddc0000cc5c00000ccc
-- 021:dccc5550ecec3550cc8c3350d88ccc00cccc0000cddc0000cc5c0000cccc0000
-- 022:000cc55d00c8c5de00c88ccc000ccd110000cccc0000cddc0000cc5c00000ccc
-- 023:dccc3550ec8c3350c88ccc00ddcc0000cccc0000cddc0000cc5c0000cccc0000
-- 024:0000c5550000c555000c8ccc000c8ddd0000cccc00000cd500000ccc00000000
-- 025:5ccc55505c8c3550cc8c3350ddcccc00cccc0000cddc0000ccc5c00000ccc000
-- 026:0000c5550000c5550000c55500000ccc00000cdd00000ccc000000c50000000c
-- 027:55c125505ccc5550558cd550cc8cdd50ddcccc00cccc0000cddc0000cccc0000
-- 028:0000c5550000c555000cc555000c1555000cc1cc0000cccd0000000500000000
-- 029:5515255055c155505cccd5505c1cdd50cc1ccc00dddcc0001cc1c000ccccc000
-- 030:0ccddc550c5cdc5500ccdcc50c5ddce50cccc35e0c88133c0c88c13300555522
-- 031:5ccccc50558887505888875058877750c5875550c5555550c557555055555500
-- 032:00000000000c55550000c7770000c8880cccc8880c8855550c88c55500ccc55d
-- 033:000000005555c0007575cc008555c350555c1250555c125055dc2550ddec5550
-- 034:00000000000c55550000c7770000c8880cccc8880c8855550c88c55500ccc55d
-- 035:000000005555c0007575cc008555c350555c1250555c125055dc2550ddec5550
-- 036:00000000000c55550000c7770000c888000cc888000c555500ccc55500c8c55d
-- 037:000000005555c0007575cc008555c350555c1250555c125055dc2550ddec5550
-- 038:000c55550000c7770000c888000cc888000c55550000c5550000c5550000c55d
-- 039:5555c0007575c0008555c000555ccc00555c235055cc12505dcc1250dec32550
-- 040:000c55550000c7770000c888000cc888000c55550000c5550000c5550000c55d
-- 041:5555c0007575c0008555c000555ccc00555c235055cc12505dcc1250dec32550
-- 042:000c55550000c7770000c888000cc888000c55550000c5550000c5550000c55d
-- 043:5555c0007575c0008555c000555ccc00555c235055cc12505dcc1250dec32550
-- 044:000c55550000c7770000c888000cc888000c55550000c5550000c5550000c55d
-- 045:5555c0007575c0008555c000555ccc00555c235055cc12505dcc1250dec32550
-- 046:00000000000c55550000c7770000c888000cc888000c555500ccc55500c8c55d
-- 047:000000005555c0007575cc008555c350555c1250555c125055dc2550ddec3550
-- 048:0000c55d0000c5de0000cccc0000cd110000cccc0000cd5c00000ccc00000000
-- 049:eeec3550eec88350ccc78c00ddccc000cccc0000cddc0000cc5c00000ccc0000
-- 050:0000c55d0000c5de0000cccc0000cd110000cccc0000cd5c00000ccc00000000
-- 051:eeec3550eec88350ccc78c00ddccc000cccc0000cddc0000cc5c00000ccc0000
-- 052:00c7c55d000cc5de000ccccc0000cd110000cccc0000ccd500000ccc00000000
-- 053:eeec3550eec88350ccc88c00ddccc000ccccc000ccddc0000cc5c00000ccc000
-- 054:00ccc55d00c8c5de000ccccc0000cd110000cccc0000cddc0000cc5c00000cc0
-- 055:eecc5550e88c3550c88d3350ddcccc00ccccc0000cd5c0000cccc00000000000
-- 056:0000c55d000cc5de000c8ccc0000cd110000cccc0000cddc0000c5cc0000ccc0
-- 057:88cc555088cc3550cccd3350ddcccc00ccccc0000cd5c0000cccc00000000000
-- 058:0000c55d000cc5de000c8ccc0000cd110000cccc0000cddc0000c5cc0000ccc0
-- 059:88cc555088cc3550cccd3350ddcccc00ccccc0000cd5c0000cccc00000000000
-- 060:00ccc55d00c8c5de000ccccc0000cd110000cccc0000cddc0000cc5c00000cc0
-- 061:eecc5550e88c3550c88d3350ddcccc00ccccc0000cd5c0000cccc00000000000
-- 062:00c7c55d000cc5de000ccccc0000cd110000cccc0000ccd500000ccc00000000
-- 063:eeec5550eec88350ccc88c00ddccc000ccccc000ccddc0000cc5c00000ccc000
-- 064:00000000000c55550000c7770000c8880cccc8880c8855550c88c55500ccc55d
-- 065:000000005555c0007575cc008555c350555cc2505558855055c78550ddcccd50
-- 066:00000000000000000000000000000000000000000000000000555555000c7777
-- 067:000000000000000000000000000000000000000000000000555c0000575cc000
-- 080:0000c55d0000c5de0000cccc0000cd110000cccc0000cd5c00000ccc00000000
-- 081:eeec3250eecc3350cccc3500ddccc000cccc0000cddc0000cc5c00000ccc0000
-- 082:000c888800cc888500c55555000c5555000cccdd000cccce000c8ccc000c77cc
-- 083:55c2cc0055cc2cc05dcc555c5ccccccccc88ccccec88ccc0ccccdcc0cccccc00
-- 128:000000000000000000cc0ccc0c99c99900cc92aa00c92aaa00c9aaaa0c92aaaa
-- 129:0000000000000000cc00cc0099cc99c0aa99cc00aaaa9c00aaaaa9c0aaaaa99c
-- 130:000000000000000000c000000c9c0ccc00c9c999000c92aa00c92aaa00c9aaaa
-- 131:000000000000000000000c00cc00c9c099cc9c00aa99c000aaaa9c00aaaaa9c0
-- 132:00000000000000000000000000c000cc0c9c0c9900c9c2aa000c2aaa00c9aaaa
-- 133:000000000000000000000000cc0000c099cc0c9caa99c9c0aaaa9c00aaaaa9c0
-- 134:000000000000000000c000000c9c0ccc00c9c999000c92aa00c92aaa00c9aaaa
-- 135:000000000000000000000c00cc00c9c099cc9c00aa99c000aaaac000aaaaac00
-- 144:0c92aaaac999aaaa9c99aaaacc999aaa0c9999990cc9999900ccc999000ccccc
-- 145:aaaaa9c9aaaaa9ccaaaaa9c0aaaa99c0aaa999c099999cc09999cc00ccccc000
-- 146:0c92aaaa0c92aaaac999aaaa9c99aaaacc999aaa0cc9999900ccc999000ccccc
-- 147:aaaaa99caaaaa9c9aaaaa9ccaaaaa9c0aaaa99c0aaa99cc09999cc00ccccc000
-- 148:0c92aaaacc92aaaa9999aaaac999aaaac9999aaacc9999990cccc99900cccccc
-- 149:aaaaa99caaaaa9c9aaaaa9ccaaaaa99caaaa999caaa999cc9999ccc0cccccc00
-- 150:0c92aaaa0c92aaaac999aaaa9c999aaacc9999990cc9999900ccc999000ccccc
-- 151:aaaaa9c0aaaaac90aaaaacc0aaaa9c00aaa99c009999cc009999c000ccccc000
-- 160:1110000091110000099100000009110b0000bbbb0000bbb5000b555a00b55355
-- 161:000001110000111900011990b1199000559000005550000055500000a5000000
-- 162:00000000011111009119911b0990099b0000bbb5000b555a00b553550009555a
-- 163:0000000000111100b1199110559009905550000055500000a500000059000000
-- 164:000000000000111b00111bbb009bbbb5000b555a00b553550009555a00009990
-- 165:00000000b1111000559911105550991055500090a5000000590000009a000000
-- 166:0000000000000000011111009119911b0990099b0000bbb5000b555a00b55355
-- 167:000000000000000000111100b1199110559009905550000055500000a5000000
-- 176:0009555a00009990000000000000000a0000000a0000000a0000000000000000
-- 177:590000009a000000aa0000001aa00000aaa00000aaa00000aa00000000000000
-- 178:00009990000000000000000a000000aa000000aa0000000a0000000000000000
-- 179:9a000000aa000000aa0000001a000000aa000000a00000000000000000000000
-- 180:000000000000000a0000000a0000000a00000000000000000000000000000000
-- 181:aa000000a1a00000aaa00000aaa00000aa000000000000000000000000000000
-- 182:0009555a00009990000000000000000000000000000000000000000000000000
-- 183:590000009a0000000aa00000aa1a0000aaaa0000aaaa00000aa0000000000000
-- 192:000000000cccccc0c222222cc211112cc21222c00c22cc0000cc000000c00000
-- 193:00cccc000c8888c0c867768cc877888cc878878cc868768c0c8888c000cccc00
-- 194:0a5500000a5155000a5111550a5115500a5550000a5000000550000055550000
-- 195:666666666cc6cc66c33c33c6c37373c6c37773c66c373c6666c3c666666c6666
-- 196:666666666cc6cc66c22c22c6c22222c6c22222c66c222c6666c2c666666c6666
-- 197:666666666cccccc666c66c6666ceec666ceffec6ceffffecceeeeeec6cccccc6
-- 198:66666666666666666666666666c66c666cacecc6caeeceaccaaeecac6cccccc6
-- 199:666666666cc66cc666ceec6666cedc6666cddc6666cdcc6666cccc66666cc666
-- 200:7377777733377777737777777777777777777777777777377777733377777737
-- 203:00000000000000000000000000000000000000000000000000000000000000cc
-- 204:0ccccccc0c5c55c500c555550c555555c5777775c58888870c888885cc788875
-- 205:00000000c0000000cc000000c5c000005c0000005c00000055c00000cccc0000
-- 208:000000000000000000000000000000cc00000c110000c111006c1114056c1133
-- 209:000000000000000000000000c0c000001c1c0000c111c00044411c0033311c00
-- 210:77333377731cc13773c56c3773c65c3773c56c3773c65c3733c56c3373c33c37
-- 217:0000000000000000000000000000000000000c000000cacc00ccccec0cacceee
-- 218:000000000000000000000000000000000000c000c00cac00cccacac0caccac00
-- 219:000ccc3300c333330c333333c3333333c3333344c2222444c8888444c78887cc
-- 220:3ccccc3cc333c33cccc33cc3444c33334444cccc44444c33444444c3cc444444
-- 221:3333c0003cc33c00cc4333c0cc4433c03444333cccc4433c4cc7444cccc7777c
-- 222:0000000000000000000000000000000c000000c700000ccd0000c777000c7777
-- 223:000000000000000000000000cc00000077c00000d77c00007d77c00077d77c00
-- 224:056c1118056cc111056cc511056cc511c88d5511c87dd511056dd51105655511
-- 225:88811c0088811c005555c000555d5c00dddd5c00dddd5c00dddddc00dddd58c0
-- 226:0aaaaaa0aaa22aaaaa2aa2aaaa2aa2aaaa2222aaaa2aa2aacaaaaaac0cccccc0
-- 227:033333303322233333233233332223333323323333222333c333333c0cccccc0
-- 228:0cccccc0cf222ffcc22ff2fcc22ff2fcc22222fcc22ff2fccddddddccccccccc
-- 229:0cccccc0cf2222fcc222fffccf222ffccff222fcc2222ffccddddddccccccccc
-- 233:00caaeee000caaee00cccaaa000c55cc00c335ae00ca3aaa00cccaaa00caccaa
-- 234:ec0cac00eccccc00cc0cac0053cccc00533ccc00e3acac00accacac0cccccc00
-- 235:0c78887c0c78887c00c7888c000c78870000c78800000c78000000c80000000c
-- 236:cccc4444cccccccccccc3cc3c3cc3333733c33337888c333888c8c3388c833cc
-- 237:ccc7888cccc778873ccc88873c78887c37787cc038887000337c0000337c0000
-- 238:000c7777c0c77777c00c6866000c88880000c88800000c44000cc499000c4949
-- 239:77d77c0067d77c0086c77c0088c7c000cccc7c00c000c0004cc0000049c00000
-- 240:056c5511056c5c1c056cccc4056c0c4c056c04c5066c0c5c0c6c00cc00c0000c
-- 241:cccd58c0444c5c004444c000555c4000ccc5c000cccc0000cccc0000cccc0000
-- 242:0dddddd0dd2dd2dddd2dd2ddddd22ddddd2dd2dddd2dd2ddcddddddc0cccccc0
-- 243:077777707727727777277277777222777777727777722777c777777c0cccccc0
-- 244:0cccccc0c22222fccff22ffccf22fffcc22ffffcc22222fccddddddccccccccc
-- 245:0cccccc0c22ff2fcc22ff2fccf222ffcc22ff2fcc22ff2fccddddddccccccccc
-- 249:000cc3330000c535000c5c3c0000cacc0000cacc0000cacc0000cacc0000cccc
-- 250:5c0ccc003c0cac005c0cac00cc0cac00ac0ccc00ac0ccc00ac0ccc00cc0ccc00
-- 251:00000000000000000000000c0000000c0000000c000000cc000000cc000000cc
-- 252:cd8dddddcdddddddddddddddddddddddddddddddddddcdddcccc0ccccccc0ccc
-- 253:dcc00000dc000000dc000000dc000000dc000000dcc00000ccc00000ccc00000
-- 254:000cc444000c8c44000c8c44000ccc440000cccc0000c5cc000c65cc000ccccc
-- 255:44cc0000cc8c0000cc8c0000cccc0000ccc00000c5c0000065c00000ccc00000
-- </SPRITES1>

-- <SPRITES2>
-- 000:0000190000000000011111100014410000122100012442101244442112222221
-- 001:0000200001111111012122120012222201222222123333321244444301444442
-- 002:0000200000000000000000000000000000000000000000000000000000000000
-- 003:0000000000000000222210003242110042213210222123102231231022133110
-- 004:0000000000000000000122220000133300001444000114440001222200001222
-- 005:0000000000000000222210003242110042213210222123102231231022133110
-- 006:0000000000000000000122220000133300001444000114440001222200001222
-- 007:0000000000000000222211003242321042212310222123102231311022131110
-- 008:0000000000000000000122220000133300001444000114440001222200001222
-- 009:0000000000000000222210003242110042213210222123102231231022133110
-- 010:0000000000000000000000000001222200001333000014440001144400012222
-- 011:0000000000000000000000002222100032421100422132102221231022312310
-- 012:0000000000000000000000000000000000012223000013330000144400001442
-- 013:0000000000000000000000000000000032421100422132102221231022212310
-- 014:0000000000000000000000000000000000000000000000000000000000011111
-- 015:0000000000000000000000000000000000000000000000000000000010000010
-- 016:0001122300131233001331110001132200001111000012210000113100000111
-- 017:3111211031412210144111003311000011110000122100001131000011110000
-- 018:0001122300131233001331110001132200001111000012210000113100000111
-- 019:3111111031412110144122103311110011110000122100001131000011110000
-- 020:0000122300011233001311110013332200011111000012210000113100000111
-- 021:3111111031112110114122103441110011110000122100001131000011110000
-- 022:0001122300131233001331110001132200001111000012210000113100000111
-- 023:3111211031412210144111003311000011110000122100001131000011110000
-- 024:0000122200001222000141110001422200001111000001230000011100000000
-- 025:2111111021412110114122102211110011110000122100001113100000111000
-- 026:0000122200001222000011220000011100000122000001110000001300000001
-- 027:2213311021111110214121101141221022111100111100001221000011110000
-- 028:0000122200001222000112220001412200011411000011120000000100000000
-- 029:2231311022131110211121102141221011411100222110003113100011111000
-- 030:0112212201312122001121120132214101111214012232210122132200111133
-- 031:2111112022444320244443202443332012432220122222201224222011122200
-- 032:0000000000012222000013330000144401111444013322220133122200111223
-- 033:0000000022221000324211004222121022212310222123102231311033313110
-- 034:0000000000012222000013330000144401111444013322220133122200111223
-- 035:0000000022221000324211004222121022212310222123102231311033313110
-- 036:0000000000012222000013330000144400011444000122220011122200131223
-- 037:0000000022221000324211004222121022212310222123102231311033312110
-- 038:0001222200001333000014440001144400012222000012220000122200001223
-- 039:2222100032421000422210002221110022213210223123102311231033133110
-- 040:0001222200001333000014440001144400012222000012220000122200001223
-- 041:2222100032421000422210002221110022213210223123102311231033133110
-- 042:0001222200001333000014440001144400012222000012220000122200001223
-- 043:2222100032421000422210002221110022213210223123102311231033133110
-- 044:0001222200001333000014440001144400012222000012220000122200001223
-- 045:2222100032421000422210002221110022213210223123102311231033133110
-- 046:0000000000012222000013330000144400011444000122220011122200131223
-- 047:0000000022221000324211004222121022212310222123102231311033312110
-- 048:0000122300001233000011110000132200001111000012310000011100000000
-- 049:3331211032144210112341003311100011110000122100001131000001110000
-- 050:0000122300001233000011110000132200001111000012310000011100000000
-- 051:3331211032144210112341003311100011110000122100001131000001110000
-- 052:0012122300011233000121110000132200001111000011230000011100000000
-- 053:3333111033244210111441003311100011111000112210000113100000111000
-- 054:0011122300131233000121110000132200001111000012210000113100000110
-- 055:3311111034412110144222103311110011111000002310000111100000000000
-- 056:0000122300011233000121110000132200001111000012210000131100001110
-- 057:4411111044212110111222103311110011111000012310000111100000000000
-- 058:0000122300011233000121110000132200001111000012210000131100001110
-- 059:4411111044212110111222103311110011111000012310000111100000000000
-- 060:0011122300131233000121110000132200001111000012210000113100000110
-- 061:3311111034412110144222103311110011111000012310000111100000000000
-- 062:0012122300011233000121110000132200001111000011230000011100000000
-- 063:3333111033244210111441003311100011111000112210000113100000111000
-- 064:0000000000012222000013330000144401111444013322220133122200111223
-- 065:0000000022221000324211004222121022211310222441102213411033111310
-- 066:0000000000000000000000000000000000000000000000000012222200013333
-- 067:0000000000000000000000000000000000000000000000002221000024211000
-- 080:0000122300001233000011110000132200001111000012310000011100000000
-- 081:3331231032112210112121003311100011110000122100001131000001110000
-- 082:0001444400114442001222220001222200011133000111130001311100013311
-- 083:2212110022112110231122212111111111441111314411101111311011111100
-- 100:0000200002000000222000000200000000000000000000000000002000000222
-- 110:0000190002110000021311000213331102133110021110000210000001100000
-- 111:0000190000000000011001100013310000132100001221000012110000111100
-- 128:0000000000000000001101110133133300113422001342220013222201342222
-- 129:0000000000000000110011003311331022331100222231002222231022222331
-- 130:0000000000000000001000000131011100131333000134220013422200132222
-- 131:0000000000000000000001001100131033113100223310002222310022222310
-- 132:0000000000000000000000000010001101310133001314220001422200132222
-- 133:0000000000000000000000001100001033110131223313102222310022222310
-- 134:0000000000000000001000000131011100131333000134220013422200132222
-- 135:0000000000000000000001001100131033113100223310002222100022222100
-- 144:0134222213332222313322221133322201333333011333330011133300011111
-- 145:2222231322222311222223102222331022233310333331103333110011111000
-- 146:0134222201342222133322223133222211333222011333330011133300111111
-- 147:2222233122222313222223112222231022223310222331103333110011111100
-- 148:0134222211342222333322221333222213333222113333330111133301111111
-- 149:2222233122222313222223112222233122223331222333113333111011111110
-- 150:0134222201342222133322223133322211333333011333330011133300011111
-- 151:2222231022222130222221102222310022233100333311003333100011111000
-- 160:3330000023330000022300000002330200002222000022210002111200211311
-- 161:0000033300003332000332202332200011200000111000001110000021000000
-- 162:0000000003333300233223320220022200002221000211120021131100021112
-- 163:0000000000333300233223301120022011100000111000002100000012000000
-- 164:0000000000003332003332220022222100021112002113110002111200002220
-- 165:0000000023333000112233301110223011100020210000001200000022000000
-- 166:0000000000000000033333002332233202200222000022210002111200211311
-- 167:0000000000000000003333002332233011200220111000001110000021000000
-- </SPRITES2>

-- <SPRITES3>
-- 000:0000190000000000011111100014410000122100012442101244442112222221
-- 001:0000200001111111012122120012222201222222123333321244444301444442
-- 002:0000200000000000000000000000000000000000000000000000000000000000
-- 003:0000000000000000222210003242110042213210222123102231231022133110
-- 004:0000000000000000000122220000133300001444000114440001222200001222
-- 005:0000000000000000222210003242110042213210222123102231231022133110
-- 006:0000000000000000000122220000133300001444000114440001222200001222
-- 007:0000000000000000222211003242321042212310222123102231311022131110
-- 008:0000000000000000000122220000133300001444000114440001222200001222
-- 009:0000000000000000222210003242110042213210222123102231231022133110
-- 010:0000000000000000000000000001222200001333000014440001144400012222
-- 011:0000000000000000000000002222100032421100422132102221231022312310
-- 012:0000000000000000000000000000000000012223000013330000144400001442
-- 013:0000000000000000000000000000000032421100422132102221231022212310
-- 014:0000000000000000000000000000000000000000000000000000000000011111
-- 015:0000000000000000000000000000000000000000000000000000000010000010
-- 016:0001122300131233001331110001132200001111000012210000113100000111
-- 017:3111211031412210144111003311000011110000122100001131000011110000
-- 018:0001122300131233001331110001132200001111000012210000113100000111
-- 019:3111111031412110144122103311110011110000122100001131000011110000
-- 020:0000122300011233001311110013332200011111000012210000113100000111
-- 021:3111111031112110114122103441110011110000122100001131000011110000
-- 022:0001122300131233001331110001132200001111000012210000113100000111
-- 023:3111211031412210144111003311000011110000122100001131000011110000
-- 024:0000122200001222000141110001422200001111000001230000011100000000
-- 025:2111111021412110114122102211110011110000122100001113100000111000
-- 026:0000122200001222000011220000011100000122000001110000001300000001
-- 027:2213311021111110214121101141221022111100111100001221000011110000
-- 028:0000122200001222000112220001412200011411000011120000000100000000
-- 029:2231311022131110211121102141221011411100222110003113100011111000
-- 030:0112212201312122001121120132214101111214012232210122132200111133
-- 031:2111112022444320244443202443332012432220122222201224222011122200
-- 032:0000000000012222000013330000144401111444013322220133122200111223
-- 033:0000000022221000324211004222121022212310222123102231311033313110
-- 034:0000000000012222000013330000144401111444013322220133122200111223
-- 035:0000000022221000324211004222121022212310222123102231311033313110
-- 036:0000000000012222000013330000144400011444000122220011122200131223
-- 037:0000000022221000324211004222121022212310222123102231311033312110
-- 038:0001222200001333000014440001144400012222000012220000122200001223
-- 039:2222100032421000422210002221110022213210223123102311231033133110
-- 040:0001222200001333000014440001144400012222000012220000122200001223
-- 041:2222100032421000422210002221110022213210223123102311231033133110
-- 042:0001222200001333000014440001144400012222000012220000122200001223
-- 043:2222100032421000422210002221110022213210223123102311231033133110
-- 044:0001222200001333000014440001144400012222000012220000122200001223
-- 045:2222100032421000422210002221110022213210223123102311231033133110
-- 046:0000000000012222000013330000144400011444000122220011122200131223
-- 047:0000000022221000324211004222121022212310222123102231311033312110
-- 048:0000122300001233000011110000132200001111000012310000011100000000
-- 049:3331211032144210112341003311100011110000122100001131000001110000
-- 050:0000122300001233000011110000132200001111000012310000011100000000
-- 051:3331211032144210112341003311100011110000122100001131000001110000
-- 052:0012122300011233000121110000132200001111000011230000011100000000
-- 053:3333111033244210111441003311100011111000112210000113100000111000
-- 054:0011122300131233000121110000132200001111000012210000113100000110
-- 055:3311111034412110144222103311110011111000002310000111100000000000
-- 056:0000122300011233000121110000132200001111000012210000131100001110
-- 057:4411111044212110111222103311110011111000012310000111100000000000
-- 058:0000122300011233000121110000132200001111000012210000131100001110
-- 059:4411111044212110111222103311110011111000012310000111100000000000
-- 060:0011122300131233000121110000132200001111000012210000113100000110
-- 061:3311111034412110144222103311110011111000012310000111100000000000
-- 062:0012122300011233000121110000132200001111000011230000011100000000
-- 063:3333111033244210111441003311100011111000112210000113100000111000
-- 064:0000000000012222000013330000144401111444013322220133122200111223
-- 065:0000000022221000324211004222121022211310222441102213411033111310
-- 066:0000000000000000000000000000000000000000000000000012222200013333
-- 067:0000000000000000000000000000000000000000000000002221000024211000
-- 080:0000122300001233000011110000132200001111000012310000011100000000
-- 081:3331231032112210112121003311100011110000122100001131000001110000
-- 082:0001444400114442001222220001222200011133000111130001311100013311
-- 083:2212110022112110231122212111111111441111314411101111311011111100
-- 100:0000200002000000222000000200000000000000000000000000002000000222
-- 110:0000190002110000021311000213331102133110021110000210000001100000
-- 111:0000190000000000011001100013310000132100001221000012110000111100
-- 128:0000000000000000001101110133133300113422001342220013222201342222
-- 129:0000000000000000110011003311331022331100222231002222231022222331
-- 130:0000000000000000001000000131011100131333000134220013422200132222
-- 131:0000000000000000000001001100131033113100223310002222310022222310
-- 132:0000000000000000000000000010001101310133001314220001422200132222
-- 133:0000000000000000000000001100001033110131223313102222310022222310
-- 134:0000000000000000001000000131011100131333000134220013422200132222
-- 135:0000000000000000000001001100131033113100223310002222100022222100
-- 144:0134222213332222313322221133322201333333011333330011133300011111
-- 145:2222231322222311222223102222331022233310333331103333110011111000
-- 146:0134222201342222133322223133222211333222011333330011133300111111
-- 147:2222233122222313222223112222231022223310222331103333110011111100
-- 148:0134222211342222333322221333222213333222113333330111133301111111
-- 149:2222233122222313222223112222233122223331222333113333111011111110
-- 150:0134222201342222133322223133322211333333011333330011133300011111
-- 151:2222231022222130222221102222310022233100333311003333100011111000
-- 160:3330000023330000022300000002330200002222000022210002111200211311
-- 161:0000033300003332000332202332200011200000111000001110000021000000
-- 162:0000000003333300233223320220022200002221000211120021131100021112
-- 163:0000000000333300233223301120022011100000111000002100000012000000
-- 164:0000000000003332003332220022222100021112002113110002111200002220
-- 165:0000000023333000112233301110223011100020210000001200000022000000
-- 166:0000000000000000033333002332233202200222000022210002111200211311
-- 167:0000000000000000003333002332233011200220111000001110000021000000
-- </SPRITES3>

-- <SPRITES4>
-- 000:0000190000000000011111100014410000122100012442101244442112222221
-- 001:0000200001111111012122120012222201222222123333321244444301444442
-- 002:0000200000000000000000000000000000000000000000000000000000000000
-- 003:0000000000000000222210003242110042213210222123102231231022133110
-- 004:0000000000000000000122220000133300001444000114440001222200001222
-- 005:0000000000000000222210003242110042213210222123102231231022133110
-- 006:0000000000000000000122220000133300001444000114440001222200001222
-- 007:0000000000000000222211003242321042212310222123102231311022131110
-- 008:0000000000000000000122220000133300001444000114440001222200001222
-- 009:0000000000000000222210003242110042213210222123102231231022133110
-- 010:0000000000000000000000000001222200001333000014440001144400012222
-- 011:0000000000000000000000002222100032421100422132102221231022312310
-- 012:0000000000000000000000000000000000012223000013330000144400001442
-- 013:0000000000000000000000000000000032421100422132102221231022212310
-- 014:0000000000000000000000000000000000000000000000000000000000011111
-- 015:0000000000000000000000000000000000000000000000000000000010000010
-- 016:0001122300131233001331110001132200001111000012210000113100000111
-- 017:3111211031412210144111003311000011110000122100001131000011110000
-- 018:0001122300131233001331110001132200001111000012210000113100000111
-- 019:3111111031412110144122103311110011110000122100001131000011110000
-- 020:0000122300011233001311110013332200011111000012210000113100000111
-- 021:3111111031112110114122103441110011110000122100001131000011110000
-- 022:0001122300131233001331110001132200001111000012210000113100000111
-- 023:3111211031412210144111003311000011110000122100001131000011110000
-- 024:0000122200001222000141110001422200001111000001230000011100000000
-- 025:2111111021412110114122102211110011110000122100001113100000111000
-- 026:0000122200001222000011220000011100000122000001110000001300000001
-- 027:2213311021111110214121101141221022111100111100001221000011110000
-- 028:0000122200001222000112220001412200011411000011120000000100000000
-- 029:2231311022131110211121102141221011411100222110003113100011111000
-- 030:0112212201312122001121120132214101111214012232210122132200111133
-- 031:2111112022444320244443202443332012432220122222201224222011122200
-- 032:0000000000012222000013330000144401111444013322220133122200111223
-- 033:0000000022221000324211004222121022212310222123102231311033313110
-- 034:0000000000012222000013330000144401111444013322220133122200111223
-- 035:0000000022221000324211004222121022212310222123102231311033313110
-- 036:0000000000012222000013330000144400011444000122220011122200131223
-- 037:0000000022221000324211004222121022212310222123102231311033312110
-- 038:0001222200001333000014440001144400012222000012220000122200001223
-- 039:2222100032421000422210002221110022213210223123102311231033133110
-- 040:0001222200001333000014440001144400012222000012220000122200001223
-- 041:2222100032421000422210002221110022213210223123102311231033133110
-- 042:0001222200001333000014440001144400012222000012220000122200001223
-- 043:2222100032421000422210002221110022213210223123102311231033133110
-- 044:0001222200001333000014440001144400012222000012220000122200001223
-- 045:2222100032421000422210002221110022213210223123102311231033133110
-- 046:0000000000012222000013330000144400011444000122220011122200131223
-- 047:0000000022221000324211004222121022212310222123102231311033312110
-- 048:0000122300001233000011110000132200001111000012310000011100000000
-- 049:3331211032144210112341003311100011110000122100001131000001110000
-- 050:0000122300001233000011110000132200001111000012310000011100000000
-- 051:3331211032144210112341003311100011110000122100001131000001110000
-- 052:0012122300011233000121110000132200001111000011230000011100000000
-- 053:3333111033244210111441003311100011111000112210000113100000111000
-- 054:0011122300131233000121110000132200001111000012210000113100000110
-- 055:3311111034412110144222103311110011111000002310000111100000000000
-- 056:0000122300011233000121110000132200001111000012210000131100001110
-- 057:4411111044212110111222103311110011111000012310000111100000000000
-- 058:0000122300011233000121110000132200001111000012210000131100001110
-- 059:4411111044212110111222103311110011111000012310000111100000000000
-- 060:0011122300131233000121110000132200001111000012210000113100000110
-- 061:3311111034412110144222103311110011111000012310000111100000000000
-- 062:0012122300011233000121110000132200001111000011230000011100000000
-- 063:3333111033244210111441003311100011111000112210000113100000111000
-- 064:0000000000012222000013330000144401111444013322220133122200111223
-- 065:0000000022221000324211004222121022211310222441102213411033111310
-- 066:0000000000000000000000000000000000000000000000000012222200013333
-- 067:0000000000000000000000000000000000000000000000002221000024211000
-- 080:0000122300001233000011110000132200001111000012310000011100000000
-- 081:3331231032112210112121003311100011110000122100001131000001110000
-- 082:0001444400114442001222220001222200011133000111130001311100013311
-- 083:2212110022112110231122212111111111441111314411101111311011111100
-- 100:0000200002000000222000000200000000000000000000000000002000000222
-- 110:0000190002110000021311000213331102133110021110000210000001100000
-- 111:0000190000000000011001100013310000132100001221000012110000111100
-- 128:0000000000000000001101110133133300113422001342220013222201342222
-- 129:0000000000000000110011003311331022331100222231002222231022222331
-- 130:0000000000000000001000000131011100131333000134220013422200132222
-- 131:0000000000000000000001001100131033113100223310002222310022222310
-- 132:0000000000000000000000000010001101310133001314220001422200132222
-- 133:0000000000000000000000001100001033110131223313102222310022222310
-- 134:0000000000000000001000000131011100131333000134220013422200132222
-- 135:0000000000000000000001001100131033113100223310002222100022222100
-- 144:0134222213332222313322221133322201333333011333330011133300011111
-- 145:2222231322222311222223102222331022233310333331103333110011111000
-- 146:0134222201342222133322223133222211333222011333330011133300111111
-- 147:2222233122222313222223112222231022223310222331103333110011111100
-- 148:0134222211342222333322221333222213333222113333330111133301111111
-- 149:2222233122222313222223112222233122223331222333113333111011111110
-- 150:0134222201342222133322223133322211333333011333330011133300011111
-- 151:2222231022222130222221102222310022233100333311003333100011111000
-- 160:3330000023330000022300000002330200002222000022210002111200211311
-- 161:0000033300003332000332202332200011200000111000001110000021000000
-- 162:0000000003333300233223320220022200002221000211120021131100021112
-- 163:0000000000333300233223301120022011100000111000002100000012000000
-- 164:0000000000003332003332220022222100021112002113110002111200002220
-- 165:0000000023333000112233301110223011100020210000001200000022000000
-- 166:0000000000000000033333002332233202200222000022210002111200211311
-- 167:0000000000000000003333002332233011200220111000001110000021000000
-- </SPRITES4>

-- <SPRITES5>
-- 000:0000190000000000011111100014410000122100012442101244442112222221
-- 001:0000200001111111012122120012222201222222123333321244444301444442
-- 002:0000200000000000000000000000000000000000000000000000000000000000
-- 003:0000000000000000222210003242110042213210222123102231231022133110
-- 004:0000000000000000000122220000133300001444000114440001222200001222
-- 005:0000000000000000222210003242110042213210222123102231231022133110
-- 006:0000000000000000000122220000133300001444000114440001222200001222
-- 007:0000000000000000222211003242321042212310222123102231311022131110
-- 008:0000000000000000000122220000133300001444000114440001222200001222
-- 009:0000000000000000222210003242110042213210222123102231231022133110
-- 010:0000000000000000000000000001222200001333000014440001144400012222
-- 011:0000000000000000000000002222100032421100422132102221231022312310
-- 012:0000000000000000000000000000000000012223000013330000144400001442
-- 013:0000000000000000000000000000000032421100422132102221231022212310
-- 014:0000000000000000000000000000000000000000000000000000000000011111
-- 015:0000000000000000000000000000000000000000000000000000000010000010
-- 016:0001122300131233001331110001132200001111000012210000113100000111
-- 017:3111211031412210144111003311000011110000122100001131000011110000
-- 018:0001122300131233001331110001132200001111000012210000113100000111
-- 019:3111111031412110144122103311110011110000122100001131000011110000
-- 020:0000122300011233001311110013332200011111000012210000113100000111
-- 021:3111111031112110114122103441110011110000122100001131000011110000
-- 022:0001122300131233001331110001132200001111000012210000113100000111
-- 023:3111211031412210144111003311000011110000122100001131000011110000
-- 024:0000122200001222000141110001422200001111000001230000011100000000
-- 025:2111111021412110114122102211110011110000122100001113100000111000
-- 026:0000122200001222000011220000011100000122000001110000001300000001
-- 027:2213311021111110214121101141221022111100111100001221000011110000
-- 028:0000122200001222000112220001412200011411000011120000000100000000
-- 029:2231311022131110211121102141221011411100222110003113100011111000
-- 030:0112212201312122001121120132214101111214012232210122132200111133
-- 031:2111112022444320244443202443332012432220122222201224222011122200
-- 032:0000000000012222000013330000144401111444013322220133122200111223
-- 033:0000000022221000324211004222121022212310222123102231311033313110
-- 034:0000000000012222000013330000144401111444013322220133122200111223
-- 035:0000000022221000324211004222121022212310222123102231311033313110
-- 036:0000000000012222000013330000144400011444000122220011122200131223
-- 037:0000000022221000324211004222121022212310222123102231311033312110
-- 038:0001222200001333000014440001144400012222000012220000122200001223
-- 039:2222100032421000422210002221110022213210223123102311231033133110
-- 040:0001222200001333000014440001144400012222000012220000122200001223
-- 041:2222100032421000422210002221110022213210223123102311231033133110
-- 042:0001222200001333000014440001144400012222000012220000122200001223
-- 043:2222100032421000422210002221110022213210223123102311231033133110
-- 044:0001222200001333000014440001144400012222000012220000122200001223
-- 045:2222100032421000422210002221110022213210223123102311231033133110
-- 046:0000000000012222000013330000144400011444000122220011122200131223
-- 047:0000000022221000324211004222121022212310222123102231311033312110
-- 048:0000122300001233000011110000132200001111000012310000011100000000
-- 049:3331211032144210112341003311100011110000122100001131000001110000
-- 050:0000122300001233000011110000132200001111000012310000011100000000
-- 051:3331211032144210112341003311100011110000122100001131000001110000
-- 052:0012122300011233000121110000132200001111000011230000011100000000
-- 053:3333111033244210111441003311100011111000112210000113100000111000
-- 054:0011122300131233000121110000132200001111000012210000113100000110
-- 055:3311111034412110144222103311110011111000002310000111100000000000
-- 056:0000122300011233000121110000132200001111000012210000131100001110
-- 057:4411111044212110111222103311110011111000012310000111100000000000
-- 058:0000122300011233000121110000132200001111000012210000131100001110
-- 059:4411111044212110111222103311110011111000012310000111100000000000
-- 060:0011122300131233000121110000132200001111000012210000113100000110
-- 061:3311111034412110144222103311110011111000012310000111100000000000
-- 062:0012122300011233000121110000132200001111000011230000011100000000
-- 063:3333111033244210111441003311100011111000112210000113100000111000
-- 064:0000000000012222000013330000144401111444013322220133122200111223
-- 065:0000000022221000324211004222121022211310222441102213411033111310
-- 066:0000000000000000000000000000000000000000000000000012222200013333
-- 067:0000000000000000000000000000000000000000000000002221000024211000
-- 080:0000122300001233000011110000132200001111000012310000011100000000
-- 081:3331231032112210112121003311100011110000122100001131000001110000
-- 082:0001444400114442001222220001222200011133000111130001311100013311
-- 083:2212110022112110231122212111111111441111314411101111311011111100
-- 100:0000200002000000222000000200000000000000000000000000002000000222
-- 110:0000190002110000021311000213331102133110021110000210000001100000
-- 111:0000190000000000011001100013310000132100001221000012110000111100
-- 128:0000000000000000001101110133133300113422001342220013222201342222
-- 129:0000000000000000110011003311331022331100222231002222231022222331
-- 130:0000000000000000001000000131011100131333000134220013422200132222
-- 131:0000000000000000000001001100131033113100223310002222310022222310
-- 132:0000000000000000000000000010001101310133001314220001422200132222
-- 133:0000000000000000000000001100001033110131223313102222310022222310
-- 134:0000000000000000001000000131011100131333000134220013422200132222
-- 135:0000000000000000000001001100131033113100223310002222100022222100
-- 144:0134222213332222313322221133322201333333011333330011133300011111
-- 145:2222231322222311222223102222331022233310333331103333110011111000
-- 146:0134222201342222133322223133222211333222011333330011133300111111
-- 147:2222233122222313222223112222231022223310222331103333110011111100
-- 148:0134222211342222333322221333222213333222113333330111133301111111
-- 149:2222233122222313222223112222233122223331222333113333111011111110
-- 150:0134222201342222133322223133322211333333011333330011133300011111
-- 151:2222231022222130222221102222310022233100333311003333100011111000
-- 160:3330000023330000022300000002330200002222000022210002111200211311
-- 161:0000033300003332000332202332200011200000111000001110000021000000
-- 162:0000000003333300233223320220022200002221000211120021131100021112
-- 163:0000000000333300233223301120022011100000111000002100000012000000
-- 164:0000000000003332003332220022222100021112002113110002111200002220
-- 165:0000000023333000112233301110223011100020210000001200000022000000
-- 166:0000000000000000033333002332233202200222000022210002111200211311
-- 167:0000000000000000003333002332233011200220111000001110000021000000
-- </SPRITES5>

-- <SPRITES6>
-- 000:0000190000000000011111100014410000122100012442101244442112222221
-- 001:0000200001111111012122120012222201222222123333321244444301444442
-- 002:0000200000000000000000000000000000000000000000000000000000000000
-- 003:0000000000000000222210003242110042213210222123102231231022133110
-- 004:0000000000000000000122220000133300001444000114440001222200001222
-- 005:0000000000000000222210003242110042213210222123102231231022133110
-- 006:0000000000000000000122220000133300001444000114440001222200001222
-- 007:0000000000000000222211003242321042212310222123102231311022131110
-- 008:0000000000000000000122220000133300001444000114440001222200001222
-- 009:0000000000000000222210003242110042213210222123102231231022133110
-- 010:0000000000000000000000000001222200001333000014440001144400012222
-- 011:0000000000000000000000002222100032421100422132102221231022312310
-- 012:0000000000000000000000000000000000012223000013330000144400001442
-- 013:0000000000000000000000000000000032421100422132102221231022212310
-- 014:0000000000000000000000000000000000000000000000000000000000011111
-- 015:0000000000000000000000000000000000000000000000000000000010000010
-- 016:0001122300131233001331110001132200001111000012210000113100000111
-- 017:3111211031412210144111003311000011110000122100001131000011110000
-- 018:0001122300131233001331110001132200001111000012210000113100000111
-- 019:3111111031412110144122103311110011110000122100001131000011110000
-- 020:0000122300011233001311110013332200011111000012210000113100000111
-- 021:3111111031112110114122103441110011110000122100001131000011110000
-- 022:0001122300131233001331110001132200001111000012210000113100000111
-- 023:3111211031412210144111003311000011110000122100001131000011110000
-- 024:0000122200001222000141110001422200001111000001230000011100000000
-- 025:2111111021412110114122102211110011110000122100001113100000111000
-- 026:0000122200001222000011220000011100000122000001110000001300000001
-- 027:2213311021111110214121101141221022111100111100001221000011110000
-- 028:0000122200001222000112220001412200011411000011120000000100000000
-- 029:2231311022131110211121102141221011411100222110003113100011111000
-- 030:0112212201312122001121120132214101111214012232210122132200111133
-- 031:2111112022444320244443202443332012432220122222201224222011122200
-- 032:0000000000012222000013330000144401111444013322220133122200111223
-- 033:0000000022221000324211004222121022212310222123102231311033313110
-- 034:0000000000012222000013330000144401111444013322220133122200111223
-- 035:0000000022221000324211004222121022212310222123102231311033313110
-- 036:0000000000012222000013330000144400011444000122220011122200131223
-- 037:0000000022221000324211004222121022212310222123102231311033312110
-- 038:0001222200001333000014440001144400012222000012220000122200001223
-- 039:2222100032421000422210002221110022213210223123102311231033133110
-- 040:0001222200001333000014440001144400012222000012220000122200001223
-- 041:2222100032421000422210002221110022213210223123102311231033133110
-- 042:0001222200001333000014440001144400012222000012220000122200001223
-- 043:2222100032421000422210002221110022213210223123102311231033133110
-- 044:0001222200001333000014440001144400012222000012220000122200001223
-- 045:2222100032421000422210002221110022213210223123102311231033133110
-- 046:0000000000012222000013330000144400011444000122220011122200131223
-- 047:0000000022221000324211004222121022212310222123102231311033312110
-- 048:0000122300001233000011110000132200001111000012310000011100000000
-- 049:3331211032144210112341003311100011110000122100001131000001110000
-- 050:0000122300001233000011110000132200001111000012310000011100000000
-- 051:3331211032144210112341003311100011110000122100001131000001110000
-- 052:0012122300011233000121110000132200001111000011230000011100000000
-- 053:3333111033244210111441003311100011111000112210000113100000111000
-- 054:0011122300131233000121110000132200001111000012210000113100000110
-- 055:3311111034412110144222103311110011111000002310000111100000000000
-- 056:0000122300011233000121110000132200001111000012210000131100001110
-- 057:4411111044212110111222103311110011111000012310000111100000000000
-- 058:0000122300011233000121110000132200001111000012210000131100001110
-- 059:4411111044212110111222103311110011111000012310000111100000000000
-- 060:0011122300131233000121110000132200001111000012210000113100000110
-- 061:3311111034412110144222103311110011111000012310000111100000000000
-- 062:0012122300011233000121110000132200001111000011230000011100000000
-- 063:3333111033244210111441003311100011111000112210000113100000111000
-- 064:0000000000012222000013330000144401111444013322220133122200111223
-- 065:0000000022221000324211004222121022211310222441102213411033111310
-- 066:0000000000000000000000000000000000000000000000000012222200013333
-- 067:0000000000000000000000000000000000000000000000002221000024211000
-- 080:0000122300001233000011110000132200001111000012310000011100000000
-- 081:3331231032112210112121003311100011110000122100001131000001110000
-- 082:0001444400114442001222220001222200011133000111130001311100013311
-- 083:2212110022112110231122212111111111441111314411101111311011111100
-- 100:0000200002000000222000000200000000000000000000000000002000000222
-- 110:0000190002110000021311000213331102133110021110000210000001100000
-- 111:0000190000000000011001100013310000132100001221000012110000111100
-- 128:0000000000000000001101110133133300113422001342220013222201342222
-- 129:0000000000000000110011003311331022331100222231002222231022222331
-- 130:0000000000000000001000000131011100131333000134220013422200132222
-- 131:0000000000000000000001001100131033113100223310002222310022222310
-- 132:0000000000000000000000000010001101310133001314220001422200132222
-- 133:0000000000000000000000001100001033110131223313102222310022222310
-- 134:0000000000000000001000000131011100131333000134220013422200132222
-- 135:0000000000000000000001001100131033113100223310002222100022222100
-- 144:0134222213332222313322221133322201333333011333330011133300011111
-- 145:2222231322222311222223102222331022233310333331103333110011111000
-- 146:0134222201342222133322223133222211333222011333330011133300111111
-- 147:2222233122222313222223112222231022223310222331103333110011111100
-- 148:0134222211342222333322221333222213333222113333330111133301111111
-- 149:2222233122222313222223112222233122223331222333113333111011111110
-- 150:0134222201342222133322223133322211333333011333330011133300011111
-- 151:2222231022222130222221102222310022233100333311003333100011111000
-- 160:3330000023330000022300000002330200002222000022210002111200211311
-- 161:0000033300003332000332202332200011200000111000001110000021000000
-- 162:0000000003333300233223320220022200002221000211120021131100021112
-- 163:0000000000333300233223301120022011100000111000002100000012000000
-- 164:0000000000003332003332220022222100021112002113110002111200002220
-- 165:0000000023333000112233301110223011100020210000001200000022000000
-- 166:0000000000000000033333002332233202200222000022210002111200211311
-- 167:0000000000000000003333002332233011200220111000001110000021000000
-- </SPRITES6>

-- <SPRITES7>
-- 000:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 001:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 002:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbb00
-- 003:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000
-- 004:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00bbbbbb000bbbbb
-- 005:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 006:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 007:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 008:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 009:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 010:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 011:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 012:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 013:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 014:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 015:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 016:bbbbbbbbbbb0000bb00000000005650000565650006666660056666000066600
-- 017:bbbbbbbbbbbbbbbbbbbbbbbb0bbbbbbb0bbbbbbb0bbbbb000bbb00000bb00000
-- 018:bbbbb000bbbbb000bbbb0000bbbb0005b0000006000000650000005665656565
-- 019:0056555065656565565656566565656556565656656565655656565665656665
-- 020:000bbbbb00000000500000006600000056565656656665665656565666666666
-- 021:bbbbbbbb000000bb000000000000000056565000666666605656565666666666
-- 022:bbbbbbbbbbbbbbbbbbbbbbbb0bbbbbbb00bbbbbb000bbbbb000bbbbb6000bbbb
-- 023:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000bb0000000b
-- 024:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 025:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 026:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 027:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 028:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 029:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 030:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 031:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 032:b0000000bb00000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 033:bb000056bb000565b0000655b0006565b00055560005656500065656b0006565
-- 034:5556555665656565565656566565656556565656656565655656565665656665
-- 035:5656565665656566565656566665666656565656656665665656565066000000
-- 036:5656565665666666565656566666666656565656000666660006565600066666
-- 037:5656566666666666565666566666666656665666666666666656666666666666
-- 038:5000bbb06000bb006000bb0060000b0056000000666000b0666000b0666000bb
-- 039:0000000000555000055555000565650000666000000000000000000bb00000bb
-- 040:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 041:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 042:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 043:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 044:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 045:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 046:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 047:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 048:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 049:b0005556b0006565b0000656bb000065bbb00000bbbb0000bbbbb000bbbbbbb0
-- 050:56565656656565665656565666656660565650000000000000000000000000bb
-- 051:500000006000000b0000bbbb000bbbbb00bbbbbb0bbbbbbbbbbbbbbbbbbbbbbb
-- 052:00005666b0006666b0000056bb000000bbb00000bbbbb000bbbbbbbbbbbbbbbb
-- 053:566656666666666660006666000006660000006600000000bbb00000bbbbb000
-- 054:666600bb666000bb666000bb666000bb60000b00000000000000000000000006
-- 055:bbbbbbbbbbbbbbbbbbbbbbbbb000000b00000000000000000060000066000000
-- 056:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbbb00bbbbbb00bbbbbb00bbbbbb
-- 057:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 058:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 059:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 060:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 061:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 062:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 063:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 064:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 065:bbbbbbbbbbbbb000bbbb0000bbb00065bbb00556bbb00565bbb00656bbb00066
-- 066:bbbbbbbb00bbbbbb000bbbbb6000bbbb5500bbbb6500bbbb6600bbbb6000bbbb
-- 067:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 068:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbb00bbbbb000bbbb0000bbb00000
-- 069:bbbbb000bbb00000b00000060000006600006666006660006600000000000000
-- 070:0000666606666600666600006600000000000005000005650005555505656565
-- 071:0000005500000565000555550555656555555555556555655555555565656565
-- 072:000bbbbb000bbbbb000bbbbb000bbbbb000bbbbb000bbbbb000bbbbb6000bbbb
-- 073:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 074:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 075:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 076:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 077:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 078:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 079:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 080:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 081:bbbb0000bbbbb000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 082:000bbbbb00bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 083:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 084:bbb00000bbb00000bbb00055bbb00005bbbb0000bbbb0000bbbbb000bbbbbb00
-- 085:0000005500055565555555556565656555555555056565650055555500656565
-- 086:5555555555656565555555556565656555555555656565655655555565656565
-- 087:5555555555656565555555556565656555555555656565655655565565656565
-- 088:5000bbbb60000bbb550000bb6560000b55550000656560005655560065656565
-- 089:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbbb00bbbbbb0000bbbb000000bb
-- 090:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 091:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 092:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 093:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 094:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 095:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 096:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 097:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 098:bbbbbbbbbbbbbbbbbbbbbb00bbb00000bb000000b0000044b000444400004444
-- 099:bbbbbbbbbbbbbbbb00bbbbbb0000bbbb00000bbb400000bb4440000b4444000b
-- 100:bbbbbbb0bbbbbbbbbbbbbbbbbbbb0000bbb00000bb000000bb000444b0003444
-- 101:0005555500006565b0005655bb00056000000500000000000000000000000004
-- 102:5555555565656565565556550000006500000000000000004444400034443440
-- 103:5555555565656565565556556565650055565000056500000056000400600044
-- 104:5555555665656565565556550065650000005000000000004000000434000004
-- 105:5000000065600000565550000005656000005500000000004400000034000044
-- 106:bbbbbbbb0bbbbbbb000000bb0000000b00000000000440000444000034400000
-- 107:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000bbb00000000000000000044
-- 108:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000bbb000000bb004000000044000000
-- 109:bbbbbbbbbbbbbbbbbbbbbbbb00000bbb000000b0000000000444000044440000
-- 110:bbbbbbbbbbbbbbbbb00000bb0000000b0000000b004440000044400000443000
-- 111:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000bbbb000000b0000000000040000
-- 112:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 113:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0
-- 114:0004440000044400004444000034340000444400003434000043430000343400
-- 115:0444000b04344000044440000034300000444400003434000043434000043430
-- 116:b0004444b0004434b00044440000343400004443000434300003434000043330
-- 117:0000004400000034000000440000003400000044000000340000004300000034
-- 118:4444444040004430400000003000000044000000340005654300065033000500
-- 119:0050004400600034005000440060003406500044006000340000004300000034
-- 120:4400000444000004440000043400000444000044343004344343434334343434
-- 121:4400004444000034440000443400003444000003340000044340000333000004
-- 122:4400000644000000440000003400000044400043343434304343430033340000
-- 123:5000004405000434000004440000043400000444000004340000034300000434
-- 124:4440000444300004444000043434000444434444343434344343434330043434
-- 125:4444400044344000444440003434300044434000343430004343400000343000
-- 126:0044400000343000004440000034300000434443003434340043434300343334
-- 127:004440000434400044444000343400004440000b343000bb430000bb00000bbb
-- 128:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 129:bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 130:0043430000343430004343430033333300034343000333300003334000003330
-- 131:0003434004343430434343403333333000004343000003330000000000000000
-- 132:0003434000033430000343400003333000034333000333330000333300000033
-- 133:0000000300000003000000030000000043000000333000003300000000000660
-- 134:4300000034300000434000033333000343334333033333330033333300003330
-- 135:0300004333000033430000433300003343000043330000333000000300000003
-- 136:4343434334333433430000433300000340000003300000033000000333000003
-- 137:4300000334000000430000003300000043000000330005003000560030006660
-- 138:4343000034330000434340003333330003334343033333330033333300333300
-- 139:0000034300000433000003430000033340000333000003330000003300000003
-- 140:4000434030003430400043003000030040000000300000003000000000060060
-- 141:0043400000333000004340000033300000334000003330000033300000030000
-- 142:004343400033343000434300033333000333400003333000033300000030000b
-- 143:0000bbbb000bbbbb00bbbbbb0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 144:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 145:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 146:b0000330b0000000bb000000bbbb0000bbbbb000bbbb0000bbb00004bb000044
-- 147:00b0000000bbbbbb0000bbbb000000bb00000000444000004444400034444400
-- 148:00000000bbb00000bbbbbb00bbb00000b0000000000000000000444400443444
-- 149:0000065600006566065656560665666500565656000065660000065030000600
-- 150:0000000060000000565600066665666650005650000000600000000000440000
-- 151:0006000005666000500056500000006600000006004000000044000000443000
-- 152:0000000000006000000600006600000050000000000044440004444400043444
-- 153:0000565000066566005656560000666600000056400000064444000034443000
-- 154:0000000000000000500000066666000056000000600000000000444000043440
-- 155:0056000005660000565656006666600006560000066600040050000400600034
-- 156:0006565600666666065666560000000600000000400000004444400034300000
-- 157:0000000000000000560000506000000000000000000004400444444404443444
-- 158:000000bb00000bbb000bbbbb00bbbbbb0000bbbb0000bbbb40000bbb34000bbb
-- 159:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 160:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 161:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 162:bb000444bb000434b0004444b0003434b0004443000434300003434000043330
-- 163:44444400000044000000400000000000000000000000000000bb000000bb0000
-- 164:0044444400344434004440040034000004430000343400004343000033300000
-- 165:4400000044300000444000003434000044430000043400000343000003340000
-- 166:0444000004340000044400000434000004430000043400000343000003340000
-- 167:0044400000343400004443000034340000434400003434000043430000343300
-- 168:0044440000343000004440000034300004434000043400000343000003343334
-- 169:4444400004343000004440000034300000434000043430000343000033300000
-- 170:0004444000044430000444400034343000434440003434300043434000343330
-- 171:0050004400000434000003430000043400000343000034340000434300003333
-- 172:4400000034000000400000003000000043000000343430004343400030000000
-- 173:0444444444300004444000003430000044400000343000004340000333300034
-- 174:444000bb443000bb444000bb343000bb444000bb343000bb430000bb30000bbb
-- 175:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 176:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 177:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 178:00034340000334300003334000033330b0004333b0003333b0000333bb000003
-- 179:0000000000000000000000000033300043334000333330003333000033000000
-- 180:4340000034330000434300003333000003334333033333330033333300003333
-- 181:0343000004330000034300003333000043330000333000063330005630000066
-- 182:0343400004333000004340000033333300334343000333330000333360000333
-- 183:0043430000333000004340003333300043334000333330003333000033300000
-- 184:0343434304333433034343433333000343330003333300000330000000000000
-- 185:4300006034000660430000663330006643330006333300063333000603300006
-- 186:0043434000333330004333000003330000034300000333000003330000000000
-- 187:0000434300033333000333430003333300034333000033330000333300000000
-- 188:0000000000000000000000000000000033000000333000003300000000000b00
-- 189:4343434334333433434343433333300303334000033330000333300003333000
-- 190:40000bbb340000bb4340000b3333000b4333400003333000003300000000000b
-- 191:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 192:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 193:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 194:bbb00000bbbb0000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 195:000000bb00000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 196:00000000b0000000bb000000bb000666bbb00066bbb00066bbb00066bbb00066
-- 197:0000066600006666005666666666666656665666666666666666666666666666
-- 198:5000000066000000665600006666666656665666666666666666666666666666
-- 199:0000000000000066000066666666666666666666666666666666666666666666
-- 200:0000000000006600666666666666666666666666666666666666666666666666
-- 201:0000006600000666000666666666666666666666666666666666666666666666
-- 202:5000000060000006666666666666666666666660666660006660000060000000
-- 203:6600000066660000660000006000000b00000bbb000bbbbb00bbbbbbbbbbbbbb
-- 204:0000bbb000bbbbb0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 205:000000000000000b00000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 206:000000bbb0000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 207:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 208:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 209:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 210:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 211:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 212:bbb00066bbb00066bbbb0006bbbb0000bbbb0000bbbbb000bbbbbb00bbbbbbb0
-- 213:5666666666666666666666666666666666666666006666660000066600000000
-- 214:5666666666666666666666666666666666666666666666666666666600000000
-- 215:6666666666666666666666666666666666666666666666606660000000000000
-- 216:6666666666666666666666666666660066600000000000000000000b0000bbbb
-- 217:6666660066660000660000000000000b00000bbb00bbbbbbbbbbbbbbbbbbbbbb
-- 218:000000bb0000bbbb0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 219:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 220:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 221:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 222:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 223:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 224:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 225:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 226:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 227:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 228:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 229:b0000000bbbbb000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 230:0000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 231:0000000b00bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 232:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 233:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 234:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 235:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 236:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 237:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 238:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 239:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 240:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 241:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 242:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 243:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 244:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 245:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 246:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 247:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 248:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 249:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 250:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 251:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 252:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 253:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 254:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 255:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- </SPRITES7>

-- <MAP>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000069140414047800000000000000000000000000000000000000
-- 001:000000000000000000000000000000000000000000006474650000000000000000000000000000000000000000000000000000002131412141000000000000000000000000000000002131410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006500000000000000000000000000000000000000000021412141000000000000000000216500000000000000000000000068130313037900000000000000000000005101110101110111
-- 002:000000000000000000000000000000000021314100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000021314100000000000000213141000000000000000000000000000000006474650000000000000000000000000000000000000000000000212131410000000000647400000000000000000000000000000000002121000000000000410000000000000000000000000000000000000000000000000000213141000000000000000000006500000000000000000000000069140414047800000000000000000000000002120202120212
-- 003:000000000000000000000000000000006474652131410000000000000000000000000021314100000000000000000000000000000000410000000000000000000000000000000000213141000000000000000000000000000000000000000000314100000065650000000000000000000000000000000000000000000000002131410000000000656474647400000000000000000000000000000021314100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000051011161000068130313037800000000000000000000000068130313031303
-- 004:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000213141000000000000000031410000000000000000000000000000000000000000000000000000002131410000000000000065756575000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000212000f0069140414047900000000000000000000000069140414041404
-- 005:e0e0e0e0e0e0e0e0e0e0e0f0c10000000000000000000000000000000000000000000000000000000000000000000000c0d0e0e0e0e0e0e0e0e0e0e000000000000000000000000000000000000000000000000000213141000000003242424252620000000000000000000032425262000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0d0e0e0e0e0e0e0e0e0e0000000000000000000000000000000000f0000000f000000000000000000687800000000000000000000000000000000000000000068130313031304
-- 006:e1e1e1e1e1e1e1e1e1e1e1f100000000000000c0d0e0e0e0e0e0e0e0e0f0c1000000000000003242526200000000000000d1e1e1e1e1e1e1e1e1e1e1000000000000324252620000000000000000000000000000000000000000000033434343536300000000000000000000334353630000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000000003242526200000000000000d1e1e1e1e1e1e1e1e1e10000000000000000000000000000000000000000000000000000000000306979002900293900009f000000000000000f000000000069140414041403
-- 007:e2e2e2e2e2e2e2e2e2e2e2f20000000000000000d1e1e1e1e1e1e1e1e1f100000000000000003343536300000000000000d2e2e2e2e2e2e2e2e2e2e20000000000003343536300000000000000000000000000000000000000000000263646566676000000000000000000323434344462000000000000000000000000000000000000000000000000000000000000000000a8b8f8000000000000000000003343536300000000000000d2e2e2e2e2e2e2e2e2e20000003242526200000000000000000000000000000000000000000000006813011101110111012a2939000000000000000000000068130313031304
-- 008:eafa717171717171717171f30000000000000000d2e2e2e2e2e2e2e2e2f200000000000000243434344454000000000000d37171717171717171eafa0000000000243434344454000000000000000000000000000f0000000000000000374757670000000000000000000033353535456300000000000000000000000000000000000000000f00000f00000f000000000000a9b9f9000000000000000000243434344454000000000000d3e5e5e5e5e5e5e5eafa00000033435363000000230022000000000000000000000000000000000069140212021202120212012a293900000000000000000069140414041403
-- 009:ebfb717171a5b571717171f30000000000000015d3e3e3e3e3e3e3e3e3f315000000000000253535354555000000001500d371717171a5b57171ebfb001500000025353535455500000000000000000000000000000000000000000000004858000000000000000000000026364656667600000000000000000000000000000000000f00000000000000000000000000001a110111011161000000000000253535354555000000150000d4e5e5e5e5e5e5e5ebfb011101110111011101110111011161000000000000005101110111011101130313031303130313030212011161000000000000000068130313031304
-- 010:eafa717171a6b671717171c20000000000000016d4e4e4e4ccdcecfce4f416000000000000263646566676000000001600c271717171a6b67171eafa00160000002636465666760000000000000000000000000000003a4a6a000000000048580000000f000000000f000000374757670000a8b8c8d8e8f8000000001a116100000000000000325262000000000051011102120212021200000000000f00263646566676000000160000c20000000000e4e4eafa021202120212021202120212021200000000000000000002120212021202140414041404140414031313021210202000000000005e69140414041404
-- 011:ebfb717171a7b770707171c30000000000000017d5e4e4e4cdddedfde4f517000000000000383747576700000083931700c371719090a7b77171ebfb001700000000374757670000000000000000000000000000002939230060602923294959390000000000000000000000294959390023a9b9c9d9e9f9009f0000021200000023000000003353630000495900000212031303130313012a0000000000003747576700000000170000c3000000808000e4ebfb03130313031303130313031303780000000000000000006813031303130313031303130313031304141403680000000000005d005d68130313031303
-- 012:eafa717171819170707171c400a8b8c8d8e8f818d4e4e4e4cedeeefee4f418969600270000969648589696969684941800c47171909071917171eafa0018a8c8f800384858000000a3b300000000000f006a00510111011101110111011101110111989898989898989801110111011101110111011101110111011103780000001a2a00001a11012a00001a2a000068130414041404140212012a0000000038485800a3b30000180000c400000080800000eafa04140414041404140414041404790000000000000000006914041404140414041404140414041404141304690f000000000000005e69140414041404
-- 013:ebfb717171829270707171c500a9b9c9d9e9f919d5e4e4e4cfdfefffe4f519979729280000979749599797979785951900c57171909072927171ebfb0019a9c9f929394959002939a4b4390000000000233900000212021202120212021202120212990000000000008902120212021202120212021202120212021204790000000212000002120212000002120000691403130313031303130212012a002939495900a4b40000190000c500000080800000ebfb031303130313031303130313037800000000000000000068130313031303130313031303130313031314036800000000000000005d68130313031303
-- 014:e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6d70111011101110111011101110111d7e6f6e6f6e6f6e6f6e6f6e6f6e6f60111011101110111011101110111012a00001a110111011103130313031303130313031303784b4b4b4b4b4b4b4b68130313031303130313031303130313031303784b4b4b68784b4b681303784b4b68784b4b68130414041404140414031302120111011101110111d7e6f6e6f6e6f6e6f6e6f6e6f6e6f604140414041404140414041404798c8c8c8c8c8c8c8c8c69140414041404140414041404140414041413046910202000000000005e69140414041404
-- 015:c6d6c6d6c6d6c6d6c6d6c6d60b0dc6d6c6d6c6d6c6d6c6d6c6d6c6d6c6d6d70212021202120212021202120212d70b0dc6d6c6d6c6d6c6d6c6d6c6d60212021202120212021202120212021200000212021202120414041404140414041404140479cacacacacacacaca6914041404140414041404140414041404140479cacaca6979caca69140479caca6979caca69140313031303130313031303130212021202120212d7c6d6c6d6c6d6c6d6c6d6c6d6c6d603130313031303130313031303784b4b4b4b4b4b4b4b4b681303130313031303130313031303130313130368000000005d0000005d68130313031303
-- 016:d7c6d6c6d6c6d6c6d6c6d6d70c0ed7c6d6c6d6c6d6c6d6c6d6c6d6c6d6c6d60313031303130313031303130313d70c0ed7c6d6c6d6c6d6c6d6c6d6d70313031303130313031303130313036850507813031303130313031303130313031303130378cbcbcbcbcbcbcbcb6813031303130313031303130313031303130378cbcbcb6878cbcb68130378cbcb6878cbcb68130414041404140414041404140313031303130313c6d6c6d6c6d6c6d6c6d6c6d6c6d6d70414041404140414041404140479cbcbcbcbcbcbcbcbcb691404140414041404140414041404140414140469000000005e0000005e69140414041404
-- 017:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000681303130313031303130313037800000f005d0000005d0000005d681313
-- 018:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000213141213141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000213141000000000000000000000000000000000000000000000000006914041404140414041404140479000000005e005e00000000005e691414
-- 019:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002131213141000000000000007431410000000000000000000000000000000021213141000000000000000074410000000000000000000000000000000000000000000000000000000000000021314100006813031303130313031303130378000000005d000000000000005d681313
-- 020:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000740000000000000000000000000000000000000000004100000000000000000000000000000032425262000000000021314100000000002131410000000000000000000000006914041404140414041404140479102020005e005e00000000005e691414
-- 021:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a3b3a8b8c8d8e8f800000000000000000000000000000000000000000000000000000000000000000000000000216441000000000000000000000000000000000000410000000000000000000074410000000033435363000000000000002131410000000000000000000000000000000000000000000000006813031303130378000000005d005d00000000005d681313
-- 022:00000000000000000000000000000000000000000000000000000000000f0000000000000000000000000000000000000f0000000f000000000000000000000000000000000000000000000000009f00000000000000000000000000000000a4b4a9b9c9d9e9f90000000000000000000000000000000000e0e0e0e0e0e0e0e0e0e0f0c10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002434344454000000000000000000000000000000000000000000213141000000000000000000006914041403130479000000005e005e00000000005e691414
-- 023:0000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000a3b30000000000000000000000000000000000000000000000001a11012a00000000000000000000000000005101110111011101110111011101110000000000000000000000e1e1e1e1e1e1e1e1e1e1f1000000000000000000000000000000000000000000000000000000000f00000000000000000000000000000000002535354555000000000000000000000000000000000000000000000000000000000000000000000000681304140378000000005d000000000000005d681313
-- 024:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a2aa4b41a2a000000000000000000000000000000000000000000000212021261000000000f00000000000000000002120212021202120212021202120000000000000000000000e2e2e2e2e2e2e2e2e2e2f20000000000000000000000000000000000000000000000000000080000000000000000000f0000000000000000002636465676000000000000000000000000000000000f00000000000000000000000000000000000000691403130378000000005e000000000000005e691414
-- 025:0000000000000000000000000000000000000000000000001a1101110111012a00000000000000000000000000001a11021201110212000000000f00000000000f0000000f00000000001a110313037800000000000000000000000000000068130313031303130313031303130000000000000000000000eafae4e4e4e4e4e4e4e4f4000000000000000000000000000000000000000000000000000000293900000000000000000000000000000000000037475767000000000000000000000000000000000000000000000000000000000000000000000000000068140479000000005d005d000000000000681313
-- 026:000000000000000000000000000000000000000000001a110212021202120212012a220000000000000f000000000212031302120313012a000000000008000000a8b8c8f80000001a1102120414047900000000000000000000000000000069140414041404140414041404140000000000000000000000ebfbe4a5b5e4e4e4e4e4f5000000000015000000000000000000000000000000000f000051011101116100000008a8b8e8f80000000000000000384858000000a8b8c8f86a0048580000000000000000a8b8c8d8e8f86a000000000000000000000000000f000000000000005e005e00000000005e691414
-- 027:00000000000000000000000000000000000000001a11021203130313031303130212012a00000008000000001a1103130414031304140212000000000000000000a9b9c9f9001a11021203130313037810200000000000000000000000000068130313031303130313031303130000000000000000000000eafae4a6b6e400000000c200000000001600000000000f000000a8f8000000000000000000021202120000000029a9b9e9f93900000000000029394959000023a9b9c9f9002249590000000000002939a9b9c9d9e9f900002300000000000000000000000f000000000000005d005d00000000005d681313
-- 028:011101110111011101111020202020300111011102120313041404140414041403130212012a00000000230002120414031304140313031301110111011101110111011101110212031304140414047900000000000000a3b300000000000069140414041404140414041404140000000000000000000000ebfbe5a7b7e480800000c300000000001700000000000f000000a9f9000000002300000000681303780000005101110111011161005101110111011101110111011101110111011101989898981101110110203001110111011101110111011101110111011101011101110000005e00000000005e691414
-- 029:0212021202120212021200000000000002120212031304140313031303130313041403130212011101110111031303130414031304140414021202120212021202120212021203130414031303130378000f0000000000a4b400000000000068130313031303130313031303130000000000000000000000eafae4e4e5e580800000c400969696961800000000000000001a1101110111011101116100691404790000000002120212021200000002120212021202120212021202120212021202990000891202120200000002120212021202120212021202120212021202021202120000005d00000000005d681313
-- 030:03130313031303130378000000000000681303130414031304140414041404140313041403130212021202120414041403130414031303130313031303130313031303130313041403130414041404784b4b6811011101110111610000000069140414041404140414041404140000000000000000000000ebfbe5e5e5e580800000c5009797979719002939001a1101110212021202120212021200006813037800000000681303130378000000681303130313031303130313031303130313680000000078031303290f3903130313031303130313031303130313031303130303780000005e00000000005e691414
-- 031:0414041404140414047900000000000069140414031304140313031303130313041403130414031303130313031303130414031304140414041404140414041404140414041403130414031303130379caca6912021202120212000000000068130313031303130313031303130000000000000000000000f6e6f6e6f6e6f6e6f6e6f6c6d6c6d6c6d60111011102120212031303130313031303787a7a691404797a7a7a7a6914041404797a7a7a691404140414041404140414041404140414698c9c8c9c7904140313031304140414041404140414041404140414041404140404794b4b4b4b4b4b4b4b4b4b681313
-- 032:031303130313031303780000000000006813031304140313041404140414041403130414031304140414041404140414031304140313031303130313031303130313031303130414031304140414041403130313031303130378000000000069140414041404140414041404140000000000000000000000c6d6c6d6c6d6c6d6c6d6c6d6c6d6c6d6d70212021203130313041404140414041404797b7b681303787b7b7b7b6813031303787b7b7b681303130313031303130313031303130313687a7a7a7a780313041404140313031303130313031303130313031303130313030378cacacacacacacacacaca691414
-- 033:041404140414041404790000000000006914041403130414031303130313031304140313041403130313031303130313041403130414041404140414041404140414041404140313041403130313031304140414041404140479000000000068130313031303130313031303130000000000000000000000d7c6d6c6d6c6d6c6d6c6d6c6d6c6d6c6d6031303130414041403130313031303130378caca69140479cacacaca691404140479cacaca691404140414041404140414041404140414694b4b4b4b790414041404140414041404140414041404140414041404140414040479cbcbcbcbcbcbcbcbcbcb681313
-- 034:780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000069140414041404140414041404140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005050505000005050505050500000000050505050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 035:79000000000000000000000000000000000000000000000000000000000000000000000000000000000000647431416431410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006813031303130313031303130313000000000000000000000000000000c0d0e0e0e0e0e0e0e0e0e0e0f0c1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 036:7900000000000000000000000000000000000000000000000000000000000000000000002939000000006421314100000000324252620000000000000000000000000000000000000000000000000000000000000000a8e8f8000000000000691404140414041404140414041400000000000000000000000000000000d1e1e1e1e1e1e1e1e1e1e1f100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 037:7800000000000000000000000000000000000000000000000000000000000000000000510111610000000000000000000000334353630000000000000000000000000000000000000000000000000000000000000000a9e9f9000000000000681303130313031303130313031300000000000000000000000000000000d2e2e2e2e2e2e2e2e2e2e2f200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 038:790000000000000000000000000000000000000000000000000000000000000008000000021200000000000000000000002434343444540000000000000000000000000000000000000000000000000000000000001a1101110111012a003069140414041404140414041404140000000000000000000000000000000000d3e5e5e5e5e5e5e5eafa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 039:78000000000000000000000000000000000000000000000000000000000000000029390068780000000000000000000000253535354555000000000000000000000000000000000000000000000000000000001a110212021202120212000068130313031303130313031303130000000000000000000000000000150000d4e5e5e5e5e5e5e5ebfb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 040:7900000f000f00000000000000000000000000000000000000000000000000001a110111047900000000000000000000002636465666760000000000a8c8f8000000000000000000000000000000000000000002120313031303780000003069140414041404140414041404140000000000000000000000000000160000c20000000000e4e4eafa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 041:7800000f000f0000000000000000000000000f000f004f000f000f0000001a11021202120378e8f80000000000000000000037475767000000000000a9c9f90000000000000000000000000000000000001a1103130414041404790000000000000000000000000000000000000000000000000000000000000000170000c3000000808000e4ebfb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 042:7900000f220f000000000000000000000000000000000000000000001a110212031303130479e9f90000a8b8f800000008003848580000001a110111011101114b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b781304140313031303780000000000000000000000000000000000000000000000000000000000000000180000c400000080800000eafa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 043:011101110111012a000000000000000000001a110111011101110111021203130414041403130111012aa9b9f900000000293949590029390212021202120212dbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdb791403130414041404140111011100000000000000000000000000000000000000000000000000000000190000c500000080800000ebfb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 044:0212021202120212100000000000000000300212021202120212021203130414031303130414021202120111012a00001a110111011101110313031303130378dbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdb78130414031303130313021202120111011101110111011101110111011101110111011101110111d7e6f6e6f6e6f6e6f6e6f6e6f6e6f60111011101110111011101110111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 045:03130313031303784b5b6b7b4b5b6b7b4b5b68130313031303130313041403130414041403130313031302120212011102120212021202120414041404140479dbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdbdb79140313041404140414031303130212021202120212021202120212021202120212021202120212d7c6d6c6d6c6d6c6d6c6d6c6d6c6d60212021202120212021202120212000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 046:0414041404140479dbdbdbdbdbdbdbdbdbdb6914041404140414041403130414031303130414041404140313031302120313031303130313031303130313031303130313031303130378dbdbdbdbdb781303130414031303130313041404140313031303130313031303130313031303130313031303130313c6d6c6d6c6d6c6d6c6d6c6d6c6d6d71403130313031303130313031303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 047:0313031303130378cacacacacacacacacaca6813031303130313031304140313041404140313031303130414041403130414041404140414041404140414041404140414041404140479dbdbdbdbdb7914041403130414041404140313031304140414041404140414041404140414041404140414041404140313031303130313031303130313031304140414041404140414041404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 048:0414041404140479cbcbcbcbcbcbcbcbcbcb6914041404140414041403130414031303130414041404140313031304140313031303130313031303130313031303130313031303130378dbdbdbdbdb7813031304140313031303130414041403130313031303130313031303130313031303130313031303130414041404140414041404140414041403130313031303130313031303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 049:0313031303130313031303130313031303130313031303130313031304140313041404140313031303130414041403130414041404140414041404140414041404140414041404140479cacacacaca7914041403130414041404140313031304140414041404140414041404140414041404140414041404140313031303130313031303130313031304140414041404140414041404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 050:0414041404140414041404140414041404140414041404140414041403130414031303130414041404140313031304140313031303130313031303130313031303130313031303130378cbcbcbcbcb7813031304140313031303130414041403130313031303130313031303130313031303130313031303130414041404140414041404140414041403130313031303130313031303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 134:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000078000000000000000000000000000000000000000000000000
-- 135:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000079000000000000000000000000000000000000000000000000
-- </MAP>

-- <MAP1>
-- 000:01010101010101010101010313000b4b0d4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:01010101010101010101010414000b4b0d4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:31213121312131213121318393000b4b0d4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:32223222322232223222328494000b4b0d4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:000000000000e2f200e2f20000000b4b0d4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:000000000000e3f300e2f20000000b4b0d4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:000000000000000000e3f30000000b4b0d4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:25352535910000000000a1b1c1000b4b0d4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:26362636130000000000a2b2c2000b4b0d4d00e4f40000000000000000000000e4f40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:01010104140000000000a3b3c3000b4b0d4d00e5f50000000000000000000a00e5f50000000000435300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:0101010313000000000000d200000b4b0d4d00e6f6a4b4000000000000000000e6f60000000000445400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:010101041400000000c4d4d300000b4b0d4d00e7f7a5b5650000000000850000e7f7000000e0f0455500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:01010105152535253525358191000b4b0d4dc06135258191757575757561712535253525352535455500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:01010101162636263626368292d00b4b0d4d004353268292000000000062722636263626362636460100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:01010101010101010101010313000b4b0d4d004454010313000000000043530101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:010101010101010101010103138b8b8d8b8d8d43530104148e8c8e8c8e44540101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:010101010101010101010104148c8e8c8e8c8e44540103138c8e8c8e8c43530101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP1>

-- <MAP7>
-- 000:f04949494949f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0e0f049494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:f049494949f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f149494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:f049f04949f0f0f000102030405060708090a0b0c0d0f249494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:f0f0f0494949f0f001112131415161718191a1b1c1d1f349494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:f0f0f0494949f0f002122232425262728292a2b2c2d2f449494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:f0f0f0494949f0f003132333435363738393a3b3c3d3f549494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:49f0f04949f0f0f004142434445464748494a4b4c4d4f649494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:49494949494949f005152535455565758595a5b5c5d5f749494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:4949494949f0f0f006162636465666768696a6b6c6d6f849494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:494949494949f0f007172737475767778797a7b7c7d7f949494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:494949494949f0f008182838485868788898a8b8c8d8fa49494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:49494949494949f009192939495969798999a9b9c9d9fb49494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:494949494949f0f00a1a2a3a4a5a6a7a8a9aaabacadafc49494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:4949494949f0f0f00b1b2b3b4b5b6b7b8b9babbbcbdbfd49494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:49f04949494949f00c1c2c3c4c5c6c7c8c9cacbcccdcfe49494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:49f04949494949f00d1d2d3d4d5d6d7d8d9dadbdcdddff49494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:494949494949494949494949494949494949494949494949494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:000000000000000000000000000000000000000000000000000049000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP7>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- 004:eeddcbba9877654210012345689abcde
-- </WAVES>

-- <WAVES1>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES1>

-- <WAVES2>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES2>

-- <WAVES3>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES3>

-- <WAVES4>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES4>

-- <WAVES5>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES5>

-- <WAVES6>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES6>

-- <WAVES7>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES7>

-- <SFX>
-- 000:b210c200e200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200300000000000
-- 001:322052507280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 002:02001210f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 003:c220a250a260b280c280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 004:739073e083b093e0a34093a0a3809300a300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300407000000000
-- 005:24f534e744e044d054d054c064b0d4a7c4a0c480b480a470945084507440e4305420441024100400f400f400f400f400f400f400f400f400f400f40041b000000000
-- 016:3130513071009100b100c100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100503000000400
-- 017:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000
-- 018:e100c130a15081606160417031a021d021f011f001c02180a170d160f150f120f110f100f100f100f100f100f100f100f100f100f100f100f100f100502000000000
-- 019:60008020b060c090c0a0b0c090e080e070e060e050c050a060809070a050a030902090109000d000d000e000f000f000f000f000f000f000f000f000305000000000
-- 032:210041006100710081009100b100c100d100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100305000000000
-- 033:010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100300000000000
-- </SFX>

-- <SFX1>
-- 000:b210c200e200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200300000000000
-- 001:b220c250d280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 002:d200e210f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 003:c220a250a260b280c280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 004:b390b3e0c3b0d3e0e340d3a0e380d300e300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300407000000000
-- 005:24f534e744e044d054d054c064b0d4a7c4a0c480b480a470945084507440e4305420441024100400f400f400f400f400f400f400f400f400f400f40041b000000000
-- 016:3130513071009100b100c100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100503000000400
-- 017:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000
-- 018:20003000400040005000500060006000700080009000a000b000c000d000e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000302000000000
-- 019:030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300305000000000
-- 032:210041006100710081009100b100c100d100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100305000000000
-- 033:010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100300000000000
-- </SFX1>

-- <SFX2>
-- 000:b210c200e200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200300000000000
-- 001:b220c250d280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 002:d200e210f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 003:c220a250a260b280c280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 004:b390b3e0c3b0d3e0e340d3a0e380d300e300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300407000000000
-- 016:3130513071009100b100c100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100503000000400
-- 017:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000
-- 018:20003000400040005000500060006000700080009000a000b000c000d000e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000302000000000
-- 019:030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300305000000000
-- 032:210041006100710081009100b100c100d100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100305000000000
-- 033:010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100300000000000
-- </SFX2>

-- <SFX3>
-- 000:b210c200e200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200300000000000
-- 001:b220c250d280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 002:d200e210f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 003:c220a250a260b280c280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 004:b390b3e0c3b0d3e0e340d3a0e380d300e300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300407000000000
-- 016:3130513071009100b100c100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100503000000400
-- 017:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000
-- 018:20003000400040005000500060006000700080009000a000b000c000d000e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000302000000000
-- 019:030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300305000000000
-- 032:210041006100710081009100b100c100d100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100305000000000
-- 033:010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100300000000000
-- </SFX3>

-- <SFX4>
-- 000:b210c200e200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200300000000000
-- 001:b220c250d280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 002:d200e210f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 003:c220a250a260b280c280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 004:b390b3e0c3b0d3e0e340d3a0e380d300e300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300407000000000
-- 016:3130513071009100b100c100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100503000000400
-- 017:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000
-- 018:20003000400040005000500060006000700080009000a000b000c000d000e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000302000000000
-- 019:030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300305000000000
-- 032:210041006100710081009100b100c100d100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100305000000000
-- 033:010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100300000000000
-- </SFX4>

-- <SFX5>
-- 000:b210c200e200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200300000000000
-- 001:b220c250d280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 002:d200e210f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 003:c220a250a260b280c280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 004:b390b3e0c3b0d3e0e340d3a0e380d300e300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300407000000000
-- 016:3130513071009100b100c100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100503000000400
-- 017:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000
-- 018:20003000400040005000500060006000700080009000a000b000c000d000e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000302000000000
-- 019:030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300305000000000
-- 032:210041006100710081009100b100c100d100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100305000000000
-- 033:010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100300000000000
-- </SFX5>

-- <SFX6>
-- 000:b210c200e200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200300000000000
-- 001:b220c250d280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 002:d200e210f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 003:c220a250a260b280c280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 004:b390b3e0c3b0d3e0e340d3a0e380d300e300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300407000000000
-- 016:3130513071009100b100c100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100503000000400
-- 017:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000
-- 018:20003000400040005000500060006000700080009000a000b000c000d000e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000302000000000
-- 019:030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300305000000000
-- 032:210041006100710081009100b100c100d100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100305000000000
-- 033:010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100300000000000
-- </SFX6>

-- <SFX7>
-- 000:b210c200e200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200300000000000
-- 001:b220c250d280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 002:d200e210f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 003:c220a250a260b280c280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 004:b390b3e0c3b0d3e0e340d3a0e380d300e300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300407000000000
-- 016:3130513071009100b100c100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100503000000400
-- 017:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000
-- 018:20003000400040005000500060006000700080009000a000b000c000d000e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000302000000000
-- 019:030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300305000000000
-- 032:210041006100710081009100b100c100d100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100305000000000
-- 033:010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100300000000000
-- </SFX7>

-- <FLAGS>
-- 000:00202020000408408001020400000000101000000000000000400000000000001010000000000010101000000000000010100000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010000000000000000020000000101010100000000000001010001000000000000000000000000010100000000000000000001010000000000000001010020210100000000002020202000010020402101000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000
-- </FLAGS>

-- <FLAGS1>
-- 000:00001000000000800102000000000000000810100000101010100000000000000000101010001010101000000000000010100000101010101010000000000000101000001010101010100000000000000000101000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000404040400000000000000000000000000000000000000000000000000000000040404040000000000000000000000000000000000000000
-- 001:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000
-- </FLAGS1>

-- <FLAGS2>
-- 000:00002000000040800102000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000
-- </FLAGS2>

-- <FLAGS3>
-- 000:00002000000040800102000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000
-- </FLAGS3>

-- <FLAGS4>
-- 000:00102000000040800102000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010000000000000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000
-- </FLAGS4>

-- <FLAGS5>
-- 000:00102000000040800102000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010000000000000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000
-- </FLAGS5>

-- <FLAGS6>
-- 000:00102000000040800102000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010000000000000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000
-- </FLAGS6>

-- <FLAGS7>
-- 000:00102000000040800102000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010000000000000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000
-- </FLAGS7>

-- <SCREEN>
-- 000:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 001:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 002:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 003:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 004:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 005:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 006:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 007:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 008:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 009:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 010:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 011:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 012:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000565550000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 013:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000cccccccccccccc0006565656500000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 014:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000cccccccccccc0000565656565000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 015:cccccccccccccccccccccccccccccccccccccccccccccccccccccccc000565000ccccccccccc00056565656566000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 016:cccccccccccccccccccccccccccccccccccccccccccccccccccccccc005656500cccccccc000000656565656565656565656500000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 017:cccccccccccccccccccccccccccccccccccccccccccccccccccccccc006666660ccccc0000000065656565656566656666666660000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 018:cccccccccccccccccccccccccccccccccccccccccccccccccccccccc005666600ccc000000000056565656565656565656565656000cccccc00000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 019:cccccccccccccccccccccccccccccccccccccccccccccccccccccccc000666000cc00000656565656565666566666666666666666000cccc0000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 020:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000cc000056555655565656565656565656565656665000ccc000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 021:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000ccc000565656565656565656665666666666666666000cc0000555000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 022:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000655565656565656565656565656565666566000cc0005555500cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 023:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00065656565656566656666666666666666666660000c0005656500cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 024:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0005556565656565656565656565656566656665600000000666000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 025:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0005656565656565656665660006666666666666666000c000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 026:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0006565656565656565656500006565666566666666000c00000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 027:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000656565656665660000000006666666666666666000ccc00000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 028:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000555656565656500000000000566656665666666600cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 029:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0006565656565666000000cc000666666666666666000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 030:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000656565656560000ccccc000005660006666666000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 031:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00006566656660000ccccccc00000000000666666000ccc000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 032:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000005656500000ccccccccc000000000006660000c00000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 033:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000cccccccccccc00000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 034:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000ccccccccccccccccccc00000000000000060000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 035:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000ccccccccccccccccccccccc000000000066600000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 036:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000666600000055000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 037:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000ccccccccccccccccccccccccc000000666660000000565000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 038:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000cccccccccccccccccccccc00000066666000000055555000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 039:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000656000ccccccccccccccccccc0000000666600000005556565000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 040:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc005565500cccccccccccccccccc00000066660000000555555555000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 041:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc005656500ccccccccccccccccc000006660000000056555655565000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 042:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc006566600cccccccccccccccc0000660000000005555555555555000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 043:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000666000ccccccccccccccc000000000000005656565656565656000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 044:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000cccccccccccccccc000000000005555555555555555555000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 045:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000ccccccccccccccccc0000000055565556565655565656560000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 046:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00055555555555555555555555555550000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 047:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000056565656565656565656565656560000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 048:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000555555555555555555555555555500000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 049:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000565656565656565656565656565600000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 050:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000005555555655555556555655565556000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 051:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000656565656565656565656565656565000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 052:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00005555555555555555555555555555650000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 053:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00006565656565656565656565656565656000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 054:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000ccccccccccccccc000565556555655565556555655565556555000000000ccccccccccccccccccccccccccc00000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 055:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000cccccccc0000cc000560000000656565650000656500000565600000000cccccccccccccccc000000ccc0000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 056:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000cccccc00000000005000000000055565000000050000000550000000000ccccc000000ccc00000000c00000000ccc000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 057:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000044400000cccc0000000000000000000000056500000000000000000000000440000ccc00000000cc000000000000444000c000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 058:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00044444440000ccc0004440000000044444000005600044000000444000000044400000000000040000000044400000044400000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 059:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000044444444000cc00034440000000434443440006000443400000434000044344000000000004444000000444400000044300000040000cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 060:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000444000444000cc00044440000004444444440005000444400000444000044440000065000004444400004444440000044400000444000cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 061:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0004440004344000c00044340000003440004430006000344400000444000034440000000500043444300004443440000034300004344000cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 062:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0044440004444000c00044440000004440000000005000444400000444000044440000000000044444400004444440000044400044444000cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 063:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00034340000343000000034340000003430000000006000343400000434000034340000000000043434340004343430000034300034340000cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 064:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0004444000044440000004443000000444400000006500044440000444400000344400043000004444443444444434000004344434440000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 065:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000343400003434000004343000000034340005650060003434300434340000043434343000000434343434343434300000343434343000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 066:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000434300004343400003434000000043430006500000004343434343434000034343430000000343434343434343400000434343430000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 067:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00034340000043430000433300000003433000500000000343434343433000004333400000000043430043434003430000034333400000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 068:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0004343000003434000034340000000034300000003000043434343434300000343430000000003434000434000434000004343400000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 069:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000343430043434300003343000000003343000003300003334333433340000003433000000000433300034300033300000333430000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 070:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00043434343434340000343400000000343400003430000434300004343000000434340000000034340004300004340000043430000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 071:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc003333333333333000033330000000003333000333000033330000033300000033333300000003333000030000333000033333000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 072:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00034343000043430003433343000000433343334300004340000003430000000333434340000333400000000033400003334000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 073:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00033330000003330003333333300000033333333300003330000003330005000333333300000333300000000033300003333000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 074:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00033340000000000000333333000000003333333000000330000003300056000033333300000033300000000033300003330000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 075:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000333000000000000000330000066000003330000000033300000330006660003333000000000300060060000300000030000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 076:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000033000c0000000000000000006560000000000060000000000000000565000000000005600000006565600000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 077:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000ccccccccc0000000006566600000000566600000006000000665660000000005660000006666660000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 078:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000cccccccccc00065656565656000650005650000600000056565650000006565656000656665656000050000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 079:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000ccccc0000006656665666566660000006666000000000066666666000066666000000000066000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 080:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000c00000000056565650005650000000065000000000000056560000000656000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 081:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000044400000000000000000656600000060004000000000444440000006600000000666000440000000000004400000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 082:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00004444440000000444400000650000000000044000000044444444400000000444000500004444440000444444440000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 083:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000044344444000044344430000600004400000044300000043444344430000004344000600034343000000444344434000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 084:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0004444444440000444444440000000444000000444000004444004444400000044440005000444400000004444444444000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 085:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0004340000440000344434443000000434000000343400003430000434300000044430000004343400000044300004443000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 086:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00044440000400000444004444000000444000000444300004440000044400000044440000003434000000044400000444000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 087:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00034340000000000340000343400000434000000343400003430000034300000343430000004343000000034300000343000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 088:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00044430000000004430000444300000443000000434400044340000043400000434440000003434300000044400000444000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 089:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000434300000000034340000043400000434000000343400043400000434300000343430000034343434300034300000343000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 090:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0003434000cc000043430000034300000343000000434300034300000343000000434340000043434343400043400003430000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 091:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0004333000cc00003330000003340000033400000034330003343334333000000034333000003333300000003330003430000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 092:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00034340000000004340000003430000034340000043430003434343430000600043434000004343000000004343434340000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 093:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000334300000000034330000043300000433300000333000043334333400066000333330000333330000000034333433340000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 094:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0003334000000000434300000343000000434000004340000343434343000066004333000003334300000000434343434340000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 095:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0003333000333000333300003333000000333333333330003333000333300066000333000003333300000000333330033333000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 096:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0004333433340000333433343330000003343434333400043330003433300060003430000034333330000000333400043334000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 097:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0003333333330000333333333300006000333333333300033330000333300060003330000003333333000000333300003333000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 098:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000333333300000033333333300056000033333333000003300000333300060003330000003333330000000333300000330000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 099:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000333000000000033333000006660000333333000000000000003300006000000000000000000000c00033330000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 100:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000cc00000000000006665000000000000000000000000000006650000000660000000000ccc000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 101:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000cccc00000000000666666000000000000660000660000000666600000066666000000ccccc00000000cc0000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 102:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000566666665600000000666666666666000666666666666666000000cccccccc00000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 103:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0006666666666666666666666666666666666666666666666666666000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 104:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0006656665666566656666666666666666666666666666666666000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 105:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00066666666666666666666666666666666666666666666666000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 106:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0006666666666666666666666666666666666666666666660000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 107:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00066666666666666666666666666666666666666666660000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 108:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000665666666656666666666666666666666666666600000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 109:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0006666666666666666666666666666666666666600000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 110:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000666666666666666666666666666666666660000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 111:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000666666666666666666666666666666000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 112:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00006666666666666666666666666660000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 113:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000066666666666666666666600000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 114:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000066666666666666000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 115:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 116:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 117:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 118:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 119:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 120:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 121:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 122:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 123:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 124:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 125:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 126:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 127:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 128:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 129:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 130:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 131:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 132:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 133:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 134:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 135:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- </SCREEN>

-- <SCREEN1>
-- 000:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 001:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 002:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 003:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 004:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 005:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 006:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 007:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 008:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 009:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 010:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 011:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 012:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 013:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 014:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 015:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 016:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 017:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 018:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 019:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 020:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 021:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 022:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 023:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 024:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 025:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 026:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 027:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 028:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 029:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 030:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 031:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 032:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 033:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 034:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 035:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 036:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 037:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 038:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 039:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 040:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 041:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 042:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 043:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 044:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 045:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 046:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 047:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 048:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 049:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 050:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 051:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 052:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 053:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 054:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 055:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 056:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 057:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 058:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 059:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 060:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 061:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 062:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 063:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 064:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 065:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 066:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 067:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 068:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 069:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 070:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 071:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 072:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 073:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 074:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 075:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 076:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 077:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 078:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 079:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 080:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 081:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 082:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 083:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 084:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 085:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 086:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 087:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 088:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 089:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 090:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 091:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 092:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 093:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 094:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 095:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 096:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 097:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 098:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 099:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 100:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 101:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 102:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 103:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 104:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 105:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 106:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 107:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 108:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 109:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 110:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 111:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 112:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 113:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 114:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 115:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 116:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 117:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 118:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 119:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 120:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 121:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 122:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 123:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 124:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 125:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 126:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 127:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 128:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 129:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 130:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 131:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 132:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 133:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 134:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 135:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- </SCREEN1>

-- <SCREEN2>
-- 000:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 001:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 002:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 003:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 004:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 005:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 006:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 007:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 008:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 009:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 010:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 011:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 012:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 013:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 014:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 015:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 016:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 017:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 018:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 019:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 020:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 021:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 022:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 023:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 024:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 025:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 026:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 027:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 028:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 029:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 030:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 031:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 032:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 033:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 034:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 035:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 036:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 037:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 038:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 039:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 040:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 041:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 042:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 043:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 044:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 045:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 046:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 047:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 048:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 049:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 050:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 051:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 052:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 053:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 054:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 055:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 056:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 057:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 058:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 059:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 060:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 061:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 062:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 063:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 064:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 065:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 066:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 067:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 068:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 069:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 070:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 071:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 072:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 073:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 074:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 075:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 076:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 077:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 078:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 079:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 080:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 081:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 082:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 083:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 084:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 085:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 086:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 087:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 088:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 089:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 090:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 091:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 092:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 093:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 094:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 095:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 096:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 097:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 098:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 099:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 100:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 101:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 102:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 103:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 104:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 105:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 106:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 107:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 108:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 109:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 110:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 111:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 112:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 113:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 114:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 115:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 116:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 117:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 118:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 119:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 120:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 121:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 122:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 123:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 124:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 125:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 126:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 127:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 128:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 129:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 130:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 131:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 132:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 133:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 134:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 135:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- </SCREEN2>

-- <SCREEN3>
-- 000:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 001:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 002:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 003:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 004:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 005:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 006:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 007:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 008:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 009:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 010:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 011:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 012:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 013:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 014:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 015:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 016:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 017:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 018:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 019:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 020:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 021:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 022:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 023:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 024:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 025:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 026:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 027:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 028:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 029:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 030:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 031:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 032:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 033:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 034:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 035:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 036:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 037:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 038:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 039:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 040:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 041:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 042:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 043:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 044:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 045:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 046:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 047:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 048:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 049:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 050:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 051:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 052:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 053:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 054:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 055:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 056:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 057:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 058:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 059:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 060:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 061:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 062:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 063:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 064:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 065:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 066:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 067:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 068:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 069:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 070:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 071:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 072:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 073:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 074:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 075:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 076:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 077:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 078:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 079:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 080:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 081:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 082:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 083:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 084:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 085:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 086:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 087:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 088:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 089:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 090:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 091:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 092:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 093:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 094:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 095:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 096:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 097:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 098:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 099:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 100:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 101:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 102:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 103:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 104:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 105:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 106:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 107:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 108:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 109:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 110:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 111:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 112:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 113:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 114:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 115:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 116:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 117:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 118:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 119:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 120:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 121:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 122:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 123:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 124:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 125:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 126:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 127:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 128:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 129:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 130:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 131:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 132:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 133:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 134:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 135:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- </SCREEN3>

-- <SCREEN4>
-- 000:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 001:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 002:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 003:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 004:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 005:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 006:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 007:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 008:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 009:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 010:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 011:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 012:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 013:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 014:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 015:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 016:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 017:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 018:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 019:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 020:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 021:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 022:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 023:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 024:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 025:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 026:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 027:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 028:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 029:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 030:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 031:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 032:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 033:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 034:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 035:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 036:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 037:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 038:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 039:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 040:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 041:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 042:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 043:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 044:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 045:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 046:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 047:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 048:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 049:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 050:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 051:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 052:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 053:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 054:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 055:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 056:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 057:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 058:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 059:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 060:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 061:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 062:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 063:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 064:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 065:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 066:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 067:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 068:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 069:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 070:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 071:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 072:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 073:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 074:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 075:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 076:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 077:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 078:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 079:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 080:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 081:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 082:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 083:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 084:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 085:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 086:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 087:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 088:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 089:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 090:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 091:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 092:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 093:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 094:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 095:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 096:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 097:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 098:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 099:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 100:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 101:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 102:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 103:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 104:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 105:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 106:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 107:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 108:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 109:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 110:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 111:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 112:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 113:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 114:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 115:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 116:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 117:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 118:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 119:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 120:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 121:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 122:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 123:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 124:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 125:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 126:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 127:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 128:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 129:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 130:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 131:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 132:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 133:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 134:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 135:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- </SCREEN4>

-- <SCREEN5>
-- 000:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 001:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 002:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 003:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 004:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 005:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 006:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 007:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 008:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 009:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 010:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 011:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 012:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 013:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 014:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 015:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 016:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 017:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 018:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 019:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 020:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 021:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 022:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 023:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 024:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 025:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 026:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 027:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 028:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 029:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 030:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 031:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 032:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 033:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 034:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 035:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 036:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 037:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 038:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 039:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 040:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 041:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 042:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 043:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 044:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 045:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 046:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 047:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 048:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 049:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 050:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 051:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 052:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 053:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 054:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 055:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 056:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 057:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 058:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 059:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 060:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 061:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 062:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 063:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 064:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 065:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 066:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 067:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 068:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 069:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 070:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 071:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 072:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 073:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 074:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 075:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 076:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 077:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 078:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 079:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 080:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 081:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 082:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 083:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 084:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 085:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 086:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 087:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 088:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 089:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 090:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 091:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 092:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 093:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 094:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 095:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 096:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 097:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 098:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 099:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 100:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 101:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 102:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 103:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 104:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 105:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 106:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 107:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 108:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 109:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 110:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 111:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 112:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 113:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 114:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 115:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 116:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 117:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 118:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 119:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 120:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 121:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 122:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 123:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 124:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 125:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 126:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 127:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 128:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 129:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 130:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 131:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 132:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 133:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 134:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 135:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- </SCREEN5>

-- <SCREEN6>
-- 000:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 001:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 002:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 003:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 004:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 005:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 006:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 007:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 008:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 009:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 010:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 011:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 012:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 013:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 014:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 015:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 016:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 017:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 018:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 019:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 020:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 021:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 022:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 023:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 024:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 025:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 026:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 027:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 028:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 029:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 030:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 031:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 032:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 033:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 034:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 035:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 036:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 037:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 038:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 039:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 040:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 041:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 042:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 043:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 044:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 045:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 046:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 047:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 048:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 049:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 050:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 051:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 052:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 053:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 054:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 055:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 056:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 057:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 058:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 059:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 060:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 061:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 062:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 063:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 064:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 065:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 066:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 067:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 068:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 069:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 070:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 071:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 072:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 073:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 074:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 075:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 076:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 077:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 078:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 079:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 080:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 081:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 082:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 083:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 084:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 085:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 086:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 087:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 088:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 089:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 090:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 091:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 092:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 093:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 094:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 095:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 096:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 097:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 098:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 099:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 100:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 101:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 102:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 103:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 104:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 105:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 106:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 107:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 108:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 109:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 110:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 111:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 112:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 113:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 114:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 115:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 116:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 117:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 118:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 119:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 120:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 121:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 122:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 123:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 124:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 125:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 126:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 127:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 128:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 129:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 130:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 131:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 132:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 133:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 134:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 135:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- </SCREEN6>

-- <SCREEN7>
-- 000:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 001:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 002:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 003:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 004:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 005:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 006:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 007:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 008:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 009:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 010:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 011:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 012:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 013:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 014:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 015:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 016:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 017:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 018:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 019:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 020:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 021:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 022:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 023:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 024:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 025:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 026:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 027:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 028:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 029:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 030:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 031:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 032:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 033:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 034:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 035:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 036:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 037:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 038:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 039:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 040:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 041:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 042:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 043:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 044:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 045:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 046:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 047:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 048:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 049:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 050:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 051:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 052:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 053:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 054:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 055:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 056:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 057:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 058:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 059:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 060:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 061:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 062:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 063:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 064:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 065:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 066:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 067:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 068:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 069:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 070:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 071:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 072:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 073:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 074:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 075:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 076:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 077:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 078:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 079:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 080:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 081:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 082:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 083:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 084:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 085:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 086:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 087:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 088:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 089:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 090:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 091:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 092:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 093:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 094:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 095:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 096:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 097:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 098:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 099:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 100:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 101:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 102:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 103:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 104:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 105:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 106:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 107:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 108:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 109:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 110:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 111:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 112:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 113:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 114:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 115:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 116:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 117:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 118:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 119:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 120:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 121:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 122:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 123:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 124:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 125:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 126:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 127:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 128:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 129:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 130:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 131:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 132:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 133:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 134:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 135:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- </SCREEN7>

-- <PALETTE>
-- 000:0000009d9d9dffffffbe2633e06f8b493c2ba46422eb8931f7e26b2f484e44891aa3ce271b263200578431a2f2b2dcef
-- </PALETTE>

-- <PALETTE1>
-- 000:0000009d9d9dffffffbe2633e06f8b493c2ba46422eb8931f7e26b2f484e44891aa3ce271b263200578431a2f2b2dcef
-- </PALETTE1>

-- <PALETTE2>
-- 000:1a1c2c0f380f3062308bac0f9bbc0f1a1c2c38b764ff000029366f3b5dc941a6f673eff7f4f4f494b0c2566c86101c2c
-- </PALETTE2>

-- <PALETTE3>
-- 000:1a1c2c0f380f3062308bac0f9bbc0f1a1c2c38b764ff000029366f3b5dc941a6f673eff7f4f4f494b0c2566c86101c2c
-- </PALETTE3>

-- <PALETTE4>
-- 000:1a1c2c0f380f3062308bac0f9bbc0f1a1c2c38b764ff000029366f3b5dc941a6f673eff7f4f4f494b0c2566c86101c2c
-- </PALETTE4>

-- <PALETTE5>
-- 000:1a1c2c0f380f3062308bac0f9bbc0f1a1c2c38b764ff000029366f3b5dc941a6f673eff7f4f4f494b0c2566c86101c2c
-- </PALETTE5>

-- <PALETTE6>
-- 000:1a1c2c0f380f3062308bac0f9bbc0f1a1c2c38b764ff000029366f3b5dc941a6f673eff7f4f4f494b0c2566c86101c2c
-- </PALETTE6>

-- <PALETTE7>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE7>

