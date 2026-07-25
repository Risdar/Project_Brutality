// Hey there! You are looking at the LMG code - that one thing
// which takes 1500 lines. I don't know how I can optimize it,
// it's still makes it job, + it's quite a complex weapon so all these
// lines are worth it

// All this code is covered by my pain and my blood... I hope you
// will understand everything here :D
// CREDITS:
// 		-Carrot, Metalman - sprites;
// 		-IKDFA - animations, code
// 		-JMartinez2098 - help with coding, bug fixes
//			-Kamil - brightmaps
//			-BeefRice - 2026 Zscript Port

// Ammo Class
Class LMGAmmo : PB_WeaponAmmo
{
	default
	{
		Inventory.MaxAmount PB_LMG.MAGAZINE_SIZE;
		Ammo.BackpackMaxAmount PB_LMG.MAGAZINE_SIZE;
		Inventory.Icon "LMPIA0";
	}
}

// The Actual Weapon
class PB_LMG : PB_WeaponBase
{
    Default
    {
        //$Title Light Machine Gun
        //$Category Project Brutality - Weapons
        //$Sprite LMPIA0
//////////////////////////// WEAPON DATA ////////////////////////////////////////////////////////////////////////////////////
        // Game Doom;
        // SpawnID 9430;
        Weapon.AmmoType1 "PB_HighCalMag";
        Weapon.AmmoType2 "LMGAmmo";
        Weapon.AmmoGive 30;
        weapon.slotnumber 4;
        Weapon.AmmoUse1 0;
        Weapon.AmmoUse2 0;
        weapon.slotpriority 1;
        PB_WeaponBase.OffsetRecoilX 3.8;
        PB_WeaponBase.OffsetRecoilY 2.5;
        PB_WeaponBase.TailPitch 0.8;
        Scale 0.45;
//////////////////////////// MESSAGES & SOUNDS ////////////////////////////////////////////////////////////////////////////////////
        Inventory.PickupSound "LMGPKP";
        Inventory.PickupMessage "$PB_LMG_PICKUP";
        Tag "$PB_LMG_TAG";
        Obituary "%o became a leaking piece of meat by %k's light machine gun";
        AttackSound "none";
        //FloatBobStrength 0.5;
//////////////////////////// WEAPON FLAGS ////////////////////////////////////////////////////////////////////////////////////
        +FLOORCLIP;
        +DONTGIB;
        +WEAPON.WIMPY_WEAPON;
        +WEAPON.NOAUTOAIM;
        +WEAPON.NOAUTOFIRE;
        //+POWERED_UP;
        +WEAPON.NOALERT;
    }
//////////////////////////// VARIABLES ////////////////////////////////////////////////////////////////////////////////////
    bool mMicroMissiles;
	int mRecoilVariant;

    const MAGAZINE_SIZE = 100;
    const EMPTY_MAG = 7;

    const FLASH_LAYER = -2;

    const RECOIL_LAYER = -5;

	const ZOOM_LAYER = 2;
    const ZOOM_CONTINUE_LAYER = FLASH_LAYER;

	const BELT_LAYER = 4;

//////////////////////////// FUNCTIONS ////////////////////////////////////////////////////////////////////////////////////
    action void setMicroMissile(bool set)
    {
        invoker.mMicroMissiles = set;
    }

    action bool inMicroMissileMode()
    {
        return invoker.mMicroMissiles;
    }

    action state jumpIfMicroMissile(StateLabel name)
    {
        if(inMicroMissileMode())
            return resolveState(name);
        return resolveState(null);
    }

	action void LMG_Fire()
	{
		bool mode 				= inMicroMissileMode();
		bool ads 				= PB_GetZoom();
		name projectile 		= mode ? "PB_MicroMissileProjectile" : "PB_556x45mm";
		name sound 				= mode ? "LMISFIR" : "LFIRE";
		name casing 			= mode ? "LMGCasingRocket"    : "LMGCasingStandard";
		name belt 				= mode ? "LMGMissileBeltLink" : "LMGBeltLink";
		StateLabel flashSt 		= mode ? "MuzzleFlashRocket"  : "MuzzleFlashBullet"
		StateLabel beltSt 		= mode ? "BeltFireMissile"    : "BeltFireBullet";
		double recoilX 			= mode ? -0.30 : -0.60;
		double recoilY 			= mode ? -0.26 : -0.55;
		double xOfs 			= ads  ?    19 : 23;
		double horOfs 			= ads  ?    4  :  8;
		double vertOfs 			= ads  ?    29 : 36;

		LMG_HandleCrosshair();
		A_SetInventory("CantWeaponSpecial", 0);
		A_ClearOverlays(FLASH_LAYER, 7);
		PB_FireOffset();
		PB_IncrementHeat();
		PB_DynamicTail("lmg", "lmg");

		if (!mode)
		{
			PB_GunSmoke_Compensator(0, 0, 0);
			PB_MuzzleFlashEffects(0, 0, 0, "FF9D2E", true);
		}
		else
		{
			PB_GunSmoke(0, 0, 0);
			PB_MuzzleFlashEffects(0, 0, 0);
			A_FireCustomMissile("YellowFlareSpawn", 0, 0, 0, 0);
		}

		A_StartSound(sound, CHAN_Weapon, CHANF_DEFAULT, 1.0);
		PB_FireBullets(projectile, 1, 1, 0, 0, 1);

		A_Overlay(RECOIL_LAYER, "FireRecoil");
		A_FlashOverlay(FLASH_LAYER, flashSt);
		A_Overlay(BELT_LAYER, beltSt);

		PB_SpawnCasing(casing, xOfs, horOfs, vertOfs, 0, frandom(3,5), frandom(0,4), false);
		PB_SpawnCasing(belt, xOfs, horOfs, vertOfs, 0, frandom(1,3), frandom(0,4), false);		


		A_FireCustomMissile("YellowFlareSpawn", 0, 0, 0, 0);

		PB_WeaponRecoil(mode ? -0.22 : -0.44, mode ? -0.20 : -0.40);
		PB_WeaponRecoil(recoilX, recoilY);
		A_ZoomFactor(0.982);
		A_AlertMonsters();

		PB_LowAmmoSoundWarning("lmg");

		PB_TakeAmmo(invoker.ammo2.GetClassName(), emptyMag: mode ? (EMPTY_MAG - 1) : EMPTY_MAG);
	}

	// All in one set sprite function
    action void LMG_SetSprite(
		name l1, 
		name l2, 
		name l3 = "", 
		name l4 = "" , 
		name l5 = "", 
		name l6 = "", 
		bool simpleMode = false
	)
    {
        name spriteToUse;
        int ammo = invoker.ammo1.amount;
		int mode = inMicroMissileMode()

		// Change sprite depending on ammo level
        if(mode) // If in missile mode check these amounts
        {
            if		(ammo >= 7) spriteToUse = l1;
            else if (ammo == 6) spriteToUse = l2;
            else if (ammo == 5) spriteToUse = l3;
            else if (ammo == 4)	spriteToUse = l4;
            else if (ammo <= 3)	spriteToUse = l5;
            else				spriteToUse = l6;

        }
        else // If in bullet mode check these
        {
            if		(ammo >= 18) spriteToUse = l1;
            else if (ammo <= 15) spriteToUse = l2;
            else if (ammo <= 12) spriteToUse = l3;
            else if (ammo <= 9)	 spriteToUse = l4;
            else			     spriteToUse = l5;
        }

		// If simple mode is active then 
		// no need to check the ammo amounts, just mode
		if(simpleMode)
			spriteToUse = mode ? l2 : l1;
        
        if(spriteToUse != "")
            A_SetWeaponSpriteEx(spriteToUse);
    }

	action state LMG_JumpState(StateLabel l1, StateLabel l2, StateLabel l3, StateLabel l4, StateLabel l5 = null, StateLabel l6 = null)
    {
        StateLabel state;
        int ammo = invoker.ammo1.amount;

        if(inMicroMissileMode())
        {
            if		(ammo >= 7) state = l1;
            else if (ammo == 6) state = l2;
            else if (ammo == 5) state = l3;
            else if (ammo == 4)	state = l4;
            else if (ammo <= 3)	state = l5;
            else				state = l6;
        }
        else
        {
            if		(ammo >= 18) state = l1;
            else if (ammo <= 15) state = l2;
            else if (ammo <= 12) state = l3;
            else if (ammo <= 9)	 state = l4;
            else			     state = l5;
        }

        return resolveState(state);
    }

    action void LMG_HandleCrosshair()
    {
        int crs = 52;
        if(inMicroMissileMode) crs = 74;

        PB_HandleCrosshair(crs);
    }

	// The scale in fire recoil overlay is turned into a formula
	double getRecoilScale(int tic)
	{
		double scale = 1.1 - (0.025 * tic);
		return max(scale, 1.0);
	}

	// This is wack ngl
	// Basically returns an offset based on what tic the overlay is currently in
	int getRecoilOffset(int variant, int tic)
	{
		if (tic == 4) return 0;
		if (tic == 3) return -1;

		switch (variant)
		{
			case 1: return (tic == 0) ? random(-1, 0)  :  0;
			case 2: return (tic == 0) ? random(-1, -2) : -2;
			case 3: return (tic == 1) ? -3 			   : -2;
		}
		return 0;
	}

	action void LMG_RecoilTick(int tic)
	{
		A_OverlayPivotAlign(PSP_WEAPON, PSPA_CENTER, PSPA_TOP);
		A_OverlayScale(PSP_WEAPON, getRecoilScale(tic));

		int variant = invoker.mRecoilVariant; // This is class wide because we need to pass the variant
		if (variant != 1 || tic == 0 || tic == 4)
			A_OverlayOffset(PSP_WEAPON, getRecoilOffset(variant, tic), 0, WOF_KEEPY);
	}

	// This two functions is just a very complicated way to get sprite names
	action void LMG_BeltSprite(String prefix, String suffix, int value, int minT, int maxT)
	{
		int tier = Clamp(value, minT, maxT);
		A_SetWeaponSpriteEx(prefix..tier.. suffix);
	}

	int GetIrregularTier(int value, int t1, int t2, int t3)
	{
		if (value >= t1) return 3;
		if (value >= t2) return 2;
		if (value >= t3) return 1;
		return 0;
	}


//////////////////////////// STATES ////////////////////////////////////////////////////////////////////////////////////
    States
    {
//////////////////////////// SETUP ////////////////////////////////////////////////////////////////////////////////////
        Spawn:
			//BRIGHT Light("WeaponUpgradeSpawner")
			LMPI A 10 BRIGHT;
			Loop;
		// [Beef] maybe one day lol
		/*Spawn: //Model not implemented yet
			VLMG A 0 NoDelay
			LMPI A 10 A_PbvpFramework("VLMG")
			"####" "#" 0 A_PbvpInterpolate()
			LOOP*/

        CacheSprites:
            LLBU A 0;
            LBMZ A 0;
            LMMZ A 0;
            LKB7 A 0; LKB6 A 0; LKB5 A 0; LKB4 A 0; LKB3 A 0;
            LSB7 A 0; LSB6 A 0; LSB5 A 0; LSB4 A 0; LSB3 A 0;
            LQB7 A 0; LQB6 A 0; LQB5 A 0; LQB4 A 0; LQB3 A 0;
            LBA7 A 0; LBA6 A 0; LBA5 A 0; LBA4 A 0;
            ALB7 A 0; ALB6 A 0; ALB5 A 0; ALB4 A 0;

            LLMU A 0;
            LAFB A 0;
            LAFR A 0;
            LSM6 A 0; LSM5 A 0; LSM4 A 0; LSM3 A 0;
            LKM6 A 0; LKM5 A 0; LKM4 A 0; LKM3 A 0;
            LQM6 A 0; LQM5 A 0; LQM4 A 0; LQM3 A 0;
            LMA6 A 0; LMA5 A 0; LMA4 A 0; LMA3 A 0;
            ALM6 A 0; ALM5 A 0; ALM4 A 0; 

			LB71 A 0; LB61 A 0; LB51 A 0; LB41 A 0;
			LB31 A 0; LB21 A 0; LB11 A 0; 

			LLB7 A 0; LLB6 A 0; LLB5 A 0; LLB4 A 0; LLB3 A 0; LLB2 A 0; LLB1 A 0; 
			LLM6 A 0; LLM5 A 0; LLM4 A 0; LLM3 A 0; LLM2 A 0; LLM1 A 0; 

			LM61 A 0; LM51 A 0; LM41 A 0;
			LM31 A 0; LM21 A 0; LM11 A 0;

			LBS1 A 0; LB97 A 0; LB98 A 0; LB99 A 0; LB90 A 0;
			LMS1 A 0; LM86 A 0; LM85 A 0; LM84 A 0;


        WeaponRespect:
			TNT1 A 0 {
				A_StartSound("weapons/smg_up", 0);
				A_SetCrosshair(-1);
			};
			LSM6 ABCD 1 A_DoPBWeaponAction();
			LMRP AAAAABCDE 1 A_DoPBWeaponAction();
			TNT1 A 0 A_StartSound("LINSP ", 2);
			LMRP FGHIJKLMNOPQRSTUVWXYZ 1 A_DoPBWeaponAction();
			LRP1 ABBBCDEFGHIJKLMNOPQ 1 A_DoPBWeaponAction();
			TNT1 A 0 A_StartSound("LLIDOP", 2);
			LRP1 RSTUVWXYZ 1 A_DoPBWeaponAction();
			LRP2 ABCDEFGHIJKLMNOPQQQ 1 A_DoPBWeaponAction();
			TNT1 A 0 A_StartSound("weapons/sgl/detach", 4);
			LRP2 RSTUVWWXYZ 1 A_DoPBWeaponAction();
			TNT1 A 0 A_StartSound("weapons/lmg/magin", 4);
			LRP3 ABCDEFGHIJKLMNOPQRSTUVWXYZ 1 A_DoPBWeaponAction();
			TNT1 A 0 A_StartSound("LFEED", 3);
			LRP4 ABCDEFGHIJKL 1 A_DoPBWeaponAction();
			"####" A 0 A_StartSound("LLIDCL", 3);
			LRP4 MNOPQRSTUVWXY 1 A_DoPBWeaponAction();
			Goto Ready3;

        Deselect:
            TNT1 A 0 //A_SetCrosshair(0)
			TNT1 A 0 A_Setinventory("RandomHeadExploder",0);
			TNT1 A 0 A_Setinventory("Unloading",0);
			TNT1 A 0 A_Setinventory("Reloading",0);
			TNT1 A 0 PB_SetZoom(false);
			TNT1 A 0 A_StopSound(6);
			TNT1 A 0 A_StopSound(4);
			TNT1 A 0 SetPlayerProperty(0,0,0);
			TNT1 A 0 A_JumpIf(PB_GetMagUnloaded(), "UnloadedDeselect");
			AU2M DCBA 1 {
                if(inMicroMissileMode())
                    LMG_SetSprite("LSM6","LSM5","LSM4","LSM3");
                else
                    LMG_SetSprite("LSB7","LSB6","LSB5","LSB4","LSB3");
            }
		CompletelyDeselect:
			TNT1 A 1;
			TNT1 AAAAAAAAAAAAAAAAAA 0 A_Lower();
			Wait;
		UnloadedDeselect:
			LUSB EDCBA 1 LMG_SetSprite("LUSB","LUSM",simpleMode = true);
			Goto CompletelyDeselect;

		UnloadedSelect:
			LUSB ABCDE 1 LMG_SetSprite("LUSB","LUSM",simpleMode = true);
			Goto ReadyUnload;

        Select:
            TNT1 A 0 {
				A_WeaponOffset(0,32);
				PB_SetRoll(0);
                PB_SetZoom(false);
                LMG_HandleCrosshair();
				A_SetInventory("PB_LockScreenTilt",0);
                PB_WeaponRaise("weapons/smg_up");
			    return PB_RespectIfNeeded();
			}
        SelectAnimation:
			TNT1 A 0 A_JumpIf(PB_GetMagUnloaded(), "UnloadedSelect");
			AU2M ABCD 1 {
                if(inMicroMissileMode())
                    LMG_SetSprite("LSM6","LSM5","LSM4","LSM3");
                else
                    LMG_SetSprite("LSB7","LSB6","LSB5","LSB4","LSB3");
            }
            jumpIfMicroMissile("ReadyMissile");
            // Fallthrough to Ready
//////////////////////////// READY ////////////////////////////////////////////////////////////////////////////////////
        Ready3:
			TNT1 A 0 {
				LMG_HandleCrosshair();
				A_Setinventory("CantWeaponSpecial",0);
				A_Setinventory("CantDoAction",0);
			}
			TNT1 A 0 A_JumpIf(PB_GetMagUnloaded(), "ReadyUnload");
		ReadyToFire:
			"####" A 0 A_Setinventory("CantWeaponSpecial",0);
			LSB7 E 1 {
                PB_CoolDownBarrel();
				if(inMicroMissileMode())
				{
					name spriteToUse;
					if (invoker.ammo2.amount >= 6 ) spriteToUse = "LSM6";
					if (invoker.ammo2.amount <= 5 ) spriteToUse = "LSM5";
					if (invoker.ammo2.amount <= 4 ) spriteToUse = "LSM4";
					if (invoker.ammo2.amount <= 3 ) spriteToUse = "LSM3";
					A_SetWeaponSprite(spriteToUse);
				}
                else
                    LMG_SetSprite("LSB7","LSB6","LSB5","LSB4","LSB3");

                return PB_ReadyFire();
            }
			Loop;

        ReadyUnload:
			"####" Q 1 { 
				LMG_SetSprite("LLBU","LLMU",simpleMode = true);
                return A_WeaponReady(WRF_ALLOWRELOAD | WRF_NOSECONDARY); 
            }
			Loop;

		// [Beef] you know I can even combine this into one Ready3 state lol
		Ready2:
			"####" Q 1 {
				PB_CoolDownBarrel(0, 0, 6);
				if(inMicroMissileMode())
				{
					name spriteToUse;
					if (invoker.ammo2.amount >= 6 ) spriteToUse = "LMA6";
					if (invoker.ammo2.amount <= 5 ) spriteToUse = "LMA5";
					if (invoker.ammo2.amount <= 4 ) spriteToUse = "LMA4";
					if (invoker.ammo2.amount <= 3 ) spriteToUse = "LMA3";
					A_SetWeaponSprite(spriteToUse);
				}
                else
                    LMG_SetSprite("LBA7","LBA6","LBA5","LBA4","LBA4");
				return PB_ReadyFire();
			}
			Loop;
		
//////////////////////////// FIRE ////////////////////////////////////////////////////////////////////////////////////
		Fire:
			TNT1 A 0 PB_JumpIfNoAmmo(chamber:false);
			TNT1 A 0 A_JumpIf(PB_GetZoom(),"Fire2");
			TNT1 A 0 LMG_Fire();
			LMGF A 1 BRIGHT {
				LMG_SetSprite("LMGF","LMMF",simpleMode = true);
				Offset(0,0);
			}
			TNT1 A 0 A_WeaponReady(WRF_NOPRIMARY|WRF_NOBOB);
			TNT1 A 0 A_ZoomFactor(1.0);
			LMGF B 1 BRIGHT {
				LMG_SetSprite("LMGF","LMMF",simpleMode = true);
				Offset(0,35);
			}
			TNT1 A 0 A_WeaponReady(WRF_NOPRIMARY|WRF_NOBOB);
			LMGF C 1 {
				LMG_SetSprite("LMGF","LMMF",simpleMode = true);
				Offset(0,34);
			}
			TNT1 A 0 A_WeaponReady(WRF_NOPRIMARY|WRF_NOBOB);
			LMGF D 1 {
				LMG_SetSprite("LMGF","LMMF",simpleMode = true);
				Offset(0,33);
			}
			TNT1 A 0 A_WeaponReady(WRF_NOPRIMARY|WRF_NOBOB);
			TNT1 A 0 A_JumpIf(!inMicroMissileMode(),"Ready3"); // Early jump if not in Micro Missile
			LSM3 E 1 {
					// This is an exception
					name spriteToUse;
					if (invoker.ammo2.amount >= 6 ) spriteToUse = "LSM6";
					if (invoker.ammo2.amount <= 5 ) spriteToUse = "LSM5";
					if (invoker.ammo2.amount <= 4 ) spriteToUse = "LSM4";
					if (invoker.ammo2.amount <= 3 ) spriteToUse = "LSM3";
					A_SetWeaponSprite(spriteToUse);
			}
			Goto Ready3;

		Fire2:
			TNT1 A 0 PB_JumpIfNoAmmo(chamber:false);
			TNT1 A 0 LMG_Fire();
			LGAF B 1 BRIGHT LMG_SetSprite("LGAF","LRAF",simpleMode = true);
			TNT1 A 0 A_ZoomFactor(1.23);
			LGAF C 1 BRIGHT LMG_SetSprite("LGAF","LRAF",simpleMode = true);
			TNT1 A 0 A_ZoomFactor(1.25);
			LGAF DA 1 LMG_SetSprite("LGAF","LRAF",simpleMode = true);
			TNT1 A 0 jumpIfMicroMissile("ContinueFire2"); // Play some extra animation if in Missile Mode
			TNT1 A 0 PB_ReadyFire();
			Goto Ready2;

		ContinueFire2:
			"####" Q 1 {
				// This is an exception
				name spriteToUse;
				if (invoker.ammo2.amount >= 18 ) spriteToUse = "LMA6";
				if (invoker.ammo2.amount >= 15 ) spriteToUse = "LMA5";
				if (invoker.ammo2.amount >= 12 ) spriteToUse = "LMA4";
				if (invoker.ammo2.amount <  12 ) spriteToUse = "LMA3";
				A_SetWeaponSprite(spriteToUse);
			}
			TNT1 A 0 PB_ReadyFire();
			Goto Ready2Micro

//////////////////////////// ALTFIRE ////////////////////////////////////////////////////////////////////////////////////
		AltFire:
			TNT1 A 0 A_Setinventory("CantWeaponSpecial",0);
			TNT1 A 0 A_JumpIf(PB_GetZoom(),"Unzoom");
			TNT1 A 0 {
				A_StartSound("Ironsights", 64);
				PB_SetZoom(true,1.25);
				LMG_HandleCrosshair();
				A_Overlay(ZOOM_LAYER, "ZoomOverlay");
			}
			"####" AB 1 LMG_SetSprite("LBAT","LMAT",simpleMode = true);
			"####" A 0 A_Overlay(ZOOM_CONTINUE_LAYER, "ZoomOverlayContinue");
			"####" CD 1 LMG_SetSprite("LBAT","LMAT",simpleMode = true);
			Goto Ready2;
		Unzoom:
			"####" A 0 {
				A_StartSound("Ironsights", 64);
				PB_SetZoom(false);
				A_Overlay(ZOOM_CONTINUE_LAYER, "UnZoomOverlayContinue");
			}
			"####" DC 1 LMG_SetSprite("LBAT","LMAT",simpleMode = true);
			"####" A 0 A_Overlay(ZOOM_LAYER, "UnZoomOverlay");
			"####" BA 1 LMG_SetSprite("LBAT","LMAT",simpleMode = true);
			Goto Ready3;

//////////////////////////// WEAPON SPECIAL ////////////////////////////////////////////////////////////////////////////////////
		WeaponSpecial:
			TNT1 A 0 {
				A_SetCrosshair(-1);
				A_Setinventory("Zoomed",0);
				A_ZoomFactor(1.0);
				A_Setinventory("GoWeaponSpecialAbility",0);
				A_SetInventory("CantWeaponSpecial",1);

				if(inMicroMissileMode())
					return resolveState("MissileToBullet");
					
				A_PRINT("$PB_LMG_MISSILE", 2);
				return resolveState(null);
			}
			"####" ABC 1 {
				LMG_SetSprite("LBS1","LB97","LB98","LB99","LB90");
				return A_DoPBWeaponAction();
			}
			LBS1 HIJKLMNOPQRSTUVWXYZ 1 A_DoPBWeaponAction();
			LBS2 ABCDEF 1 A_DoPBWeaponAction();
			TNT1 A 0 A_StartSound("MG42RE");
			LBS2 GHIJKLMNOPQRSTUVWXYZ 1 A_DoPBWeaponAction();
			LBS3 ABCDEFGHIJKLMNOPQR 1 A_DoPBWeaponAction();
			TNT1 A 0 A_StartSound("MG42IN");
			LBS3 STUVWX 1 A_DoPBWeaponAction();
			LBS4 ABCDE 1 A_DoPBWeaponAction();
			TNT1 A 0 A_StartSound("weapons/riflemagslap", 0);
			LBS4 FGHIJKLMNOPQRSTUVWXYZ 1;
			LBS5 A 1 A_DoPBWeaponAction();
			"####" CBA 1 {
				LMG_SetSprite("LBS1","LB97","LB98","LB99","LB90");
				return A_DoPBWeaponAction();
			}
			Goto BarrelSwitchBulletMissile;

		MissileToBullet:
			TNT1 A 0 A_PRINT("$PB_LMG_BULLET", 2);
			LMS1 A 0 A_JumpIfInventory("LMGAmmo", 6, 5);
			LM86 A 0 A_JumpIfInventory("LMGAmmo", 5, 4);
			LM85 A 0 A_JumpIfInventory("LMGAmmo", 4, 3);
			LM84 A 0 ;
			"####" A 0;
			"####" A 0;
			"####" ABC 1 A_DoPBWeaponAction();
			LMS1 HIJKLMNOPQRSTUVWXYZ 1 A_DoPBWeaponAction();
			LMS2 ABCDEF 1 A_DoPBWeaponAction();
			TNT1 A 0 A_StartSound("MG42RE");
			LMS2 GHIJKLMNOPQRSTUVWXYZ 1 A_DoPBWeaponAction();
			LMS3 ABCDEFGHIJKLMNOPQR 1 A_DoPBWeaponAction();
			TNT1 A 0 A_StartSound("MG42IN");
			LMS3 STVWX 1 A_DoPBWeaponAction();
			LMS4 ABCDEFGHIJKLMNOPQRST 1 A_DoPBWeaponAction();
			LMS1 A 0 A_JumpIfInventory("LMGAmmo", 6, 5);
			LM86 A 0 A_JumpIfInventory("LMGAmmo", 5, 4);
			LM85 A 0 A_JumpIfInventory("LMGAmmo", 4, 3);
			LM84 A 0 ;
			"####" A 0;
			"####" A 0;
			"####" CBA 1 A_DoPBWeaponAction();
			Goto BarrelSwitchMissileBullet;

		BarrelSwitchBulletMissile:
			TNT1 A 0 A_Overlay(ZOOM_LAYER, "BeltReloadBullet");
			LBR1 ABCDEFGHIJ 1 A_DoPBWeaponAction();
			LBR1 A 0 A_StartSound("LLIDOP");
			LBMR ABCDEFFFF 1 A_DoPBWeaponAction();
			TNT1 A 0 {
				IF (invoker.ammo1.amount < 3 && invoker.ammo2.amount == 0)
					return  ResolveState  ("BarrelSwitchGetEmptyClipBM");
				return ResolveState(null);
			}
			TNT1 A 0 {
				if (invoker.ammo2.amount >= 8 && invoker.ammo1.amount >= 13)
					return  ResolveState ("BarrelSwitchBMNormalReload");
				else if (invoker.ammo2.amount >= 7)
					return  ResolveState ("BarrelSwitchBMNormalReload");

				if (invoker.ammo2.amount >= 1)
					A_Overlay(ZOOM_LAYER, "BeltReloadBulletGet7");
				return ResolveState(null);
			}
			LLBM AAABCDEFGHHHHH 1 A_DoPBWeaponAction();
			LLBM IJKLLLL 1 A_DoPBWeaponAction();
			"####" A 0 {
				A_StartSound("weapons/sgl/detach", 3);
				setMicroMissile(true);
				PB_UnloadMag(invoker.ammo2.getClassName(),invoker.ammo1.getClassName(),1,1,0,invoker.ammo2.amount - invoker.ammo2.amount % 2,"PB_HigherCalRound");
				A_SetInventory(invoker.ammo2.getClassName(),invoker.ammo2.amount / 2);
				SetAmmoCapacity(invoker.ammo2.getClassName(),MAGAZINE_SIZE/2);
				PB_SetMagUnloaded(true);
				PB_SetChamberEmpty(true);
			}
			LLBM MNOPQQQQ 1 A_DoPBWeaponAction();

		//ENTER the LMGAmmo -> NewClip sequence here
		BarrelSwitchBMContinue:
			TNT1 A 0 A_JumpIf(invoker.ammo1.amount >= 7 || invoker.ammo1.amount < 3, "BarrelSwitchBGoNormal");
			LLMU PON 1 A_DoPBWeaponAction();
			"####" A 0 A_StartSound("weapons/lmg/magin", 4) ;
			LLMU MLLLLKJIHHHG 1 A_DoPBWeaponAction();
			TNT1 A 0 A_Overlay(ZOOM_LAYER, "BeltReloadRocketGive6");
			LLMU FEDCBARSTUV 1 A_DoPBWeaponAction();
			Goto ReloadLidClosing;
		BarrelSwitchBGoNormal:
			LBM1 ABCD 1 A_DoPBWeaponAction();
			LMR2 KK 1 A_DoPBWeaponAction();
			LMR2 A 0 A_JumpIf(invoker.ammo1.amount >= 7, "ReloadBulletInsert");
			Goto BarrelSwitchGiveEmptyClipBM;
		BarrelSwitchBMNormalReload:
			LBMR GHIJ 1 A_DoPBWeaponAction();
			"####" A 0 A_StartSound("", 2);
			LBMR KLL 1 A_DoPBWeaponAction();
			LBMR MNNNN 1 A_DoPBWeaponAction();
			"####" A 0 {
				A_StartSound("weapons/sgl/detach", 3);
				setMicroMissile(true);
				PB_UnloadMag(invoker.ammo2.getClassName(),invoker.ammo1.getClassName(),1,1,0,invoker.ammo2.amount - invoker.ammo2.amount % 2,"PB_HigherCalRound");
				A_SetInventory(invoker.ammo2.getClassName(),invoker.ammo2.amount / 2);
				SetAmmoCapacity(invoker.ammo2.getClassName(),MAGAZINE_SIZE/2);
				PB_SetMagUnloaded(true);
				PB_SetChamberEmpty(true);
			}
		BarrelSwitchBMContinueNormal:
		BarrelSwitchBMContinueNormalStill:
			LBMR OPQR 1 A_DoPBWeaponAction();
			LMR2 IIIIIII 1 A_DoPBWeaponAction();
			Goto ReloadBulletInsert;

		BarrelSwitchGetEmptyClipBM:
			LBMR GHIJ 1 A_DoPBWeaponAction();
			"####" A 0 A_StartSound("", 2);
			LBMR JKLL 1 A_DoPBWeaponAction();
			LBMR MNNNN 1 A_DoPBWeaponAction();
			"####" A 0 {
				A_StartSound("weapons/sgl/detach", 3);
				setMicroMissile(true);
				PB_UnloadMag(invoker.ammo2.getClassName(),invoker.ammo1.getClassName(),1,1,0,invoker.ammo2.amount - invoker.ammo2.amount % 2,"PB_HigherCalRound");
				A_SetInventory(invoker.ammo2.getClassName(),invoker.ammo2.amount / 2);
				SetAmmoCapacity(invoker.ammo2.getClassName(),MAGAZINE_SIZE/2);
				PB_SetMagUnloaded(true);
				PB_SetChamberEmpty(true);
			}
			LBMR OPQR 1 A_DoPBWeaponAction();
			LMR2 IIIII 1 A_DoPBWeaponAction();
			LMR2 A 0 A_JumpIf(invoker.ammo1.amount >= 21, "ReloadBulletInsert");
		BarrelSwitchGiveEmptyClipBM:
			LMR2 IIIII 1 A_DoPBWeaponAction();
			LMR2 HGFE 1 A_DoPBWeaponAction();
			"####" A 0 A_StartSound("weapons/lmg/magin", 4) ;
			LMR2 DCBA 1 A_DoPBWeaponAction();
			Goto ReloadLidClosing;

		//MISSILE TO BULLET
		BarrelSwitchMissileBullet:
			TNT1 A 0 A_Overlay(ZOOM_LAYER, "BeltReloadMissile");
			LMR1 ABCDEFGHIJ 1 A_DoPBWeaponAction();
			LRMR A 0 A_StartSound("LLIDOP");
			LRMR ABCDEFFFF 1 A_DoPBWeaponAction();
			TNT1 A 0 {
				IF (invoker.ammo1.amount == 0 && invoker.ammo2.amount < 3) 
					return  ResolveState  ("BarrelSwitchGetEmptyClipMB");
				else if (invoker.ammo2.amount >= 21) 
					return  ResolveState ("BarrelSwitchMBNormalReload");
					
				return ResolveState(null);
			}
			TNT1 A 0
			TNT1 A 0 {
				if (invoker.ammo2.amount >= 21 && invoker.ammo1.amount >= 21) 
					return  ResolveState ("BarrelSwitchMBNormalReload");
				else 
					return ResolveState(null);

				if (invoker.ammo2.amount >= 3) 
					A_Overlay(ZOOM_LAYER, "BeltReloadRocketGet6");
				return ResolveState(null);
			}
			LLMB AAABCDEFGHHHH 1 A_DoPBWeaponAction();
			LLMB IJKLMMMM 1 A_DoPBWeaponAction();
			"####" A 0 {
				A_StartSound("weapons/sgl/detach", 3);
				setMicroMissile(false);
				SetAmmoCapacity(invoker.ammo2.getClassName(),MAGAZINE_SIZE);
				A_SetInventory(invoker.ammo2.getClassName(),invoker.ammo2.amount * 2);
				PB_SetMagUnloaded(true);
				PB_SetChamberEmpty(true);
			}
			LLMB MNOPQQQQQ 1 A_DoPBWeaponAction();
		//ENTER the LMGAmmo -> NewClip sequence here
		BarrelSwitchMBContinue:
			TNT1 A 0 A_JumpIf(invoker.ammo1.amount >= 8 || invoker.ammo1.amount < 3, "BarrelSwitchMGoNormal");
			LLBU PON 1 A_DoPBWeaponAction();
			"####" A 0 A_StartSound("weapons/lmg/magin", 4) ;
			LLBU MLLLLKJIHHHGF 1 A_DoPBWeaponAction();
			TNT1 A 0 A_Overlay(ZOOM_LAYER, "BeltReloadBulletGive7");
			LLBU EDCBARSTUV 1 A_DoPBWeaponAction();
			Goto ReloadLidClosing;
		BarrelSwitchMGoNormal:
			LBM2 ABCD 1 A_DoPBWeaponAction();
			LBR2 KK 1 A_DoPBWeaponAction();
			LBR2 A 0 A_JumpIf(invoker.ammo1.amount >= 8, "ReloadBulletInsert");
			Goto BarrelSwitchGiveEmptyClipMB;
		BarrelSwitchMBNormalReload:
			LRMR GHIJ 1 A_DoPBWeaponAction();
			"####" A 0 A_StartSound("", 2);
			LRMR KLL 1 A_DoPBWeaponAction();
			LRMR MNNNN 1 A_DoPBWeaponAction();
			"####" A 0 {
				A_StartSound("weapons/sgl/detach", 3);
				setMicroMissile(false);
				SetAmmoCapacity(invoker.ammo2.getClassName(),MAGAZINE_SIZE);
				A_SetInventory(invoker.ammo2.getClassName(),invoker.ammo2.amount * 2);
				PB_SetMagUnloaded(true);
				PB_SetChamberEmpty(true);
			}
		BarrelSwitchMBContinueNormal:
		BarrelSwitchMBContinueNormalStill:
			LRMR OPQ 1 A_DoPBWeaponAction();
			LBR2 IIIIIII 1 A_DoPBWeaponAction();
			LBR2 A 0 A_DoPBWeaponAction();
			Goto ReloadBulletInsert;
		BarrelSwitchGetEmptyClipMB:
			LRMR GHIJ 1 A_DoPBWeaponAction();
			"####" A 0 A_StartSound("", 2);
			LRMR KLL 1 A_DoPBWeaponAction();
			LRMR MNNNN 1 A_DoPBWeaponAction();
			"####" A 0 {
				A_StartSound("weapons/sgl/detach", 3);
				setMicroMissile(false);
				SetAmmoCapacity(invoker.ammo2.getClassName(),MAGAZINE_SIZE);
				A_SetInventory(invoker.ammo2.getClassName(),invoker.ammo2.amount * 2);
				PB_SetMagUnloaded(true);
				PB_SetChamberEmpty(true);
			}
			LRMR OPQR 1 A_DoPBWeaponAction();
			LBR2 IIIII 1 A_DoPBWeaponAction();
			LBR2 A 0 A_JumpIfInventory(invoker.ammo1.amount >= 8, "ReloadBulletInsert");
		BarrelSwitchGiveEmptyClipMB:
			LBR2 IIIII 1 A_DoPBWeaponAction();
			LBR2 HGFE 1 A_DoPBWeaponAction();
			"####" A 0 A_StartSound("weapons/lmg/magin", 4) ;
			LBR2 DCBA 1 A_DoPBWeaponAction()
			Goto ReloadLidClosing;
//////////////////////////// RELOAD ////////////////////////////////////////////////////////////////////////////////////
//////////////////////////// UNLOAD ////////////////////////////////////////////////////////////////////////////////////
//////////////////////////// FLASH STATES ////////////////////////////////////////////////////////////////////////////////////
		StopOverlay: //just for fun lmfao
			TNT1 A 1;
			Stop;

		// Bullet Reload
		BeltReload:
			TNT1 A 0 jumpIfMicroMissile("BeltReloadMissile");
		BeltReloadBullet:
			"####" A 0 A_JumpIf(invoker.ammo2.amount >= 4, "BeltReloadBulletMain");
			Goto BeltReloadBulletLess4;
		BeltReloadBulletMain:
			"####" A 0 A_LMGTierSprite("LB", "1", invoker.ammo2.amount, 4, 7);
			"####" ABCDEFFFGHIJKKKKKK 1;
			"####" A 0 A_JumpIf(invoker.ammo2.amount >= 8, "BeltReloadBullet8");
			Goto BeltReloadBulletGet7;

		BeltReloadBulletLess4:
			TNT1 A 0 A_JumpIf(invoker.ammo2.amount < 1, "StopOverlay");
			TNT1 AAAAAAAAAA 1;
			TNT1 A 0 A_LMGTierSprite("LB", "1", invoker.ammo2.amount, 1, 3);
			"####" ABCCCCCC 1;
		BeltReloadBulletGet7:
			TNT1 A 0 A_LMGTierSprite("LLB", "", invoker.ammo2.amount, 1, 7);
			"####" ABCD 1;
			"####" A 0 {
				if (invoker.ammo2.amount >= 1)
					A_StartSound("LFEED");
			}
			"####" EFGH 1;
			"####" A 0 A_JumpIf(invoker.ammo1.amount >= 8, "StopOverlay");
			"####" OOO 1;
			Stop;

		BeltReloadBulletGive7:
			TNT1 A 0 A_LMGTierSprite("LLB", "", invoker.ammo2.amount, 1, 7);
			"####" HGF 1;
			"####" A 0 {
				if (invoker.ammo2.amount >= 1)
					A_StartSound("LFEED");
			}
			"####" EDIJKLMN 1;
			Stop;

		BeltReloadBullet8:
			LB71 KKKL 1;
		BeltReloadBullet8Get:
			LB71 MNOOPQQQQRSTU 1;
			Stop;

		// Micro Missile Reload
		BeltReloadRocketLess6:
			TNT1 A 0 A_JumpIf(invoker.ammo2.amount < 3, "StopOverlay");
			TNT1 AAAAAAAAAA 1;
			TNT1 A 0 {
				A_SetWeaponSpriteEx("LM"..invoker.GetIrregularTier(invoker.ammo2.amount, 9, 6, 3).."1");
			}
			"####" ABCCCCCC 1;
			Goto BeltReloadRocketGet6;

		BeltReloadMissile:
			"####" A 0 A_JumpIf(invoker.ammo2.amount >= 4, "BeltReloadMissileMain");
			Goto BeltReloadRocketLess6;

		BeltReloadMissileMain:
			"####" A 0 A_LMGTierSprite("LM", "1", invoker.ammo2.amount, 4, 6);
			"####" ABCDEFFFGHIJKKKKKK 1;
			"####" A 0 A_JumpIf(invoker.ammo2.amount >= 7, "BeltReloadRocket7");
		BeltReloadRocketGet6:
			TNT1 A 0 A_LMGTierSprite("LLM", "", invoker.ammo2.amount, 1, 6);
			"####" ABCD 1;
			"####" A 0 {
				if (invoker.ammo2.amount >= 1)
					A_StartSound("LFEED");
			}
			"####" EFGH 1;
			"####" A 0 A_JumpIf(invoker.ammo1.amount >= 7, "StopOverlay");
			"####" OOO 1;
			Stop;

		BeltReloadRocketGive6:
			TNT1 A 0 A_LMGTierSprite("LLM", "", invoker.ammo2.amount, 1, 6);
			"####" HGF 1;
			"####" A 0 {
				if (invoker.ammo2.amount >= 1)
					A_StartSound("LFEED");
			}
			"####" EDIJKLMN 1;
			Stop;

		BeltReloadRocket7:
			LM61 KKKL 1;
		BeltReloadRocket7Get:
			LM61 MNOOPQQQQRSTU 1;
			Stop;

		// Close Lid
		BeltLidClosing:
			TNT1 A 0 jumpIfMicroMissile("BeltLidMissile");
			"####" A 0 A_JumpIf(invoker.ammo1.amount + invoker.ammo2.amount >= 4, "BeltLidBulletMain");
			Goto BeltLidBulletLess4;
		BeltLidBulletMain:
			LB71 A 0 A_JumpIf(invoker.ammo1.amount + invoker.ammo2.amount >= 7, "BeltBulletLidMore7");
			TNT1 A 0 A_LMGTierSprite("LB", "1", invoker.ammo1.amount + invoker.ammo2.amount, 4, 7);
			"####" LMNPQRSTUUUUVWXY 1;
			Stop;

		BeltLidBulletLess4:
			TNT1 A 0 A_LMGTierSprite("LB", "1", invoker.ammo1.amount + invoker.ammo2.amount, 1, 3);
			"####" DEGHI 1;
			Stop;

		BeltBulletLidMore7:
			LB71 VWXYZ 1;
			LB72 ABCDDDDEFGH 1;
			Stop;

		BeltLidMissile:
			"####" A 0 A_JumpIf(invoker.ammo1.amount + invoker.ammo2.amount / 2 >= 8, "BeltLidMissileMain");
			Goto BeltLidRocketLess4;
		BeltLidMissileMain:
			LM61 A 0 A_JumpIf(invoker.ammo1.amount + invoker.ammo2.amount / 2 >= 12, "BeltRocketLidMore6");
			TNT1 A 0 {
				int combined = invoker.ammo1.amount + invoker.ammo2.amount / 2;
				A_SetWeaponSpriteEx("LM" .. invoker.GetIrregularTier(combined, 12, 8, 6) .. "1");
			}
			"####" LMNOPQRSTTTTUVWXY 1;
			Stop;

		BeltLidRocketLess4:
			TNT1 A 0 A_LMGTierSprite("LM", "1", (invoker.ammo1.amount + invoker.ammo2.amount / 2) / 6, 1, 3);
			"####" DEFGHI 1;
			Stop;

		BeltRocketLidMore6:
			LM61 VWXYZ 1;
			LM62 ABCDDDDEFGH 1;
			Stop;

		// Missile
		BeltFireMissile:
			TNT1 A 0 LMG_JumpState("BeltMissile21","BeltMissile18","BeltMissile15","BeltMissile12",null);
			TNT1 A 4;
			Stop;
		BeltMissile21:
			LMML MN 1 BRIGHT;
			LMML OA 1;
			Stop;
		BeltMissile18:
			LMML PQ 1 BRIGHT;
			LMML RG 1;
			Stop;
		BeltMissile15:
			LMML ST 1 BRIGHT;
			LMML UJ 1;
			Stop;
		BeltMissile12:
			LMML VW 1 BRIGHT;
			LMML X 1;
			Stop;

		BeltFireMissileZoom:
			TNT1 A 0 LMG_JumpState("BeltFireMissileZoom7","BeltFireMissileZoom6","BeltFireMissileZoom5","BeltFireMissileZoom4",null);
			TNT1 A 4 ;
			Stop;
		BeltFireMissileZoom7:
			LRAB JK 1 BRIGHT;
			LRAB LA 1;
			Stop;
		BeltFireMissileZoom6:
			LRAB JK 1 BRIGHT;
			LRAB LD 1;
			Stop;
		BeltFireMissileZoom5:
			LRAB MN 1 BRIGHT;
			LRAB OG 1;
			Stop;
		BeltFireMissileZoom4:
			LRAB PQ 1 BRIGHT;
			LRAB R 1;
			Stop;
		
		// Muzzle Missile
		MuzzleFlashRocket:
			TNT1 A 0 PB_FireOffset();
			TNT1 A 0 A_Jump(255, "MuzzleRocket1", "MuzzleRocket2");
		MuzzleRocket1:
			LMMZ AB 1 BRIGHT {
				if(PB_GetZoom())
					A_SetWeaponSpriteEx("LAFR");
				A_GunFlash();
			}
			Stop;
		MuzzleRocket2:
			LMMZ DC 1 BRIGHT {
				if(PB_GetZoom())
					A_SetWeaponSpriteEx("LAFR");
				A_GunFlash();
			}
			Stop;

		// Bullet 
		BeltFireBullet:
			TNT1 A 0 LMG_JumpState("BeltBullet87","BeltBullet6","BeltBullet5",null);
			TNT1 A 4 ;
			Stop;
		BeltBullet87:
			LMGB JK 1 BRIGHT;
			LMGB L 1;
			LMGB A 1 {
				if(invoker.ammo2.amount == 7)
					A_SetWeaponFrame(3); // frame D
			}
			Stop;
		BeltBullet6:
			LMGB MN 1 BRIGHT;
			LMGB OG 1;
			Stop;
		BeltBullet5:
			LMGB PQ 1 BRIGHT;
			LMGB R 1;
			Stop;

		BeltFireBulletZoom:
			TNT1 A 0 LMG_JumpState("BeltFireBulletZoom87","BeltFireBulletZoom7","BeltFireBulletZoom6","BeltFireBulletZoom5",null);
			TNT1 A 4 ;
			Stop;
		BeltFireBulletZoom87:
			LGAB JK 1 BRIGHT;
			LGAB L 1;
			LGAB A 1 {
				if(invoker.ammo2.amount == 7)
					A_SetWeaponFrame(3); // frame D
			}
			Stop;
		BeltFireBulletZoom6:
			LGAB MN 1 BRIGHT;
			LGAB OG 1;
			Stop;
		BeltFireBulletZoom5:
			LGAB PQ 1 BRIGHT;
			LGAB R 1;
			Stop;

		// Muzzle Bullet
		MuzzleFlashBullet:
			TNT1 A 0 PB_FireOffset();
			TNT1 A 0 A_Jump(255, "MuzzleBullet1", "MuzzleBullet2","MuzzleBullet3");
		MuzzleBullet1:
			LBMZ AB 1 BRIGHT {
				if(PB_GetZoom())
					A_SetWeaponSpriteEx("LAFB");
				A_GunFlash();
			}
			Stop;
		MuzzleBullet2:
			LBMZ DC 1 BRIGHT {
				if(PB_GetZoom())
					A_SetWeaponSpriteEx("LAFB");
				A_GunFlash();
			}
			Stop;
		MuzzleBullet3:
			LBMZ EF 1 BRIGHT {
				if(PB_GetZoom())
					A_SetWeaponSpriteEx("LAFB");
				A_GunFlash();
			}
			Stop;

		//Additional weapon recoil animations, randomized for shakiness
		FireRecoil:
			TNT1 A 0 {invoker.mRecoilVariant = random(1,3);}
			TNT1 A 1 LMG_RecoilTick(0);
			TNT1 A 1 LMG_RecoilTick(1);
			TNT1 A 1 LMG_RecoilTick(2);
			TNT1 A 1 LMG_RecoilTick(3);
			TNT1 A 0 LMG_RecoilTick(4);
			Stop;

        //Zoom
		ZoomOverlay:
			"####" AB 1 {
                if(inMicroMissileMode())
                    LMG_SetSprite("ALM6","ALM5","ALM4","TNT1");
                else
                    LMG_SetSprite("ALB7","ALB6","ALB5","ALB4","TNT1");
            }
			Stop;
		ZoomOverlayContinue:
			"####" CD 1 {
                if(inMicroMissileMode())
                    LMG_SetSprite("ALM6","ALM5","ALM4","TNT1");
                else
                    LMG_SetSprite("ALB7","ALB6","ALB5","TNT1","TNT1");
            }
			Stop;

        UnZoomOverlay:
			"####" BA 1 {
                if(inMicroMissileMode())
                    LMG_SetSprite("ALM6","ALM5","ALM4","TNT1");
                else
                    LMG_SetSprite("ALB7","ALB6","ALB5","ALB4","TNT1");
            }
			Stop;

		UnZoomOverlayContinue:
			"####" DC 1 {
                if(inMicroMissileMode())
                    LMG_SetSprite("ALM6","ALM5","ALM4","TNT1");
                else
                    LMG_SetSprite("ALB7","ALB6","ALB5","ALB4","TNT1");
            }
			Stop;

        FlashPunching:
			TNT1 A 0 A_SetInventory("CantWeaponSpecial",0);
			TNT1 A 0 jumpIfMicroMissile("FlashPunchingMissile");
			LQB7 AB 1 {
                if(inMicroMissileMode())
                    LMG_SetSprite("LQM6","LQM5","LQM4","LQM3");
                else
                    LMG_SetSprite("LQB7","LQB6","LQB5","LQB4","LQB3");
            }
			LQB7 CDEFGHFEDC 1 LMG_SetSprite("LQM6","LQB7",simpleMode = true);
			LQB7 BA 1 {
                if(inMicroMissileMode())
                    LMG_SetSprite("LQM6","LQM5","LQM4","LQM3");
                else
                    LMG_SetSprite("LQB7","LQB6","LQB5","LQB4","LQB3");
            }
			Goto Ready3;

		FlashKicking:
			"####" ABCDEFGHGFEDCBA 1 {
                if(inMicroMissileMode())
                    LMG_SetSprite("LKM6","LKM5","LKM4","LKM3");
                else
                    LMG_SetSprite("LKB7","LKB6","LKB5","LKB4","LKB3");
            }
			Goto Ready3;

		FlashAirKicking:
			"####" ABCDEFGHHGFEDCBA 1 {
                if(inMicroMissileMode())
                    LMG_SetSprite("LKM6","LKM5","LKM4","LKM3");
                else
                    LMG_SetSprite("LKB7","LKB6","LKB5","LKB4","LKB3");
            }
			Goto Ready3;

		FlashSlideKicking:
			"####" ABCDEFGHHHHHHHHHHHHGFEDCBA 1 {
                if(inMicroMissileMode())
                    LMG_SetSprite("LKM6","LKM5","LKM4","LKM3");
                else
                    LMG_SetSprite("LKB7","LKB6","LKB5","LKB4","LKB3");
            }
			Goto Ready3;

		FlashSlideKickingStop:
			"####" GFEDCBA 1 {
                if(inMicroMissileMode())
                    LMG_SetSprite("LKM6","LKM5","LKM4","LKM3");
                else
                    LMG_SetSprite("LKB7","LKB6","LKB5","LKB4","LKB3");
            }
			Goto Ready3;

    }
}
