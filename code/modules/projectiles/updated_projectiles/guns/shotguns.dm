//-------------------------------------------------------
//Generic shotgun magazines. Only three of them, since all shotguns can use the same ammo unless we add other gauges.

/*
Shotguns don't really use unique "ammo" like other guns. They just load from a pool of ammo and generate the projectile
on the go. There's also buffering involved. But, we do need the ammo to check handfuls type, and it's nice to have when
you're looking back on the different shotgun projectiles available. In short of it, it's not needed to have more than
one type of shotgun ammo, but I think it helps in referencing it. ~N
*/
/obj/item/ammo_magazine/shotgun
	name = "box of shotgun slugs"
	desc = "A box filled with heavy shotgun shells. A timeless classic. 12 Gauge."
	icon_state = "slugs"
	default_ammo = /datum/ammo/bullet/shotgun/slug
	caliber = "12g" //All shotgun rounds are 12g right now.
	gun_type = /obj/item/weapon/gun/shotgun
	max_rounds = 25 // Real shotgun boxes are usually 5 or 25 rounds. This works with the new system, five handfuls.
	w_class = 3 // Can't throw it in your pocket, friend.

/obj/item/ammo_magazine/shotgun/incendiary
	name = "box of incendiary slugs"
	desc = "A box filled with self-detonating incendiary shotgun rounds. 12 Gauge."
	icon_state = "incendiary"
	default_ammo = /datum/ammo/bullet/shotgun/incendiary

/obj/item/ammo_magazine/shotgun/buckshot
	name = "box of buckshot shells"
	desc = "A box filled with buckshot spread shotgun shells. 12 Gauge."
	icon_state = "buckshot"
	default_ammo = /datum/ammo/bullet/shotgun/buckshot

//-------------------------------------------------------

/*
Generic internal magazine. All shotguns will use this or a variation with different ammo number.
Since all shotguns share ammo types, the gun path is going to be the same for all of them. And it
also doesn't really matter. You can only reload them with handfuls.
*/
/obj/item/ammo_magazine/internal/shotgun
	name = "shotgun tube"
	desc = "An internal magazine. It is not supposed to be seen or removed."
	default_ammo = /datum/ammo/bullet/shotgun/slug
	caliber = "12g"
	max_rounds = 8
	chamber_closed = 0

/*
Shotguns always start with an ammo buffer and they work by alternating ammo and ammo_buffer1
in order to fire off projectiles. This is only done to enable burst fire for the shotgun.
Consequently, the shotgun should never fire more than three projectiles on burst as that
can cause issues with ammo types getting mixed up during the burst.
*/

/obj/item/weapon/gun/shotgun
	origin_tech = "combat=4;materials=3"
	w_class = 4
	force = 14.0
	fire_sound = 'sound/weapons/gun_shotgun.ogg'
	reload_sound = 'sound/weapons/gun_shotgun_shell_insert.ogg'
	cocked_sound = 'sound/weapons/gun_shotgun_reload.ogg'
	var/opened_sound = 'sound/weapons/gun_shotgun_open2.ogg'
	type_of_casings = "shell"
	accuracy = 1.15
	flags_atom = FPRINT|CONDUCT|TWOHANDED
	flags_gun_features = GUN_CAN_POINTBLANK|GUN_INTERNAL_MAG
	aim_slowdown = SLOWDOWN_ADS_SHOTGUN
	wield_delay = WIELD_DELAY_VERY_FAST //Shotguns are really easy to put up to fire, since they are designed for CQC (at least compared to a rifle)

	New()
		..()
		accuracy += config.low_hit_accuracy_mult
		recoil = config.low_recoil_value
		replace_tube(current_mag.current_rounds) //Populate the chamber.

	update_icon() //Shotguns do not currently have empty states, as they look exactly the same. Other than double barrel.
		return

/obj/item/weapon/gun/shotgun/proc/replace_tube(number_to_replace)
	current_mag.chamber_contents = list()
	current_mag.chamber_contents.len = current_mag.max_rounds
	var/i
	for(i = 1 to current_mag.max_rounds) //We want to make sure to populate the tube.
		current_mag.chamber_contents[i] = i > number_to_replace ? "empty" : current_mag.default_ammo
	current_mag.chamber_position = current_mag.current_rounds //The position is always in the beginning [1]. It can move from there.

/obj/item/weapon/gun/shotgun/proc/add_to_tube(mob/user,selection) //Shells are added forward.
	current_mag.chamber_position++ //We move the position up when loading ammo. New rounds are always fired next, in order loaded.
	current_mag.chamber_contents[current_mag.chamber_position] = selection //Just moves up one, unless the mag is full.
	if(current_mag.current_rounds == 1 && !in_chamber) //The previous proc in the reload() cycle adds ammo, so the best workaround here,
		update_icon()	//This is not needed for now. Maybe we'll have loaded sprites at some point, but I doubt it. Also doesn't play well with double barrel.
		ready_in_chamber()
		cock_gun(user)
	if(user) playsound(user, reload_sound, 25, 1)
	return 1

/obj/item/weapon/gun/shotgun/proc/empty_chamber(mob/user)
	if(current_mag.current_rounds <= 0)
		if(in_chamber)
			in_chamber = null
			var/obj/item/ammo_magazine/handful/new_handful = retrieve_shell(ammo.type)
			playsound(user, reload_sound, 25, 1)
			new_handful.forceMove(get_turf(src))
		else
			if(user) user << "<span class='warning'>[src] is already empty.</span>"
		return

	unload_shell(user)
	if(!current_mag.current_rounds && !in_chamber) update_icon()

/obj/item/weapon/gun/shotgun/proc/unload_shell(mob/user)
	var/obj/item/ammo_magazine/handful/new_handful = retrieve_shell(current_mag.chamber_contents[current_mag.chamber_position])

	if(user)
		user.put_in_hands(new_handful)
		playsound(user, reload_sound, 25, 1)
	else new_handful.loc = get_turf(src)

	current_mag.current_rounds--
	current_mag.chamber_contents[current_mag.chamber_position] = "empty"
	current_mag.chamber_position--
	return 1

		//While there is a much smaller way to do this,
		//this is the most resource efficient way to do it.
/obj/item/weapon/gun/shotgun/proc/retrieve_shell(selection)
	var/obj/item/ammo_magazine/handful/new_handful = rnew(/obj/item/ammo_magazine/handful)
	new_handful.generate_handful(selection, "12g", 5, 1, /obj/item/weapon/gun/shotgun)
	return new_handful

/obj/item/weapon/gun/shotgun/proc/check_chamber_position()
	return 1

/obj/item/weapon/gun/shotgun
	reload(mob/user, var/obj/item/ammo_magazine/magazine)
		if((flags_gun_features|GUN_BURST_ON|GUN_BURST_FIRING) == flags_gun_features) return

		if(!magazine || !istype(magazine,/obj/item/ammo_magazine/handful)) //Can only reload with handfuls.
			user << "<span class='warning'>You can't use that to reload!</span>"
			return

		if(!check_chamber_position()) //For the double barrel.
			user << "<span class='warning'>[src] has to be open!</span>"
			return

		//From here we know they are using shotgun type ammo and reloading via handful.
		//Makes some of this a lot easier to determine.

		var/mag_caliber = magazine.default_ammo //Handfuls can get deleted, so we need to keep this on hand for later.
		if(current_mag.transfer_ammo(magazine,current_mag,user,1))
			add_to_tube(user,mag_caliber) //This will check the other conditions.

	unload(mob/user)
		if((flags_gun_features|GUN_BURST_ON|GUN_BURST_FIRING) == flags_gun_features) return
		empty_chamber(user)

/obj/item/weapon/gun/shotgun/proc/ready_shotgun_tube()
	if(current_mag.current_rounds > 0)
		ammo = ammo_list[current_mag.chamber_contents[current_mag.chamber_position]]
		in_chamber = create_bullet(ammo)
		current_mag.current_rounds--
		current_mag.chamber_contents[current_mag.chamber_position] = "empty"
		current_mag.chamber_position--
		return in_chamber

/obj/item/weapon/gun/shotgun
	ready_in_chamber()
		return ready_shotgun_tube()

	reload_into_chamber(mob/user)
		if(active_attachable) make_casing(active_attachable.type_of_casings)
		else
			make_casing(type_of_casings)
			in_chamber = null

		if(!active_attachable) //Time to move the tube position.
			ready_in_chamber() //We're going to try and reload. If we don't get anything, icon change.
			if(!current_mag.current_rounds && !in_chamber) //No rounds, nothing chambered.
				update_icon()
		else
			if( !(active_attachable.flags_attach_features & ATTACH_CONTINUOUS) ) active_attachable = null
		return 1

//-------------------------------------------------------
//GENERIC MERC SHOTGUN //Not really based on anything.

/obj/item/ammo_magazine/internal/shotgun/merc
	max_rounds = 5

/obj/item/weapon/gun/shotgun/merc
	name = "custom built shotgun"
	desc = "A cobbled-together pile of scrap and alien wood. Point end towards things you want to die. Has a burst fire feature, as if it needed it."
	icon_state = "cshotgun"
	item_state = "cshotgun"
	origin_tech = "combat=4;materials=2"
	fire_sound = 'sound/weapons/gun_shotgun_automatic.ogg'
	current_mag = /obj/item/ammo_magazine/internal/shotgun/merc
	flags_atom = FPRINT|CONDUCT
	attachable_allowed = list(
						/obj/item/attachable/compensator)

	flags_gun_features = GUN_CAN_POINTBLANK|GUN_INTERNAL_MAG|GUN_ON_MERCS

	New()
		..()
		accuracy -= config.high_hit_accuracy_mult
		fire_delay = config.high_fire_delay*2
		burst_amount = config.low_burst_value
		burst_delay = config.mlow_fire_delay
		attachable_offset = list("muzzle_x" = 31, "muzzle_y" = 19,"rail_x" = 10, "rail_y" = 21, "under_x" = 17, "under_y" = 14, "stock_x" = 17, "stock_y" = 14)
		if(current_mag && current_mag.current_rounds > 0) load_into_chamber()

	examine(mob/user)
		..()
		if(in_chamber) user << "It has a chambered round."

//-------------------------------------------------------
//TACTICAL SHOTGUN

/obj/item/ammo_magazine/internal/shotgun/combat

/obj/item/weapon/gun/shotgun/combat
	name = "\improper MK221 tactical shotgun"
	desc = "The Weyland-Yutani MK221 Shotgun, a semi-automatic shotgun with a quick fire rate."
	icon_state = "mk221"
	item_state = "mk221"
	origin_tech = "combat=5;materials=4"
	fire_sound = 'sound/weapons/gun_shotgun_automatic.ogg'
	current_mag = /obj/item/ammo_magazine/internal/shotgun/combat
	attachable_allowed = list(
						/obj/item/attachable/bayonet,
						/obj/item/attachable/reddot,
						/obj/item/attachable/flashlight,
						/obj/item/attachable/extended_barrel,
						/obj/item/attachable/compensator,
						/obj/item/attachable/magnetic_harness)

	New()
		..()
		fire_delay = config.mhigh_fire_delay*2
		attachable_offset = list("muzzle_x" = 33, "muzzle_y" = 19,"rail_x" = 10, "rail_y" = 21, "under_x" = 14, "under_y" = 16, "stock_x" = 14, "stock_y" = 16)
		var/obj/item/attachable/grenade/G = new(src)
		G.flags_attach_features &= ~ATTACH_REMOVABLE
		G.icon_state = "" //Gun already has a better one
		G.Attach(src)
		update_attachable(G.slot)
		if(current_mag && current_mag.current_rounds > 0) load_into_chamber()

	examine(mob/user)
		..()
		if(in_chamber) user << "It has a chambered round."

//-------------------------------------------------------
//DOUBLE SHOTTY

/obj/item/ammo_magazine/internal/shotgun/double //For a double barrel.
	default_ammo = /datum/ammo/bullet/shotgun/buckshot
	max_rounds = 2
	chamber_closed = 1 //Starts out with a closed tube.

/obj/item/weapon/gun/shotgun/double
	name = "double barrel shotgun"
	desc = "A double barreled shotgun of archaic, but sturdy design. Uses 12 Gauge Special slugs, but can only hold 2 at a time."
	icon_state = "dshotgun"
	item_state = "dshotgun"
	origin_tech = "combat=4;materials=2"
	current_mag = /obj/item/ammo_magazine/internal/shotgun/double
	fire_sound = 'sound/weapons/gun_shotgun_heavy.ogg'
	cocked_sound = null //We don't want this.
	attachable_allowed = list(
						/obj/item/attachable/bayonet,
						/obj/item/attachable/reddot,
						/obj/item/attachable/gyro,
						/obj/item/attachable/flashlight,
						/obj/item/attachable/magnetic_harness)

	flags_gun_features = GUN_CAN_POINTBLANK|GUN_INTERNAL_MAG|GUN_ON_MERCS

	New()
		..()
		fire_delay = config.mlow_fire_delay
		attachable_offset = list("muzzle_x" = 33, "muzzle_y" = 21,"rail_x" = 15, "rail_y" = 22, "under_x" = 21, "under_y" = 16, "stock_x" = 21, "stock_y" = 16)

	examine(mob/user)
		..()
		if(current_mag.chamber_closed) user << "It's closed."
		else user << "It's open with [current_mag.current_rounds] shell\s loaded."

	unique_action(mob/user)
		empty_chamber(user)

	//Turns out it has some attachments.
	update_icon()
		icon_state = current_mag.chamber_closed ? copytext(icon_state,1,-2) : icon_state + "_o"

	check_chamber_position()
		if(current_mag.chamber_closed) return
		return 1

	add_to_tube(mob/user,selection) //Load it on the go, nothing chambered.
		current_mag.chamber_position++
		current_mag.chamber_contents[current_mag.chamber_position] = selection
		playsound(user, reload_sound, 25, 1)
		return 1

	able_to_fire(mob/user)
		if(!current_mag.chamber_closed)
			user << "\red Close the chamber!"
			return
		return ..()

	empty_chamber(mob/user)
		if(current_mag.chamber_closed) //Has to be closed.
			if(current_mag.current_rounds) //We want to empty out the bullets.
				var/i
				for(i = 1 to current_mag.current_rounds)
					unload_shell(user)
			make_casing(type_of_casings)

		current_mag.chamber_closed = !current_mag.chamber_closed
		update_icon()
		playsound(user, reload_sound, 25, 1)

	load_into_chamber()
		//Trimming down the unnecessary stuff.
		//This doesn't chamber, creates a bullet on the go.
		if(active_attachable && (active_attachable.flags_attach_features & ATTACH_PASSIVE) ) active_attachable = null
		if(current_mag.current_rounds > 0)
			ammo = ammo_list[current_mag.chamber_contents[current_mag.chamber_position]]
			in_chamber = create_bullet(ammo)
			current_mag.current_rounds--
			return in_chamber
		//We can't make a projectile without a mag or active attachable.

	make_casing()
		if(current_mag.used_casings)
			..()
			current_mag.used_casings = 0

	delete_bullet(obj/item/projectile/projectile_to_fire, refund = 0)
		cdel(projectile_to_fire)
		if(refund) current_mag.current_rounds++
		return 1

	reload_into_chamber(mob/user)
		in_chamber = null
		current_mag.chamber_contents[current_mag.chamber_position] = "empty"
		current_mag.chamber_position--
		current_mag.used_casings++
		return 1

/obj/item/weapon/gun/shotgun/double/sawn
	name = "sawn-off shotgun"
	desc = "A double barreled shotgun whose barrel has been artificially shortened to reduce range but increase damage and spread."
	icon_state = "sshotgun"
	item_state = "sshotgun"
	flags_equip_slot = SLOT_WAIST
	flags_atom = FPRINT|CONDUCT
	attachable_allowed = list()
	flags_gun_features = GUN_CAN_POINTBLANK|GUN_INTERNAL_MAG|GUN_ON_MERCS

	New()
		..()
		accuracy -= config.high_hit_accuracy_mult
		damage += config.high_hit_damage_mult
		recoil = config.med_recoil_value
		attachable_offset = list("muzzle_x" = 30, "muzzle_y" = 20,"rail_x" = 11, "rail_y" = 22, "under_x" = 18, "under_y" = 16, "stock_x" = 18, "stock_y" = 16)

//-------------------------------------------------------
//PUMP SHOTGUN
//Shotguns in this category will need to be pumped each shot.

/obj/item/ammo_magazine/internal/shotgun/pump

/obj/item/weapon/gun/shotgun/pump
	name = "\improper M37A2 pump shotgun"
	desc = "An Armat Battlefield Systems classic design, the M37A2 combines close-range firepower with long term reliability. Requires a pump, which is a Unique Action."
	icon_state = "m37"
	item_state = "m37"
	current_mag = /obj/item/ammo_magazine/internal/shotgun/pump
	fire_sound = 'sound/weapons/gun_shotgun.ogg'
	var/pump_sound = 'sound/weapons/gun_shotgun_pump.ogg'
	var/pump_delay //Higher means longer delay.
	var/recent_pump //world.time to see when they last pumped it.
	attachable_allowed = list(
						/obj/item/attachable/bayonet,
						/obj/item/attachable/reddot,
						/obj/item/attachable/foregrip,
						/obj/item/attachable/gyro,
						/obj/item/attachable/flashlight,
						/obj/item/attachable/extended_barrel,
						/obj/item/attachable/heavy_barrel,
						/obj/item/attachable/compensator,
						/obj/item/attachable/magnetic_harness,
						/obj/item/attachable/flamer,
						/obj/item/attachable/stock/shotgun)

	New()
		select_gamemode_skin(/obj/item/weapon/gun/shotgun/pump)
		..()
		fire_delay = config.med_fire_delay*5
		pump_delay = config.max_fire_delay*2
		attachable_offset = list("muzzle_x" = 33, "muzzle_y" = 18,"rail_x" = 10, "rail_y" = 21, "under_x" = 20, "under_y" = 14, "stock_x" = 20, "stock_y" = 14)

	unique_action(mob/user)
		pump_shotgun(user)

	ready_in_chamber() //If there wasn't a shell loaded through pump, this returns null.
		return

	//Same as double barrel. We don't want to do anything else here.
	add_to_tube(mob/user, selection) //Load it on the go, nothing chambered.
		current_mag.chamber_position++
		current_mag.chamber_contents[current_mag.chamber_position] = selection
		playsound(user, reload_sound, 25, 1)
		return 1
	/*
	Moves the ready_in_chamber to it's own proc.
	If the Fire() cycle doesn't find a chambered round with no active attachable, it will return null.
	Which is what we want, since the gun shouldn't fire unless something was chambered.
	*/

//More or less chambers the round instead of load_into_chamber(). Also ejects used casings.
/obj/item/weapon/gun/shotgun/pump/proc/pump_shotgun(mob/user)	//We can't fire bursts with pumps.
	if(world.time < (recent_pump + pump_delay) ) return //Don't spam it.

	if(in_chamber) //eject the chambered round
		in_chamber = null
		var/obj/item/ammo_magazine/handful/new_handful = retrieve_shell(ammo.type)
		new_handful.forceMove(get_turf(src))

	ready_shotgun_tube()

	if(current_mag.used_casings)
		current_mag.used_casings--
		make_casing(type_of_casings)

	playsound(user, pump_sound, 25, 1)
	recent_pump = world.time

/obj/item/weapon/gun/shotgun/pump
	reload_into_chamber(mob/user)
		if(active_attachable) make_casing(active_attachable.type_of_casings)
		else
			current_mag.used_casings++ //The shell was fired successfully. Add it to used.
			in_chamber = null

		if(!active_attachable) //Time to move the tube position.
			if(!current_mag.current_rounds && !in_chamber) update_icon()//No rounds, nothing chambered.
		else
			if( !(active_attachable.flags_attach_features & ATTACH_CONTINUOUS) ) active_attachable = null

		return 1


//-------------------------------------------------------
//SHOTGUN FROM ISOLATION

/obj/item/ammo_magazine/internal/shotgun/pump/CMB //The only cycle method.
	max_rounds = 4

/obj/item/weapon/gun/shotgun/pump/cmb
	name = "\improper HG 37-12 pump shotgun"
	desc = "A four-round pump action shotgun with internal tube magazine allowing for quick reloading and highly accurate fire. Used exclusively by Colonial Marshals."
	icon_state = "hg3712"
	item_state = "hg3712"
	fire_sound = 'sound/weapons/gun_shotgun_small.ogg'
	current_mag = /obj/item/ammo_magazine/internal/shotgun/pump/CMB
	attachable_allowed = list(
						/obj/item/attachable/reddot,
						/obj/item/attachable/gyro,
						/obj/item/attachable/flashlight,
						/obj/item/attachable/compensator,
						/obj/item/attachable/magnetic_harness,
						/obj/item/attachable/flamer)


	New()
		..()
		fire_delay = config.med_fire_delay*4
		pump_delay = config.mhigh_fire_delay*2
		attachable_offset = list("muzzle_x" = 30, "muzzle_y" = 20,"rail_x" = 10, "rail_y" = 23, "under_x" = 19, "under_y" = 17, "stock_x" = 19, "stock_y" = 17)

//-------------------------------------------------------
